//
//  CategoryView.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/27/25.
//

import SwiftUI

/// Displays a set of random jokes for a specific category.
struct CategoryView<ViewModelType: ViewModeling>: View where
ViewModelType.State == CategoryViewModel.State,
ViewModelType.Event == CategoryViewModel.Event {
    @ObservedObject var viewModel: ViewModelType

    /// Convenience property to give direct access to `viewModel.state`.
    private var state: ViewModelType.State { viewModel.state }

    private let placeHolderText = "If Chuck Norris goes to Z'ha'dum, he would not die."

    var body: some View {
        VStack(alignment: .leading) {
            Text("Random \(state.categoryName) Jokes")
                .appTitle2()

            if let errorMessage = state.errorMessage {
                Text(errorMessage)
                    .appTextError()
                    .padding(.top)
            }

            if state.isLoading {
                loadingPlaceholder()
            }
            else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(state.jokes, id: \.self) { joke in
                            row(with: joke)
                        }
                    }
                }
            }

            refreshButton
                .padding(.vertical)
        }
        .padding(.top, 8)
        .padding(.horizontal)
        .navigationTitle(state.categoryName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Subviews

private extension CategoryView {
    func loadingPlaceholder() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                row(with: placeHolderText)
                row(with: placeHolderText)
                row(with: placeHolderText)
            }
            .redacted(reason: .placeholder)
        }
    }

    func row(with joke: String) -> some View {
        HStack(spacing: 0) {
            Text(joke)
                .appBodyTextSmall()
                .italic()
            Spacer(minLength: 0)
        }
    }

    var refreshButton: some View {
        HStack {
            Spacer(minLength: 0)

            Button("Refresh") {
                viewModel.send(event: .refreshButtonPressed)
            }
            .buttonStyle(AppButtonStyle.Primary())
            .disabled(state.refreshButtonDisabled)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Previews

private final class FakeViewModel: ViewModeling {
    @Published var state: CategoryViewModel.State
    func send(event: CategoryViewModel.Event) {}

    init(state: CategoryViewModel.State) {
        self.state = state
    }
}

#Preview("default") {
    let viewModel = FakeViewModel(state: .init(categoryName: "Category 1"))
    return CategoryView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("loading") {
    let viewModel = FakeViewModel(state: .init(categoryName: "Category 1"))
    viewModel.state.handleLoading()

    return CategoryView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("ready") {
    let viewModel = FakeViewModel(state: .init(categoryName: "Category 1"))
    let result = GetRandomJokesResult.success([
        PreviewHelper.createJoke("Joke 1"),
        PreviewHelper.createJoke("Joke 2")]
    )
    viewModel.state.handleRandomJokesResult(result)

    return CategoryView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("error") {
    let viewModel = FakeViewModel(state: .init(categoryName: "Category 1"))
    let result = GetRandomJokesResult.failure(AppUrlSession.RequestError.serverResponse(code: 404))
    viewModel.state.handleRandomJokesResult(result)
    return CategoryView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let viewModel = FakeViewModel(state: .init(categoryName: "Category 1"))
    return CategoryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

fileprivate enum PreviewHelper {
    static func createJoke(_ text: String) -> ChuckNorrisJoke {
        ChuckNorrisJoke(
            iconUrl: nil,
            id: "",
            url: "",
            value: text
        )    }
}
