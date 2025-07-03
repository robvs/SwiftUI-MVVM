//
//  NavigationRouter.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 6/2/25.
//

import Combine
import SwiftUI

enum AppRoute: Hashable {
    case category(name: String)
}

/// Interface for a navigation router to be used by a `NavigationStack`.
protocol NavigationRouting: ObservableObject {
    /// The current navigation path for a `NavigationStack`.
    ///
    /// NOTE: Even though this provides `set` access, setting (i.e. appending or removing)
    /// should only be done by `NavigationRouting` methods or a `NavigationStack`.
    var path: NavigationPath { get set }
    func push(_ route: AppRoute)
}

final class NavigationRouter: NavigationRouting {
    @Published var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }
}
