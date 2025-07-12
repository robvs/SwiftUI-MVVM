//
//  HomeViewState.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 7/12/25.
//

/// Encapsulation of values that drive the dynamic elements of the associated view.
///
/// The default values indicate the intended initial state of the view.
struct HomeViewState: Equatable {
    // MARK: Public Properties
    // These properties define the view's state. They are publicly
    // readable but privately settable in order to force all state
    // changes to funnel through the `reduce()` method.

    // Calculated property that provides access to the value of
    // data model property while preventing the view from being
    // dependent on the raw data model.
    var randomJokeText: String? { randomJoke?.value }

    private(set) var randomJokeError: String?
    private(set) var filteredCategories: [String]?
    private(set) var categoriesError: String?
    private(set) var refreshButtonDisabled: Bool = true

    // MARK: Private Properties

    private var randomJoke: ChuckNorrisJoke?
    private var allCategories: [String] = []

    /// Init a new instance with the given joke.
    init(randomJoke: ChuckNorrisJoke? = nil) {
        // A reference to the data model object is held here to
        // demonstrate how to pass it to another view's state without
        // exposing it to the view. Ideally, views should not be
        // dependent upon low-level data models - it is the job of
        // the view model or view state to translate/transform the
        // data model's values for presentation to the user.
        self.randomJoke = randomJoke
    }

    // MARK: Events that affect the state

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
                randomJoke = nil
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
