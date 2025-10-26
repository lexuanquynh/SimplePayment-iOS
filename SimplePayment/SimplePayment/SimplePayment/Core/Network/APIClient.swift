//
//  APIClient.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Network client with retry logic and low bandwidth optimization
//

import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://api.simplepayment.com/v1" // Replace with your API
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        // Enable compression
        config.httpAdditionalHeaders = [
            "Accept-Encoding": "gzip, deflate"
        ]

        self.session = URLSession(configuration: config)
    }

    // MARK: - Request Methods

    func request<T: Decodable>(
        _ endpoint: Endpoint,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        retries: Int = 3
    ) async throws -> T {
        var request = try createRequest(endpoint, method: method, body: body)

        // Add auth token if available
        if let token = try? SecureStorage.shared.getString("auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return try await performRequest(request, retries: retries)
    }

    // MARK: - Private Methods

    private func createRequest(
        _ endpoint: Endpoint,
        method: HTTPMethod,
        body: Encodable?
    ) throws -> URLRequest {
        let url = URL(string: baseURL + endpoint.path)!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")

        // Add body
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        retries: Int
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<retries {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                // Handle different status codes
                switch httpResponse.statusCode {
                case 200...299:
                    return try JSONDecoder().decode(T.self, from: data)
                case 401:
                    throw APIError.unauthorized
                case 400...499:
                    throw APIError.clientError(httpResponse.statusCode)
                case 500...599:
                    throw APIError.serverError(httpResponse.statusCode)
                default:
                    throw APIError.unknown
                }

            } catch {
                lastError = error

                // Don't retry on client errors
                if case APIError.clientError = error {
                    throw error
                }
                if case APIError.unauthorized = error {
                    throw error
                }

                // Exponential backoff before retry
                if attempt < retries - 1 {
                    let delay = pow(2.0, Double(attempt)) * 0.5
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? APIError.unknown
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum Endpoint {
    case login
    case register
    case refreshToken
    case profile
    case balance
    case transactions
    case sendMoney
    case transaction(id: String)

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .refreshToken: return "/auth/refresh"
        case .profile: return "/user/profile"
        case .balance: return "/wallet/balance"
        case .transactions: return "/transactions"
        case .sendMoney: return "/transactions/send"
        case .transaction(let id): return "/transactions/\(id)"
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case clientError(Int)
    case serverError(Int)
    case decodingError
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Please log in again"
        case .clientError(let code):
            return "Request failed with code \(code)"
        case .serverError(let code):
            return "Server error \(code). Please try again."
        case .decodingError:
            return "Failed to process response"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
