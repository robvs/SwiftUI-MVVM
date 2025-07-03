//
//  HomeViewModelTests.swift
//  HomeViewModelTests
//
//  Created by Rob Vander Sloot on 5/23/25.
//

import Combine
import Foundation
@testable import SwiftUI_MVVM
import Testing

@MainActor
struct HomeViewModelTests {
    // MARK: generic test data

    private let jokeUrlString = "https://api.chucknorris.io/jokes/uKVtJZN4TMmT55lX3v752A"
    private let randomJoke = "Chuck Norris was once bitten by a rattlesnake, and after three days of suffering... the rattlesnake finally died!"
    private let categories = ["category01", "category02"]
    private var cancellables: [AnyCancellable] = []
}

// MARK: - Initialization

extension HomeViewModelTests {
    @Test
    func initialState_loadSuccess() async throws {
        // Setup/Execute
        let fakeUrlSession = FakeUrlSession()
        let sut = try await createSut(fakeUrlSession: fakeUrlSession)

        // Validate the initial view state
        #expect(sut.state.randomJokeText == nil)
        #expect(sut.state.filteredCategories == nil)

        // wait for the init() actions to complete (i.e. the two `get()`
        // requests on the urlSession)
        try await waitFor(urlCount: 2, on: fakeUrlSession)

        // Validate the view state after a random joke is received
        fakeUrlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
        try await TestUtility.expect(
            value: randomJoke,
            on: sut.$state,
            keyPath: \.randomJokeText
        )

        // Validate the view state after categories are received
        fakeUrlSession.triggerCategoriesResponse(with: categories)
        try await TestUtility.expect(
            value: categories,
            on: sut.$state,
            keyPath: \.filteredCategories
        )
    }

    @Test
    func initialState_loadFailure() async throws {
        // Setup/Execute
        let fakeUrlSession = FakeUrlSession()
        let sut = try await createSut(fakeUrlSession: fakeUrlSession)

        // Validate the initial view state
        #expect(sut.state.randomJokeText == nil)
        #expect(sut.state.filteredCategories == nil)

        // wait for the init() actions to complete (i.e. the two `get()`
        // requests on the urlSession)
        try await waitFor(urlCount: 2, on: fakeUrlSession)

        // Validate the view state after a random joke is received
        fakeUrlSession.triggerJokeResponse(with: nil)
        do {
            try await TestUtility.expect(
                value: FakeUrlSession.requestError.localizedDescription,
                on: sut.$state,
                keyPath: \.randomJokeError
            )
        } catch {
            // in theory, this do/catch should not be necessary, but the
            // message displayed by the debugger here is not the thrown
            // error's description.
            Issue.record(error)
        }

        #expect(sut.state.randomJokeText == nil)

        // Validate the view state after categories are received
        fakeUrlSession.triggerCategoriesResponse(with: nil)
        do {
            try await TestUtility.expect(
                value: FakeUrlSession.requestError.localizedDescription,
                on: sut.$state,
                keyPath: \.categoriesError
            )
        } catch {
            // in theory, this do/catch should not be necessary, but the
            // message displayed by the debugger here is not the thrown
            // error's description.
            Issue.record(error)
        }

        #expect(sut.state.filteredCategories == [])
    }
}

// MARK: - Events

extension HomeViewModelTests {
    @Test(
        arguments: [
            (
                allCategories: ["cat01", "cat02", "cat003", "cat004"],
                searchText: "",
                expectedCategories: ["cat01", "cat02", "cat003", "cat004"]
            ),
            (
                allCategories: ["cat01", "cat02", "cat003", "cat004"],
                searchText: "cat00",
                expectedCategories: ["cat003", "cat004"]
            ),
            (
                allCategories: ["cat01", "cat02", "cat003", "cat004"],
                searchText: "02",
                expectedCategories: ["cat02"]
            ),
            (
                allCategories: ["cat01", "cat02", "cat003", "cat004"],
                searchText: "nothing",
                expectedCategories: []
            )
        ]
    )
    func searchTextChanged(
        allCategories: [String],
        searchText: String,
        expectedCategories: [String]
    ) async throws {
        // Setup
        let fakeUrlSession = FakeUrlSession()
        let fakeRouter = FakeNavigationRouter()
        let sut = try await createSut(
            fakeUrlSession: fakeUrlSession,
            router: fakeRouter,
            allCategories: allCategories,
            makeReady: true
        )

        // Execute
        sut.send(event: .searchTextChanged(searchText))

        // Validate
        #expect(sut.state.filteredCategories == expectedCategories)
    }

    @Test
    func categorySelected() async throws {
        // Setup
        let selectedCategory = categories[0]
        let fakeUrlSession = FakeUrlSession()
        let fakeRouter = FakeNavigationRouter()
        let sut = try await createSut(
            fakeUrlSession: fakeUrlSession,
            router: fakeRouter,
            makeReady: true
        )

        // Execute
        sut.send(event: .categorySelected(name: selectedCategory))

        // Validate
        #expect(fakeRouter.capturedRoutes[0] == .category(name: selectedCategory))
    }

    @Test
    func refreshButtonPressed() async throws {
        // Setup
        let fakeUrlSession = FakeUrlSession()
        let sut = try await createSut(
            fakeUrlSession: fakeUrlSession,
            makeReady: true
        )
        let sessionUrlCount = fakeUrlSession.capturedUrls.count

        // Execute
        sut.send(event: .refreshButtonPressed)

        // wait for the refresh `get()` request to be made on the urlSession
        try await waitFor(urlCount: sessionUrlCount + 1, on: fakeUrlSession)

        // Validate
        #expect(sut.state.refreshButtonDisabled == true)
        #expect(sut.state.randomJokeText == nil)

        fakeUrlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
        try await TestUtility.expect(
            value: randomJoke,
            on: sut.$state,
            keyPath: \.randomJokeText
        )
    }
}

// MARK: - Private Helpers

private extension HomeViewModelTests {
    func createSut(
        fakeUrlSession: FakeUrlSession = .init(),
        router: FakeNavigationRouter = FakeNavigationRouter(),
        allCategories: [String]? = nil,
        makeReady: Bool = false
    ) async throws -> HomeViewModel {
        let sut = HomeViewModel(session: fakeUrlSession, router: router)

        if makeReady {
            // wait for the init() actions to complete (i.e. the two `get()`
            // requests on the urlSession)
            try await waitFor(urlCount: 2, on: fakeUrlSession)

            // get to the `.ready` state
            fakeUrlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
            fakeUrlSession.triggerCategoriesResponse(with: allCategories ?? categories)
            try await expectReady(on: sut)
        }

        return sut
    }

    /// Wait for the random joke and categories to be loaded on the given view interactor.
    /// - parameters:
    ///  - viewModel: The view model on which async tasks are in process.
    func expectReady(on viewModel: HomeViewModel) async throws {
        try await TestUtility.waitNotNil(
            on: viewModel.$state,
            keyPath: \.randomJokeText
        )

        try await TestUtility.waitNotNil(
            on: viewModel.$state,
            keyPath: \.filteredCategories
        )
    }

    func waitFor(urlCount: Int, on session: FakeUrlSession) async throws {
        let predicate = #Predicate<FakeUrlSession> { fakeSession in
            fakeSession.capturedUrlCount == urlCount
        }

        try await TestUtility.wait(for: predicate, evaluateWith: session)
    }
}
