//
//  CategoryViewModelTests.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 7/2/25.
//

import Combine
import Foundation
@testable import SwiftUI_MVVM
import Testing

@MainActor
struct CategoryViewModelTests {
    // MARK: generic test data

    private let genericCategory = "Category1"
    private let jokeUrlString = "https://api.chucknorris.io/jokes/uKVtJZN4TMmT55lX3v752A"

    // Combine subjects that are used to trigger a response in FakeUrlSession.get()
    private let jokeSubject = PassthroughSubject<ChuckNorrisJoke?, Never>()
    private let categoriesSubject = PassthroughSubject<[String]?, Never>()

    private var cancellables: [AnyCancellable] = []
}

// MARK: - Initialization

extension CategoryViewModelTests {
    @Test(
        arguments: [
            (
                responseJokes: ["Joke 1", "Joke 2", "Joke 3", "Joke 4", "Joke 5"],
                expectedJokes: ["Joke 1", "Joke 2", "Joke 3", "Joke 4", "Joke 5"]
            ),
            (
                responseJokes: ["Joke 1", "Joke 1", "Joke 2", "Joke 2", "Joke 2"],
                expectedJokes: ["Joke 1", "Joke 2"]
            )
        ]
    )
    func initialState_loadSuccess(
        responseJokes: [String],
        expectedJokes: [String]
    ) async throws {
        // Setup/Execute
        let fakeUrlSession = FakeUrlSession()
        let sut = try await createSut(fakeUrlSession: fakeUrlSession)

        // Validate the initial view state
        #expect(sut.state.isLoading == true)

        // trigger responses for all CategoryViewModel.jokeCount (5) requests.
        try await trigger(jokeResponses: responseJokes, on: fakeUrlSession)

        // Validate the view state after the jokes are received.
        do {
            try await TestUtility.expect(
                value: expectedJokes,
                on: sut.$state,
                keyPath: \.jokes
            )
        } catch {
            // in theory, this do/catch should not be necessary, but the
            // message displayed by the debugger here is not the thrown
            // error's description.
            Issue.record(error)
        }

        #expect(sut.state.isLoading == false)
        #expect(sut.state.errorMessage == nil)
        #expect(sut.state.refreshButtonDisabled == false)
    }

    @Test
    func initialState_loadFailure() async throws {
        // Setup
        let fakeUrlSession = FakeUrlSession()
        let sut = try await createSut(fakeUrlSession: fakeUrlSession)

        // Validate the initial view state
        #expect(sut.state.isLoading == true)

        // wait for at least 1 random joke request to be initiated
        // on the urlSession.
        try await waitFor(urlCount: 1, on: fakeUrlSession)

        // Execute - cause the first joke request to fail
        fakeUrlSession.triggerJokeResponse(with: nil)

        // Validate that the expected changes were applied to the view state.
        do {
            try await TestUtility.expect(
                value: FakeUrlSession.requestError.localizedDescription,
                on: sut.$state,
                keyPath: \.errorMessage
            )
        } catch {
            // in theory, this do/catch should not be necessary, but the
            // message displayed by the debugger here is not the thrown
            // error's description.
            Issue.record(error)
        }

        #expect(sut.state.isLoading == false)
        #expect(sut.state.refreshButtonDisabled == false)
    }
}

// MARK: - Events

extension CategoryViewModelTests {
    @Test
    func refreshButtonPressed() async throws {
        // Setup
        let initialJokes = ["Joke 1", "Joke 2", "Joke 3", "Joke 4", "Joke 5"]
        let refreshJokes = ["Joke 6", "Joke 7", "Joke 8", "Joke 9", "Joke 10"]
        let fakeUrlSession = FakeUrlSession()
        let sut = try await createSut(
            fakeUrlSession: fakeUrlSession,
            makeReady: true,
            responseJokes: initialJokes
        )

        // sanity check
        try await TestUtility.expect(
            value: initialJokes,
            on: sut.$state,
            keyPath: \.jokes
        )

        // Execute
        sut.send(event: .refreshButtonPressed)

        // trigger responses for all CategoryViewModel.jokeCount (5) requests.
        try await trigger(
            jokeResponses: refreshJokes,
            on: fakeUrlSession,
            previousRequestCount: initialJokes.count
        )

        // Validate the view state after the jokes are received.
        do {
            try await TestUtility.expect(
                value: refreshJokes,
                on: sut.$state,
                keyPath: \.jokes
            )
        } catch {
            // in theory, this do/catch should not be necessary, but the
            // message displayed by the debugger here is not the thrown
            // error's description.
            Issue.record(error)
        }

        #expect(sut.state.isLoading == false)
        #expect(sut.state.errorMessage == nil)
        #expect(sut.state.refreshButtonDisabled == false)
    }
}

// MARK: - Private Helpers

private extension CategoryViewModelTests {
    func createSut(
        fakeUrlSession: FakeUrlSession = .init(),
        makeReady: Bool = false,
        responseJokes: [String] = ["Joke 1", "Joke 2", "Joke 3", "Joke 4", "Joke 5"]
    ) async throws -> CategoryViewModel {
        let sut = CategoryViewModel(categoryName: genericCategory, session: fakeUrlSession)

        if makeReady {
            try await trigger(jokeResponses: responseJokes, on: fakeUrlSession)
        }

        return sut
    }

    func waitFor(urlCount: Int, on session: FakeUrlSession) async throws {
        let predicate = #Predicate<FakeUrlSession> { fakeSession in
            fakeSession.capturedUrlCount == urlCount
        }

        try await TestUtility.wait(for: predicate, evaluateWith: session)
    }

    /// The view model makes `CategoryViewModel.jokeCount` number of random joke
    /// requests when loading and refreshing. This method waits for all of those requests to complete.
    /// - parameters:
    ///  - urlSession: The session on which the requests are made by the view model and
    ///                are fulfilled here.
    ///  - previousRequestCount: The total number of requests that have previously been
    ///                          made on the session.
    func trigger(jokeResponses: [String],
                 on fakeUrlSession: FakeUrlSession,
                 previousRequestCount: Int = 0) async throws {
        // this is a little tricky because when the view model makes a set
        // of joke requests, each request is only made after the previous
        // request returns. this means that the following gymnastics are
        // required to get through all of the requests.
        //
        // note: this would be a little less complicated if the view model
        // made the requests in parallel (it would also be more efficient for
        // the app), but that can be left as an exercise for the reader ;)
        for index in 0..<CategoryViewModel.jokeCount {
            // wait for the next joke request to be made
            try await waitFor(urlCount: previousRequestCount + index + 1, on: fakeUrlSession)

            // trigger the response to that request
            fakeUrlSession.triggerJokeResponse(
                with: ChuckNorrisJoke(iconUrl: nil,
                                      id: "id01",
                                      url: jokeUrlString,
                                      value: jokeResponses[index]))
        }
    }
}
