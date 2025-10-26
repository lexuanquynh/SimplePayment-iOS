//
//  PendingTransactionsSection.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Shows pending offline transactions
//

import SwiftUI

struct PendingTransactionsSection: View {
    let transactions: [Transaction]
    let isSyncing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pending Transactions")
                    .font(.headline)

                Spacer()

                if isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            ForEach(transactions) { transaction in
                PendingTransactionRow(transaction: transaction)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
}

struct PendingTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.recipientName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(transaction.status.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatAmount(transaction.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
    }

    private var statusIcon: String {
        switch transaction.status {
        case .pending: return "clock"
        case .sending: return "arrow.clockwise"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch transaction.status {
        case .pending: return .orange
        case .sending: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

#Preview {
    PendingTransactionsSection(
        transactions: [
            Transaction(
                amount: 50.00,
                recipientId: "1",
                recipientName: "Code toan bug",
                senderId: "2",
                senderName: "Me",
                type: .sent,
                status: .pending
            )
        ],
        isSyncing: false
    )
    .padding()
}
