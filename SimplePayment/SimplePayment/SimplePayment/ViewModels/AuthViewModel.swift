//
//  AuthViewModel.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Handles authentication logic
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Demo Mode (set to true for testing without backend)
    private let useMockMode = true // Set to false when you have a real backend

    private let apiClient = APIClient.shared

    @MainActor
    func checkAuthStatus() {
        // Check if token exists
        if let token = try? SecureStorage.shared.getString("auth_token"),
           !token.isEmpty {
            // Try to load user from cache
            if let user: User = try? SecureStorage.shared.getCodable("current_user", as: User.self) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }

    @MainActor
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        if useMockMode {
            // Mock authentication - accepts any credentials
            mockLogin(email: email, password: password)
        } else {
            // Real API call
            do {
                let request = LoginRequest(email: email, password: password)
                let response: AuthResponse = try await apiClient.request(
                    .login,
                    method: .post,
                    body: request
                )

                // Save tokens
                try SecureStorage.shared.saveString(response.token, for: "auth_token")
                try SecureStorage.shared.saveString(response.refreshToken, for: "refresh_token")
                try SecureStorage.shared.saveCodable(response.user, for: "current_user")

                // Update state
                self.currentUser = response.user
                self.isAuthenticated = true

            } catch {
                self.errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    @MainActor
    func register(name: String, email: String, phone: String, password: String) async {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        if useMockMode {
            // Mock registration
            mockRegister(name: name, email: email, phone: phone, password: password)
        } else {
            // Real API call
            do {
                let request = RegisterRequest(
                    name: name,
                    email: email,
                    phone: phone,
                    password: password
                )

                let response: AuthResponse = try await apiClient.request(
                    .register,
                    method: .post,
                    body: request
                )

                // Save tokens
                try SecureStorage.shared.saveString(response.token, for: "auth_token")
                try SecureStorage.shared.saveString(response.refreshToken, for: "refresh_token")
                try SecureStorage.shared.saveCodable(response.user, for: "current_user")

                // Update state
                self.currentUser = response.user
                self.isAuthenticated = true

            } catch {
                self.errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    @MainActor
    func refreshToken() async throws {
        if useMockMode {
            // Mock token refresh
            try await mockRefreshToken()
        } else {
            // Real API call
            guard let refreshToken = try? SecureStorage.shared.getString("refresh_token") else {
                throw AuthError.noRefreshToken
            }

            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await apiClient.request(
                .refreshToken,
                method: .post,
                body: request
            )

            // Save new tokens
            try SecureStorage.shared.saveString(response.token, for: "auth_token")
            try SecureStorage.shared.saveString(response.refreshToken, for: "refresh_token")
        }
    }

    @MainActor
    func logout() {
        // Clear all secure data
        SecureStorage.shared.clearAll()

        // Clear cache
        Task {
            await CacheManager.shared.clearAll()
        }

        // Update state
        self.currentUser = nil
        self.isAuthenticated = false
    }

    // MARK: - Mock Methods (for testing without backend)

    private func mockLogin(email: String, password: String) {
        // Create mock user
        let user = User(
            id: "demo-user-123",
            name: "Demo User",
            email: email,
            phone: "+1234567890",
            profileImageURL: nil,
            createdAt: Date()
        )

        do {
            // Save mock tokens
            try SecureStorage.shared.saveString("mock-token-12345", for: "auth_token")
            try SecureStorage.shared.saveString("mock-refresh-token", for: "refresh_token")
            try SecureStorage.shared.saveCodable(user, for: "current_user")

            // Update state
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = "Failed to save credentials"
        }
    }

    private func mockRegister(name: String, email: String, phone: String, password: String) {
        // Create mock user with provided info
        let user = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            phone: phone,
            profileImageURL: nil,
            createdAt: Date()
        )

        do {
            // Save mock tokens
            try SecureStorage.shared.saveString("mock-token-12345", for: "auth_token")
            try SecureStorage.shared.saveString("mock-refresh-token", for: "refresh_token")
            try SecureStorage.shared.saveCodable(user, for: "current_user")

            // Update state
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = "Failed to save credentials"
        }
    }

    private func mockRefreshToken() async throws {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Generate new mock tokens with timestamp
        let timestamp = Date().timeIntervalSince1970
        let newToken = "mock-token-\(Int(timestamp))"
        let newRefreshToken = "mock-refresh-token-\(Int(timestamp))"

        // Save new mock tokens
        try SecureStorage.shared.saveString(newToken, for: "auth_token")
        try SecureStorage.shared.saveString(newRefreshToken, for: "refresh_token")

        print("✅ Mock token refreshed: \(newToken)")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case noRefreshToken
    case refreshFailed

    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "No refresh token found. Please login again."
        case .refreshFailed:
            return "Failed to refresh authentication token."
        }
    }
}
