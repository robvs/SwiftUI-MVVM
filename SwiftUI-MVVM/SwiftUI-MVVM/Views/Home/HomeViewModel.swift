//
//  HomeViewModel.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/26/25.
//

import Combine
import OSLog

final class HomeViewModel: ViewModel {
    @Published var state: State

    // MARK: Private Properties

    private let session: AppUrlSessionHandling

    // MARK: Object lifecycle

    init(state: State = State(), session: AppUrlSessionHandling) {
        self.state = state
        self.session = session

        fetchData()
    }

    // MARK: State

    /// Encapsulation of values that drive the dynamic elements of the associated view.
    ///
    /// The default values indicate the intended initial state.
    struct State: Equatable {
        var randomJoke: String?
        var randomJokeError: String?
        var categories: [String]?
        var categoriesError: String?
        var refreshButtonDisabled: Bool = true
    }

    // MARK: Events

    enum Event {
        case categorySelected(name: String)
        case refreshButtonPressed
    }

    func send(event: Event) {
        switch event {
        case .categorySelected(let name):
            break
        case .refreshButtonPressed:
            break
        }
    }
}

// MARK: - Private Helpers

private extension HomeViewModel {
    func fetchData() {
        state.refreshButtonDisabled = true
        state.randomJoke = nil
        state.randomJokeError = nil
        state.categoriesError = nil

        // run both random joke and categories requests in parallel.

        Task {
            Logger.api.trace("isMainThread: \(Thread.isMainThread)")

            do {
                let joke: ChuckNorrisJoke = try await session.get(from: ChuckNorrisIoRequest.getRandomJoke().url)
                state.randomJoke = joke.value
            } catch let requestError as AppUrlSession.RequestError {
                state.randomJokeError = requestError.localizedDescription
            } catch {
                state.randomJokeError = AppUrlSession.RequestError.unexpected(error.localizedDescription).localizedDescription
            }

            state.refreshButtonDisabled = false
        }

        Task {
            Logger.api.trace("isMainThread: \(Thread.isMainThread)")

            do {
                state.categories = try await session.get(from: ChuckNorrisIoRequest.getCategories.url)
            } catch let requestError as AppUrlSession.RequestError {
                state.categoriesError = requestError.localizedDescription
            } catch {
                state.categoriesError = AppUrlSession.RequestError.unexpected(error.localizedDescription).localizedDescription
            }

            state.refreshButtonDisabled = false
        }
    }
}
