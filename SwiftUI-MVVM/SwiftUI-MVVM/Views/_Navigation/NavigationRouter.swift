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

final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }
}
