//
//  User.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  User model
//

import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var email: String
    var phone: String?
    var profileImageURL: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
    }
}

// MARK: - Auth Models

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable, Sendable {
    let name: String
    let email: String
    let phone: String
    let password: String
}

struct RefreshTokenRequest: Codable, Sendable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct AuthResponse: Codable, Sendable {
    let token: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case user
    }
}
