//
//  SwiftUI_MVVMApp.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/23/25.
//

import SwiftUI

@main
struct SwiftUI_MVVMApp: App {
    @StateObject var router = NavigationRouter()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                homeView
            }
        }
    }
}

// MARK: - Home View & Navigation

private extension SwiftUI_MVVMApp {
    var homeView: some View {
        HomeView(viewModel: HomeViewModel(session: AppUrlSession.shared, router: router))
            .navigationDestination(for: AppRoute.self) { route in
                view(for: route)
            }
    }

    func view(for route: AppRoute) -> some View {
        switch route {
        case .category(let name):
            CategoryView(viewModel: CategoryViewModel(
                categoryName: name,
                session: AppUrlSession.shared
            ))
        }
    }
}
