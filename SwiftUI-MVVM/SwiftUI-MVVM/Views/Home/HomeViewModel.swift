//
//  HomeViewModel.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/26/25.
//

import Combine
import OSLog

final class HomeViewModel: ViewModeling {
    @Published var state: State

    private let session: any AppUrlSessionHandling
    private let router: NavigationRouter

    /// Create a new instance.
    /// - Parameters:
    ///   - state: The initial view state values.
    ///   - session: Injected URL session handler.
    init(session: any AppUrlSessionHandling, router: NavigationRouter) {
        self.state = State()
        self.session = session
        self.router = router

        fetchData()
    }

    // MARK: Events

    enum Event {
        case searchTextChanged(String)
        case categorySelected(name: String)
        case refreshButtonPressed
    }

    func send(event: Event) {
        switch event {
        case .searchTextChanged(let searchText):
            state.reduce(with: .filterCategories(searchText: searchText))
        case .categorySelected(let name):
            Logger.view.debug("Category selected: \(name)")
            router.push(.category(name: name))
        case .refreshButtonPressed:
            fetchData()
        }
    }
}

// MARK: - Private Helpers

private extension HomeViewModel {
    func fetchData() {
        state.reduce(with: .loadingRandomJoke)

        // run both random joke and categories requests in parallel.

        Task {
            let result: GetRandomJokeResult
            do {
                let joke: ChuckNorrisJoke = try await session.get(from: ChuckNorrisIoRequest.getRandomJoke().url)
                result = .success(joke.value)
            } catch let requestError as AppUrlSession.RequestError {
                result = .failure(requestError)
            } catch {
                result = .failure(AppUrlSession.RequestError.unexpected(error.localizedDescription))
            }

            state.reduce(with: .getRandomJokeResult(result))
        }

        Task {
            let result: GetCategoriesResult
            do {
                let categories: [String] = try await session.get(from: ChuckNorrisIoRequest.getCategories.url)
                result = .success(categories)
            } catch let requestError as AppUrlSession.RequestError {
                result = .failure(requestError)
            } catch {
                result = .failure(AppUrlSession.RequestError.unexpected(error.localizedDescription))
            }

            state.reduce(with: .getCategoriesResult(result))
        }
    }
}

// MARK: - View State

extension HomeViewModel {
    /// Encapsulation of values that drive the dynamic elements of the associated view.
    ///
    /// The default values indicate the intended initial state.
    struct State: Equatable {
        private(set) var randomJoke: String?
        private(set) var randomJokeError: String?
        private(set) var filteredCategories: [String]?
        private(set) var categoriesError: String?
        private(set) var refreshButtonDisabled: Bool = true

        private var allCategories: [String] = []

        // MARK: Events that effect the state

        /// Items that designate how the view state should change, usually
        /// the result of an `Event`.
        enum Effect: Equatable {
            /// Indicates that the random joke is being fetched.
            case loadingRandomJoke

            /// Indicates that retrieval of the random joke is complete.
            case getCategoriesResult(GetCategoriesResult)

            /// Indicates that retrieval of the random joke is complete.
            case getRandomJokeResult(GetRandomJokeResult)

            case filterCategories(searchText: String)
        }

        /// Handle changes from the current state to the next state.
        /// - Parameter effect: Directive of how the state should change.
        mutating func reduce(with effect: Effect) {
            switch effect {
            case .loadingRandomJoke:
                refreshButtonDisabled = true
                randomJoke = nil
                randomJokeError = nil

            case .getRandomJokeResult(let result):
                refreshButtonDisabled = false

                switch result {
                case .success(let joke):
                    randomJoke = joke
                    randomJokeError = nil
                case .failure(let error):
                    randomJoke = ""
                    randomJokeError = error.localizedDescription
                }

            case .getCategoriesResult(let result):
                switch result {
                case .success(let categories):
                    allCategories = categories
                    filteredCategories = categories
                    categoriesError = nil
                case .failure(let error):
                    allCategories = []
                    filteredCategories = []
                    categoriesError = error.localizedDescription
                }

            case .filterCategories(let searchText):
                filteredCategories = allCategories.filter {
                    $0.range(of: searchText, options: [.caseInsensitive, .regularExpression]) != nil
                }
            }
        }
    }
}
