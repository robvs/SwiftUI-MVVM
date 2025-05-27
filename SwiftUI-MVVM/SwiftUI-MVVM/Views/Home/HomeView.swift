//
//  HomeView.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/26/25.
//

import OSLog
import SwiftUI

/// Displays a random joke and a list of available categories.
struct HomeView<ViewModelType: ViewModel>: View where
ViewModelType.State == HomeViewModel.State,
ViewModelType.Event == HomeViewModel.Event {
    @ObservedObject var viewModel: ViewModelType

    /// Convenience property to give direct access to `viewModel.state`.
    private var state: HomeViewModel.State { viewModel.state }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header()

            randomJoke()

            categories()
        }
        .padding(.horizontal)
        .navigationTitle("Home")
        .toolbar(.hidden, for: .navigationBar)
    }
}


// MARK: - Subviews

private extension HomeView {
    func header() -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Chuck Norris Jokes")
                        .appTitle1()

                    Spacer()

                    HStack {
                        Spacer()
                        Text("Powered by")
                            .appBodyTextSmall()
                    }
                }

                Image("chucknorris_logo")
                    .scale(height: 50)
            }
            .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.top, 8)
        }
    }

    func randomJoke() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Random Joke")
                    .appTitle2()

                Spacer()

                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(state.refreshButtonDisabled ? .appOnSurfaceDisabled : .appTextLink)
                    .disabled(state.refreshButtonDisabled)
                    .onTapGesture {
                        viewModel.send(event: .refreshButtonPressed)
                    }
            }

            error(message: state.randomJokeError)

            Group {
                if let randomJoke = state.randomJoke {
                    Text(randomJoke)
                        .appBodyText()
                        .italic()
                }
                else {
                    Text("This is dummy text to provide something to be redacted.")
                        .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal)
        }
    }

    func categories() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Categories")
                .appTitle2()

            error(message: state.categoriesError)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let categoryNames = state.categories {
                        ForEach(categoryNames, id: \.self) { categoryName in
                            HomeCategoryListRow(categoryName: categoryName)
                                .onTapGesture {
                                    viewModel.send(event: .categorySelected(name: categoryName))
                                }
                        }
                    }
                    else {
                        Group {
                            Text("Category 1")
                            Text("Category 2")
                            Text("Category 3")
                        }
                        .redacted(reason: .placeholder)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    func error(message: String?) -> some View {
        if let message = message {
            Text(message)
                .appTextError()
        }
        else {
            EmptyView()
        }
    }
}


// MARK: - Previews

private final class FakeViewModel: ViewModel {
    @Published var state = HomeViewModel.State()
    func send(event: HomeViewModel.Event) {}
}

#Preview("Initial State") {
    HomeView(viewModel: FakeViewModel())
        .preferredColorScheme(.light)
}

#Preview("Joke Loaded") {
    let viewModel = FakeViewModel()
    viewModel.state.reduce(with: .getRandomJokeResult(.success(randomJoke)))

    return HomeView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("Categories Loaded") {
    let viewModel = FakeViewModel()
    let result = GetCategoriesResult.success(categoryNames)
    viewModel.state.reduce(with: .getCategoriesResult(result))

    return HomeView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("Ready") {
    let viewModel = FakeViewModel()
    let jokeResult = GetRandomJokeResult.success(randomJoke)
    let categoriesResult = GetCategoriesResult.success(categoryNames)
    viewModel.state.reduce(with: .getRandomJokeResult(jokeResult))
    viewModel.state.reduce(with: .getCategoriesResult(categoriesResult))

    return HomeView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("Errors") {
    let viewModel = FakeViewModel()
    let jokeError = AppUrlSession.RequestError.serverResponse(code: 404)
    let categoriesError = AppUrlSession.RequestError.serverResponse(code: 404)
    let jokeResult = GetRandomJokeResult.failure(jokeError)
    let categoriesResult = GetCategoriesResult.failure(categoriesError)
    viewModel.state.reduce(with: .getRandomJokeResult(jokeResult))
    viewModel.state.reduce(with: .getCategoriesResult(categoriesResult))

    return HomeView(viewModel: viewModel)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HomeView(viewModel: FakeViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Dark Errors") {
    let viewModel = FakeViewModel()
    let jokeError = AppUrlSession.RequestError.serverResponse(code: 404)
    let categoriesError = AppUrlSession.RequestError.serverResponse(code: 404)
    let jokeResult = GetRandomJokeResult.failure(jokeError)
    let categoriesResult = GetCategoriesResult.failure(categoriesError)
    viewModel.state.reduce(with: .getRandomJokeResult(jokeResult))
    viewModel.state.reduce(with: .getCategoriesResult(categoriesResult))

    return HomeView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

fileprivate let randomJoke = "Chuck Norris can kill you with a headshot using a shotgun from across the map on call of duty."
fileprivate let categoryNames = ["animal","career","celebrity","dev","explicit","fashion","food","history","money","movie","music","political","religion","science","sport","travel"]
