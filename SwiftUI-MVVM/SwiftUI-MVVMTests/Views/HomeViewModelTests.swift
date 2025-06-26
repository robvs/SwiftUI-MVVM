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
        #expect(sut.state.randomJoke == nil)
        #expect(sut.state.filteredCategories == nil)

        // wait for the init() actions to complete (i.e. the two `get()`
        // requests on the urlSession)
        try await waitFor(urlCount: 2, on: fakeUrlSession)

        // Validate the view state after a random joke is received
        fakeUrlSession.triggerJokeResponse(with: ChuckNorrisJoke(iconUrl: nil, id: "id01", url: jokeUrlString, value: randomJoke))
        try await expect(joke: randomJoke, on: sut)

        // Validate the view state after categories are received
        fakeUrlSession.triggerCategoriesResponse(with: categories)
        try await expect(categories: categories, on: sut)
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
            keyPath: \.randomJoke
        )

        try await TestUtility.waitNotNil(
            on: viewModel.$state,
            keyPath: \.filteredCategories
        )
    }

    func expect(joke: String, on viewModel: HomeViewModel) async throws {
        try await TestUtility.wait(
            on: viewModel.$state,
            keyPath: \.randomJoke,
            expectedValue: joke
        )
    }

    func expect(categories: [String], on viewModel: HomeViewModel) async throws {
        try await TestUtility.wait(
            on: viewModel.$state,
            keyPath: \.filteredCategories,
            expectedValue: categories
        )
    }

    func waitFor(urlCount: Int, on session: FakeUrlSession) async throws {
        let predicate = #Predicate<FakeUrlSession> { fakeSession in
            fakeSession.capturedUrlCount == urlCount
        }

        try await TestUtility.wait(for: predicate, evaluateWith: session)
    }
}
