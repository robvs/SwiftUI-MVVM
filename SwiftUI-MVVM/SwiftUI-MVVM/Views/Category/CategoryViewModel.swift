//
//  CategoryViewModel.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/27/25.
//

import OSLog
import SwiftUI

final class CategoryViewModel: ViewModeling {
    @Published var state: State

    nonisolated static let jokeCount = 5
    private let session: any AppUrlSessionHandling

    /// Create a new instance.
    /// - Parameters:
    ///   - state: The initial view state values.
    ///   - session: Injected URL session handler.
    init(categoryName: String, session: any AppUrlSessionHandling) {
        self.state = State(categoryName: categoryName)
        self.session = session

        fetchRandomJokes(for: categoryName)
    }

    // MARK: Events

    enum Event {
        case refreshButtonPressed
    }

    func send(event: Event) {
        switch event {
        case .refreshButtonPressed:
            fetchRandomJokes(for: state.categoryName)
        }
    }
}

// MARK: - Private Helpers

private extension CategoryViewModel {
    func fetchRandomJokes(for category: String) {
        state.handleLoading()

        Task {
            let result: GetRandomJokesResult
            do {
                // fetch a set of random category jokes
                var jokes: [ChuckNorrisJoke] = []
                for _ in 0..<Self.jokeCount {
                    let jokeUrl = ChuckNorrisIoRequest.getRandomJoke(category: category).url
                    let joke: ChuckNorrisJoke = try await session.get(from: jokeUrl)

                    if !jokes.contains(where: { $0.value == joke.value }) {
                        jokes.append(joke)
                    }
                }

                result = GetRandomJokesResult.success(jokes)
            }
            catch let requestError as AppUrlSession.RequestError {
                result = GetRandomJokesResult.failure(requestError)
            }
            catch {
                result = GetRandomJokesResult.failure(AppUrlSession.RequestError.unexpected(error.localizedDescription))
            }

            Logger.view.trace("Fetch result: \(String(describing: result))")
            state.handleRandomJokesResult(result)
        }
    }
}

// MARK: - View State

extension CategoryViewModel {
    /// Encapsulation of values that drive the dynamic elements of the associated view.
    ///
    /// The default values indicate the intended initial state.
    struct State: Equatable {
        let categoryName: String
        private(set) var isLoading: Bool = true
        private(set) var jokes: [String] = []
        private(set) var errorMessage: String?
        private(set) var refreshButtonDisabled: Bool = true

        init(categoryName: String) {
            self.categoryName = categoryName
        }

        // MARK: State Changes
        // This differs from the `reduce(with:)` function in `HomeViewModel`
        // only to illustrate a less formal approach to state updates.

        mutating func handleLoading() {
            isLoading = true
            jokes = []
            errorMessage = nil
            refreshButtonDisabled = true
        }

        mutating func handleRandomJokesResult(_ result: GetRandomJokesResult) {
            switch result {
            case .success(let newJokes):
                isLoading = false
                jokes = newJokes.map { $0.value }
                errorMessage = nil
                refreshButtonDisabled = false

            case .failure(let error):
                isLoading = false
                errorMessage = error.localizedDescription
                refreshButtonDisabled = false
            }
        }
    }
}
