//
//  CategoryViewStateTests.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 7/20/25.
//

@testable import SwiftUI_MVVM
import Testing

struct CategoryViewStateTests {
    // MARK: generic test data

    private let categoryName = "category01"
    private let randomJokes = Self.createRandomJokes()
}

// MARK: - Initial State

extension CategoryViewStateTests {
    @Test
    func initialState() async throws {
        // Setup/Execute
        let state = CategoryViewState(categoryName: categoryName)

        // Validate (loading state)
        #expect(state.categoryName == categoryName)
        #expect(state.isLoading == true)
        #expect(state.jokes == [])
        #expect(state.errorMessage == nil)
        #expect(state.refreshButtonDisabled == true)
    }
}

// MARK: - handleRandomJokesResult()

extension CategoryViewStateTests {
    @Test
    func handleRandomJokesResult_success() async throws {
        // Setup
        var state = CategoryViewState(categoryName: categoryName)

        // Execute
        state.handleRandomJokesResult(.success(randomJokes))

        // Validate (loading state)
        #expect(state.categoryName == categoryName)
        #expect(state.isLoading == false)
        #expect(state.jokes == randomJokes.map { $0.value })
        #expect(state.errorMessage == nil)
        #expect(state.refreshButtonDisabled == false)
    }

    @Test
    func handleRandomJokesResult_failure() async throws {
        // Setup
        let error: AppUrlSession.RequestError = .serverResponse(code: 404)
        var state = CategoryViewState(categoryName: categoryName)

        // Execute
        state.handleRandomJokesResult(.failure(error))

        // Validate (loading state)
        #expect(state.categoryName == categoryName)
        #expect(state.isLoading == false)
        #expect(state.jokes == [])
        #expect(state.errorMessage == error.localizedDescription)
        #expect(state.refreshButtonDisabled == false)
    }
}

// MARK: - handleLoading()

extension CategoryViewStateTests {
    @Test
    func handleLoading() async throws {
        // Setup
        var state = CategoryViewState(categoryName: categoryName)
        state.handleRandomJokesResult(.success(randomJokes))

        // sanity check
        #expect(state.isLoading == false)

        // Execute
        state.handleLoading()

        // Validate (loading state)
        #expect(state.categoryName == categoryName)
        #expect(state.isLoading == true)
        #expect(state.jokes == [])
        #expect(state.errorMessage == nil)
        #expect(state.refreshButtonDisabled == true)
    }
}

// MARK: - Private Helpers

private extension CategoryViewStateTests {
    static func createRandomJokes() -> [ChuckNorrisJoke] {
        [
            ChuckNorrisJoke(
                iconUrl: nil,
                id: "id01",
                url: "",
                value: "joke 1"
            ),
            ChuckNorrisJoke(
                iconUrl: nil,
                id: "id02",
                url: "",
                value: "joke 2"
            ),
            ChuckNorrisJoke(
                iconUrl: nil,
                id: "id03",
                url: "",
                value: "joke 3"
            )
        ]
    }
}
