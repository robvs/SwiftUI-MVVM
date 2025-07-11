//
//  AppUrlSession.swift
//  SwiftUI-MVVM
//
//  Created by Rob Vander Sloot on 5/25/25.
//

import Foundation
import OSLog

/// Interface for an object that handles URL session requests.
protocol AppUrlSessionHandling: Sendable {
    /// Perform a GET request on the given URL. If the request fails or the data
    /// can not be parsed, an error is thrown.
    /// - Parameter url: The URL on which to make the request.
    /// - Returns: An object containing the decoded response data.
    /// - Throws: `AppUrlSession.RequestError`
    func get<Model: Decodable>(from url: URL) async throws -> Model
}

/// This is a wrapper around URLSession that provides a simplified API specific to this app.
final class AppUrlSession: AppUrlSessionHandling {
    /// The singleton instance of the app's URL Session.
    static let shared = AppUrlSession()

    private let session: URLSession

    private init() {
        session = URLSession.shared
    }

    func get<Model: Decodable>(from url: URL) async throws -> Model {
        let urlRequest = URLRequest(url: url)
        let response: (data: Data, urlResponse: URLResponse)

        do {
            Logger.api.trace("GET \(url.absoluteString)")
            response = try await session.data(for: urlRequest, delegate: nil)
        }
        catch {
            Logger.api.error("session.data() threw an error: \(error.localizedDescription)")
            throw RequestError.unexpectedError(error)
        }

        return try parse(response.data, urlResponse: response.urlResponse)
    }
}


// MARK: - Private Helpers

private extension AppUrlSession {
    func parse<Model: Decodable>(_ data: Data, urlResponse: URLResponse) throws -> Model {
        // ensure that the response is `HTTPURLResponse`; this is mostly a sanity check.
        let requestUrlString = urlResponse.url?.absoluteString ?? "nil URL"
        guard let urlResponse = urlResponse as? HTTPURLResponse else {
            Logger.api.critical("The received URLResponse as not an HTTPURLResponse: \(urlResponse) for \(requestUrlString)")
            throw RequestError.unexpected("HTTPURLResponse type was expected")
        }

        // ensure a success status code.
        guard 200...299 ~= urlResponse.statusCode else {
            Logger.api.error("Failure response code: \(urlResponse.statusCode) for \(requestUrlString)")
            throw RequestError.serverResponse(code: urlResponse.statusCode)
        }

        // ensure that some data was returned.
        guard !data.isEmpty else {
            Logger.api.error("API request succeeded but the response data is empty for \(requestUrlString)")
            throw RequestError.unexpected("API request succeeded but the response data is empty")
        }

        // the response data is expected to be JSON. parse it into a model object.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(Model.self, from: data)
        }
        catch let decodingError as DecodingError {
            let dataString = String(data: data, encoding: .utf8) ?? ""
            Logger.api.error("Data could not be decoded: \(dataString)")
            throw RequestError.unexpectedError(decodingError)
        }
        catch {
            Logger.api.error("Unexpected error type: \(error)")
            throw RequestError.unexpectedError(error)
        }
    }
}

// MARK: - AppError extension

extension AppUrlSession {
    /// Errors that may be thrown by `AppUrlSession`.
    enum RequestError: LocalizedError, Equatable {
        case unexpected(_ description: String)
        case unexpectedError(_ error: any Error)
        case serverResponse(code: Int)

        var code: Int {
            switch self {
            case .unexpected: -1
            case .unexpectedError: -2
            case .serverResponse(let code): code
            }
        }

        var localizedDescription: String {
            switch self {
            case .unexpected(let description): description
            case .unexpectedError(let error): error.localizedDescription
            case .serverResponse(let code): "A data request error occurred. (code: \(code))"
            }
        }

        /// Equatable conformance.
        static func == (lhs: AppUrlSession.RequestError,
                        rhs: AppUrlSession.RequestError) -> Bool {
            switch (lhs, rhs) {
            case let (.unexpected(lhsDescription), .unexpected(rhsDescription)):
                return lhsDescription == rhsDescription

            case let (.unexpectedError(lhsError), .unexpectedError(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription

            case let (.serverResponse(code: lhsCode), .serverResponse(rhsCode)):
                return lhsCode == rhsCode

            default:
                return false
            }
        }
    }
}
