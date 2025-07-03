//
//  FakeNavigationRouter.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 6/30/25.
//

import SwiftUI
@testable import SwiftUI_MVVM

/// "Fake" navigation router.
///
/// This is necessary because `NavigationPath` does not provide access to its stack.
class FakeNavigationRouter: NavigationRouting {
    private(set) var capturedRoutes: [AppRoute] = []

    // MARK: NavigationRouting conformance

    @Published var path = NavigationPath()

    func push(_ route: SwiftUI_MVVM.AppRoute) {
        capturedRoutes.append(route)
        path.append(route)
    }
}
