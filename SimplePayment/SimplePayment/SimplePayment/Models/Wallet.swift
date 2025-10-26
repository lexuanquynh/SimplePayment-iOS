//
//  Wallet.swift
//  SimplePayment
//
//  Wallet model
//

import Foundation

struct Wallet: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    var balance: Decimal
    let currency: String
    var availableBalance: Decimal
    var frozenBalance: Decimal
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case balance
        case currency
        case availableBalance = "available_balance"
        case frozenBalance = "frozen_balance"
        case updatedAt = "updated_at"
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        balance: Decimal = 0,
        currency: String = "USD",
        availableBalance: Decimal = 0,
        frozenBalance: Decimal = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.balance = balance
        self.currency = currency
        self.availableBalance = availableBalance
        self.frozenBalance = frozenBalance
        self.updatedAt = updatedAt
    }
}

struct BalanceResponse: Codable, Sendable {
    let wallet: Wallet
}
