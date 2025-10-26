//
//  SecureStorage.swift
//  SimplePayment
//
//  Secure storage using Keychain
//

import Foundation
import Security

class SecureStorage {
    static let shared = SecureStorage()

    private init() {}

    // MARK: - Save

    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }

    // MARK: - Get

    func get(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unableToRetrieve
        }

        return result as? Data
    }

    // MARK: - Delete

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }

    // MARK: - Clear All

    func clearAll() {
        let secClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        for secClass in secClasses {
            let query: [String: Any] = [kSecClass as String: secClass]
            SecItemDelete(query as CFDictionary)
        }
    }
}

// MARK: - Convenience Methods

extension SecureStorage {
    func saveString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unableToSave
        }
        try save(data, for: key)
    }

    func getString(_ key: String) throws -> String? {
        guard let data = try get(key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func saveCodable<T: Codable>(_ object: T, for key: String) throws {
        let data = try JSONEncoder().encode(object)
        try save(data, for: key)
    }

    func getCodable<T: Codable>(_ key: String, as type: T.Type) throws -> T? {
        guard let data = try get(key) else {
            return nil
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
}
