//
//  CacheManager.swift
//  SimplePayment
//
//  Two-layer caching system for optimal performance
//

import Foundation

@globalActor actor CacheActor {
    static let shared = CacheActor()
}

class CacheManager {
    static let shared = CacheManager()

    // Layer 1: In-memory cache (fast)
    private var memoryCache: [String: Any] = [:]
    private var expirations: [String: Date] = [:]

    // Layer 2: Disk cache (persistent)
    private let cacheDirectory: URL

    private init() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("SimplePaymentCache")

        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Set

    func set<T: Codable>(_ value: T, for key: String, ttl: TimeInterval) async {
        let expiresAt = Date().addingTimeInterval(ttl)

        // Save to memory
        memoryCache[key] = value
        expirations[key] = expiresAt

        // Save to disk in background
        Task.detached(priority: .utility) { [cacheDirectory] in
            await Self.saveToDisk(value, expiresAt: expiresAt, for: key, at: cacheDirectory)
        }
    }

    // MARK: - Get

    func get<T: Codable>(_ key: String, as type: T.Type) async -> T? {
        // Try memory first
        if let value = memoryCache[key] as? T,
           let expiresAt = expirations[key],
           Date() < expiresAt {
            return value
        } else {
            // Expired or not found - remove from memory
            memoryCache.removeValue(forKey: key)
            expirations.removeValue(forKey: key)
        }

        // Try disk
        if let (value, expiresAt): (T, Date) = await Self.loadFromDisk(key, as: type, from: cacheDirectory) {
            if Date() < expiresAt {
                // Still valid - promote to memory cache
                memoryCache[key] = value
                expirations[key] = expiresAt
                return value
            } else {
                // Expired - delete
                Task.detached(priority: .utility) { [cacheDirectory] in
                    await Self.deleteFromDisk(key, from: cacheDirectory)
                }
            }
        }

        return nil
    }

    // MARK: - Delete

    func delete(_ key: String) async {
        memoryCache.removeValue(forKey: key)
        expirations.removeValue(forKey: key)

        Task.detached(priority: .utility) { [cacheDirectory] in
            await Self.deleteFromDisk(key, from: cacheDirectory)
        }
    }

    func clearAll() async {
        memoryCache.removeAll()
        expirations.removeAll()

        Task.detached(priority: .utility) { [cacheDirectory] in
            try? FileManager.default.removeItem(at: cacheDirectory)
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Disk Operations (Static to avoid actor issues)

    private static func saveToDisk<T: Codable>(_ value: T, expiresAt: Date, for key: String, at cacheDirectory: URL) async {
        let sanitizedKey = Self.sanitize(key)
        let url = cacheDirectory.appendingPathComponent(sanitizedKey)

        do {
            let entry = DiskCacheEntry(value: value, expiresAt: expiresAt)
            let data = try JSONEncoder().encode(entry)
            try data.write(to: url)
        } catch {
            print("Failed to save to disk: \(error)")
        }
    }

    private static func loadFromDisk<T: Codable>(_ key: String, as type: T.Type, from cacheDirectory: URL) async -> (T, Date)? {
        let sanitizedKey = Self.sanitize(key)
        let url = cacheDirectory.appendingPathComponent(sanitizedKey)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let entry = try JSONDecoder().decode(DiskCacheEntry<T>.self, from: data)
            return (entry.value, entry.expiresAt)
        } catch {
            print("Failed to load from disk: \(error)")
            return nil
        }
    }

    private static func deleteFromDisk(_ key: String, from cacheDirectory: URL) async {
        let sanitizedKey = Self.sanitize(key)
        let url = cacheDirectory.appendingPathComponent(sanitizedKey)
        try? FileManager.default.removeItem(at: url)
    }

    // Helper to sanitize keys for file names
    private static func sanitize(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}

// MARK: - Disk Cache Entry

struct DiskCacheEntry<T: Codable>: Codable {
    let value: T
    let expiresAt: Date
}
