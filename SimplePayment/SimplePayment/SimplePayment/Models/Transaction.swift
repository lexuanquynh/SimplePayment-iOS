//
//  Transaction.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Transaction model with offline support
//

import Foundation

struct Transaction: Codable, Identifiable, Sendable {
    let id: String
    let amount: Decimal
    let currency: String
    let recipientId: String
    let recipientName: String
    let senderId: String
    let senderName: String
    let type: TransactionType
    var status: TransactionStatus
    let note: String?
    let createdAt: Date
    var syncedToServer: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case currency
        case recipientId = "recipient_id"
        case recipientName = "recipient_name"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case type
        case status
        case note
        case createdAt = "created_at"
        case syncedToServer = "synced_to_server"
    }

    init(
        id: String = UUID().uuidString,
        amount: Decimal,
        currency: String = "USD",
        recipientId: String,
        recipientName: String,
        senderId: String,
        senderName: String,
        type: TransactionType,
        status: TransactionStatus = .pending,
        note: String? = nil,
        createdAt: Date = Date(),
        syncedToServer: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.senderId = senderId
        self.senderName = senderName
        self.type = type
        self.status = status
        self.note = note
        self.createdAt = createdAt
        self.syncedToServer = syncedToServer
    }
}

enum TransactionType: String, Codable, Sendable {
    case sent
    case received

    var displayName: String {
        switch self {
        case .sent: return "Sent"
        case .received: return "Received"
        }
    }
}

enum TransactionStatus: String, Codable, Sendable {
    case pending    // Created locally, not sent yet
    case sending    // Being sent to server
    case completed  // Confirmed by server
    case failed     // Server rejected

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .sending: return "Sending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Request/Response Models

struct SendMoneyRequest: Codable, Sendable {
    let recipientId: String
    let amount: Decimal
    let currency: String
    let note: String?
    let idempotencyKey: String

    enum CodingKeys: String, CodingKey {
        case recipientId = "recipient_id"
        case amount
        case currency
        case note
        case idempotencyKey = "idempotency_key"
    }
}

struct TransactionResponse: Codable, Sendable {
    let transaction: Transaction
    let newBalance: Decimal

    enum CodingKeys: String, CodingKey {
        case transaction
        case newBalance = "new_balance"
    }
}
