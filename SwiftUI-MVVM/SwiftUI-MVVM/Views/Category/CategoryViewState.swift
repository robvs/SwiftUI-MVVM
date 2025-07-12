//
//  CategoryViewState.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 7/12/25.
//

/// Encapsulation of values that drive the dynamic elements of the associated view.
///
/// The default values indicate the intended initial state.
struct CategoryViewState: Equatable {
    // MARK: Public Properties
    // These properties define the view's state. They are publicly
    // readable but privately settable in order to force all state
    // changes to funnel through the `mutating` functions.

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
    // only to illustrate a less regid approach to state updates.

    /// Transform the properties to represent the loading state.
    mutating func handleLoading() {
        isLoading = true
        jokes = []
        errorMessage = nil
        refreshButtonDisabled = true
    }

    /// Transform the properties to represent a loaded state with the given result.
    /// - Parameter result: The results from a data request for a set of random jokes.
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
