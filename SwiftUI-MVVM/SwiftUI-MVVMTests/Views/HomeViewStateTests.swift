//
//  HomeViewStateTests.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 7/12/25.
//

@testable import SwiftUI_MVVM
import Testing

struct HomeViewStateTests {
    // MARK: generic test data

    private let randomJoke = "Chuck Norris was once bitten by a rattlesnake, and after three days of suffering... the rattlesnake finally died!"
    private let categories = ["category01", "category02"]
}

// MARK: - Initial State

extension HomeViewStateTests {
    @Test
    func initialState() async throws {
        // Setup/Execute
        let state = HomeViewState()

        // Validate (loading state)
        #expect(state.randomJokeText == nil)
        #expect(state.randomJokeError == nil)
        #expect(state.filteredCategories == nil)
        #expect(state.categoriesError == nil)
        #expect(state.refreshButtonDisabled == true)
    }
}

// MARK: - Effect - loadingRandomJoke

extension HomeViewStateTests {
    @Test
    func loadingRandomJoke() async throws {
        // Setup
        var state = HomeViewState()
        let joke = ChuckNorrisJoke(
            iconUrl: nil,
            id: "id01",
            url: "",
            value: randomJoke
        )

        state.reduce(with: .getCategoriesResult(.success(categories)))
        state.reduce(with: .getRandomJokeResult(.success(joke)))

        // sanity check
        #expect(state.randomJokeText == joke.value)

        // Execute
        state.reduce(with: .loadingRandomJoke)

        // Validate (loading state)
        #expect(state.randomJokeText == nil)
        #expect(state.randomJokeError == nil)
        #expect(state.filteredCategories == categories)
        #expect(state.categoriesError == nil)
        #expect(state.refreshButtonDisabled == true)
    }
}

// MARK: - Effect - getCategoriesResult

extension HomeViewStateTests {
    @Test
    func getCategoriesResult_success() async throws {
        // Setup
        var state = HomeViewState()

        // Execute
        state.reduce(with: .getCategoriesResult(.success(categories)))

        // Validate (loading state)
        #expect(state.randomJokeText == nil)
        #expect(state.randomJokeError == nil)
        #expect(state.filteredCategories == categories)
        #expect(state.categoriesError == nil)
        #expect(state.refreshButtonDisabled == true)
    }

    @Test
    func getCategoriesResult_failure() async throws {
        // Setup
        let error: AppUrlSession.RequestError = .serverResponse(code: 404)
        var state = HomeViewState()

        // Execute
        state.reduce(with: .getCategoriesResult(.failure(error)))

        // Validate (loading state)
        #expect(state.randomJokeText == nil)
        #expect(state.randomJokeError == nil)
        #expect(state.filteredCategories == [])
        #expect(state.categoriesError == error.localizedDescription)
        #expect(state.refreshButtonDisabled == true)
    }
}

// MARK: - Effect - getRandomJokeResult

extension HomeViewStateTests {
    @Test
    func getRandomJokeResult_success() async throws {
        // Setup
        var state = HomeViewState()
        let joke = ChuckNorrisJoke(
            iconUrl: nil,
            id: "id01",
            url: "",
            value: randomJoke
        )

        // Execute
        state.reduce(with: .getRandomJokeResult(.success(joke)))

        // Validate (loading state)
        #expect(state.randomJokeText == joke.value)
        #expect(state.randomJokeError == nil)
        #expect(state.filteredCategories == nil)
        #expect(state.categoriesError == nil)
        #expect(state.refreshButtonDisabled == false)
    }

    @Test
    func getRandomJokeResult_failure() async throws {
        // Setup
        let error: AppUrlSession.RequestError = .serverResponse(code: 404)
        var state = HomeViewState()

        // Execute
        state.reduce(with: .getRandomJokeResult(.failure(error)))

        // Validate (loading state)
        #expect(state.randomJokeText == nil)
        #expect(state.randomJokeError == error.localizedDescription)
        #expect(state.filteredCategories == nil)
        #expect(state.categoriesError == nil)
        #expect(state.refreshButtonDisabled == false)
    }
}
