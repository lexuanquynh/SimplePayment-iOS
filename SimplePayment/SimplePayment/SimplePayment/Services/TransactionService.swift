//
//  TransactionService.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Handles transaction operations with offline support
//

import Foundation
import Combine

class TransactionService: ObservableObject {
    static let shared = TransactionService()

    @Published var pendingTransactions: [Transaction] = []
    @Published var isSyncing = false

    private let apiClient = APIClient.shared
    private let networkMonitor = NetworkMonitor.shared

    private init() {
        // Load pending transactions
        loadPendingTransactions()

        // Listen for network connection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkDidConnect),
            name: .networkConnected,
            object: nil
        )
    }

    // MARK: - Send Money

    func sendMoney(
        amount: Decimal,
        to recipientId: String,
        recipientName: String,
        from senderId: String,
        senderName: String,
        note: String? = nil
    ) async throws -> Transaction {
        // Check security restrictions
        guard SecurityManager.shared.isFeatureAllowed(.sendMoney) else {
            throw TransactionError.featureRestricted(
                reason: "Sending money is restricted on jailbroken devices for security reasons."
            )
        }

        // Create transaction locally first
        let transaction = Transaction(
            amount: amount,
            recipientId: recipientId,
            recipientName: recipientName,
            senderId: senderId,
            senderName: senderName,
            type: .sent,
            status: .pending,
            note: note
        )

        // Save locally
        await savePendingTransaction(transaction)

        // Try to send if online
        if networkMonitor.isConnected {
            await syncTransaction(transaction)
        }

        return transaction
    }

    // MARK: - Fetch Transactions

    func fetchTransactions() async throws -> [Transaction] {
        // Try cache first
        if let cached: [Transaction] = await CacheManager.shared.get(
            "transactions",
            as: [Transaction].self
        ) {
            return cached
        }

        // Fetch from API
        let transactions: [Transaction] = try await apiClient.request(.transactions)

        // Cache for 30 minutes
        await CacheManager.shared.set(transactions, for: "transactions", ttl: 1800)

        return transactions
    }

    // MARK: - Offline Queue Management

    private func savePendingTransaction(_ transaction: Transaction) async {
        await MainActor.run {
            pendingTransactions.append(transaction)
        }

        // Save to persistent storage
        try? SecureStorage.shared.saveCodable(
            pendingTransactions,
            for: "pending_transactions"
        )
    }

    private func loadPendingTransactions() {
        if let pending: [Transaction] = try? SecureStorage.shared.getCodable(
            "pending_transactions",
            as: [Transaction].self
        ) {
            pendingTransactions = pending
        }
    }

    private func syncTransaction(_ transaction: Transaction) async {
        var updatedTransaction = transaction
        updatedTransaction.status = .sending
        updateTransactionStatus(updatedTransaction)

        do {
            let request = SendMoneyRequest(
                recipientId: transaction.recipientId,
                amount: transaction.amount,
                currency: transaction.currency,
                note: transaction.note,
                idempotencyKey: transaction.id
            )

            let response: TransactionResponse = try await apiClient.request(
                .sendMoney,
                method: .post,
                body: request
            )

            var completedTransaction = response.transaction
            completedTransaction.status = .completed
            completedTransaction.syncedToServer = true

            updateTransactionStatus(completedTransaction)
            removePendingTransaction(transaction)

        } catch {
            var failedTransaction = transaction
            failedTransaction.status = .failed
            updateTransactionStatus(failedTransaction)
        }
    }

    @objc private func networkDidConnect() {
        Task {
            await syncAllPendingTransactions()
        }
    }

    func syncAllPendingTransactions() async {
        guard !pendingTransactions.isEmpty else { return }

        await MainActor.run {
            isSyncing = true
        }

        for transaction in pendingTransactions {
            await syncTransaction(transaction)
        }

        await MainActor.run {
            isSyncing = false
        }
    }

    private func updateTransactionStatus(_ transaction: Transaction) {
        if let index = pendingTransactions.firstIndex(where: { $0.id == transaction.id }) {
            pendingTransactions[index] = transaction
            savePendingTransactions()
        }
    }

    private func removePendingTransaction(_ transaction: Transaction) {
        pendingTransactions.removeAll { $0.id == transaction.id }
        savePendingTransactions()
    }

    private func savePendingTransactions() {
        try? SecureStorage.shared.saveCodable(
            pendingTransactions,
            for: "pending_transactions"
        )
    }
}
