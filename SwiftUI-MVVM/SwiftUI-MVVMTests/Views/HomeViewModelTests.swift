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
    func test_initialState_loadSuccess() async throws {
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
        try await TestUtility.wait(
            on: sut.$state,
            keyPath: \.randomJokeText,
            expectedValue: randomJoke
        )

        // Validate the view state after categories are received
        fakeUrlSession.triggerCategoriesResponse(with: categories)
        try await TestUtility.wait(
            on: sut.$state,
            keyPath: \.filteredCategories,
            expectedValue: categories
        )
    }

    @Test
    func test_initialState_loadFailure() async throws {
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
        try await TestUtility.wait(
            on: sut.$state,
            keyPath: \.randomJokeError,
            expectedValue: FakeUrlSession.requestError.localizedDescription
        )
        #expect(sut.state.randomJokeText == "")

        // Validate the view state after categories are received
        fakeUrlSession.triggerCategoriesResponse(with: nil)
        try await TestUtility.wait(
            on: sut.$state,
            keyPath: \.categoriesError,
            expectedValue: FakeUrlSession.requestError.localizedDescription
        )
        #expect(sut.state.filteredCategories == [])
    }
}

// MARK: - Private Helpers

private extension HomeViewModelTests {
    func createSut(
        fakeUrlSession: FakeUrlSession = .init(),
        router: NavigationRouter = .init(),
        makeReady: Bool = false
    ) async throws -> HomeViewModel {
        let sut = HomeViewModel(session: fakeUrlSession, router: router)

        if makeReady {
            // wait for the init() actions to complete (i.e. the two `get()`
            // requests on the urlSession)
            try await waitFor(urlCount: 2, on: fakeUrlSession)

            // get to the `.ready` state
            fakeUrlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
            fakeUrlSession.triggerCategoriesResponse(with: categories)
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
