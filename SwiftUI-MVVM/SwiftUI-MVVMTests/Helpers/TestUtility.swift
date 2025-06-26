//
//  TestUtility.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 6/23/25.
//

import Combine
import Foundation
import OSLog
@testable import SwiftUI_MVVM

enum TestUtility {
    /// Wait up to `timeout` seconds for the given predicate to succeed.
    ///
    /// NOTE: `Predicate<>` only supports very simple closures and definitely does not
    /// work with `@Published` properties.
    ///
    /// Usage:
    /// ```swift
    /// let session = FakeUrlSession()
    /// ...
    /// let predicate = #Predicate<FakeUrlSession> { fakeSession in
    ///     fakeSession.requestCount == expectedCount
    /// }
    ///
    /// try await TestUtility.wait(for: predicate, evaluateWith: session)
    /// ```
    /// - Parameters:
    ///   - predicate: The predicate to be waited upon.
    ///   - evaluationObject: The object on which the predicate is evaluated.
    ///   - timeout: Maximum amount of time to wait.
    /// - Throws: `TestingError.timeout` if the timeout is exceeded.
    static func wait<EvalType>(
        for predicate: Predicate<EvalType>,
        evaluateWith evaluationObject: EvalType,
        timeout: TimeInterval = 1.0
    ) async throws {
        let startTime = Date()
        var didSucceed = false

        // a busy wait is used here (though it does yield at each iteration) because
        // using an `expectation` can block testing tasks that run on the main thread.
        while startTime.timeIntervalSinceNow > -timeout, !didSucceed {
            // wait for a few milliseconds to avoid a completely busy wait.
            try? await Task.sleep(for: .milliseconds(5))
            didSucceed = try predicate.evaluate(evaluationObject)
        }

        if !didSucceed {
            let errorDescription = "Timeout (\(timeout)s) while waiting for predicate./n  evaluationObject: \(evaluationObject)"
            throw TestingError.timeout(message: errorDescription)
        }
    }

    /// Wait up to `timeout` seconds for the given publisher to produce a result that,
    /// when `keyPath` is applied, matches `matchingValue`.
    ///
    /// This method is intended to service `@Published` properties on a view model since
    /// published properties do not work with `Predicate<>`.
    ///
    /// Usage:
    /// ```swift
    /// try await TestUtility.wait(
    ///     on: viewModel.$state,
    ///     keyPath: \.randomJoke,
    ///     matchingValue: joke
    /// )
    /// ```
    /// - Parameters:
    ///   - publisher: The publisher that is expected to produce a result that, when
    ///   `keyPath` is applied, matches `matchingValue`. This is typically a view
    ///   model's state. i.e. `viewModel.$state`.
    ///   - keyPath: The key path that is applied to a result from `publisher`.
    ///   - expectedValue: The value that is expected to match a published result.
    ///   - timeout: The amount of time to wait for the expected value.
    /// - Throws: `TestingError.timeout` if the timeout is exceeded.
    static func wait<PublisherType, ValueType: Equatable>(
        on publisher: Published<PublisherType>.Publisher,
        keyPath: KeyPath<PublisherType, ValueType>,
        expectedValue: ValueType?,
        timeout: TimeInterval = 1.0
    ) async throws {
        let startTime = Date()
        var didSucceed = false
        let cancellable = publisher
            .sink { value in
                print("Value captured: \(value)")
                // note: it is important that once `didSucceed` is set
                //       to `true`, we don't want it being set back to
                //       `false` if another value is produced.
                if value[keyPath: keyPath] == expectedValue {
                    didSucceed = true
                }
            }

        // a busy wait is used here (though it does yield at each iteration) because
        // using an `expectation` can block testing tasks that run on the main thread.
        while startTime.timeIntervalSinceNow > -timeout, !didSucceed {
            // wait for a few milliseconds to avoid a completely busy wait.
            try? await Task.sleep(for: .milliseconds(5))
        }

        cancellable.cancel()
        if !didSucceed {
            let errorDescription = "Timeout (\(timeout)s) while waiting for predicate."
            throw TestingError.timeout(message: errorDescription)
        }
    }

    /// Wait up to `timeout` seconds for the given publisher to produce a result that,
    /// when `keyPath` is applied, the value is not `nil`.
    ///
    /// This method is intended to service `@Published` properties on a view model since
    /// published properties do not work with `Predicate<>`.
    ///
    /// Usage:
    /// ```swift
    /// try await TestUtility.waitNotNil(
    ///     on: viewModel.$state,
    ///     keyPath: \.randomJoke
    /// )
    /// ```
    /// - Parameters:
    ///   - publisher: The publisher that is expected to produce a result that, when
    ///   `keyPath` is applied, is not `nil`. This is typically a view model's state.
    ///   i.e. `viewModel.$state`.
    ///   - keyPath: The key paths that is applied to a result from `publisher`.
    ///   - timeout: The amount of time to wait for the expected value.
    /// - Throws: `TestingError.timeout` if the timeout is exceeded.
    static func waitNotNil<PublisherType, ValueType>(
        on publisher: Published<PublisherType>.Publisher,
        keyPath: KeyPath<PublisherType, ValueType?>,
        timeout: TimeInterval = 1.0
    ) async throws {
        let startTime = Date()
        var didSucceed = false
        let cancellable = publisher
            .sink { value in
                print("Value captured: \(value)")
                // note: it is important that once `didSucceed` is set
                //       to `true`, we don't want it being set back to
                //       `false` if another value is produced.
                if value[keyPath: keyPath] != nil {
                    didSucceed = true
                }
            }

        // a busy wait is used here (though it does yield at each iteration) because
        // using an `expectation` can block testing tasks that run on the main thread.
        while startTime.timeIntervalSinceNow > -timeout, !didSucceed {
            // wait for a few milliseconds to avoid a completely busy wait.
            try? await Task.sleep(for: .milliseconds(5))
        }

        cancellable.cancel()
        if !didSucceed {
            let errorDescription = "Timeout (\(timeout)s) while waiting for predicate."
            throw TestingError.timeout(message: errorDescription)
        }
    }
}

/// Error thrown by a Test Utility function.
enum TestingError: Error {
    case timeout(message: String)

    var localizedDescription: String {
        switch self {
        case .timeout(message: let message):
            "timeout: \(message)"
        }
    }
}
