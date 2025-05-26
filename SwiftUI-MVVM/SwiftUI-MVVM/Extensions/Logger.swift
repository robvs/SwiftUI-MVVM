//
//  Logger.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/25/25.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!

    /// Used for logging view-related messages
    static let view = Logger(subsystem: subsystem, category: "view")

    /// Used for logging api-related messages
    static let api = Logger(subsystem: subsystem, category: "api")
}
