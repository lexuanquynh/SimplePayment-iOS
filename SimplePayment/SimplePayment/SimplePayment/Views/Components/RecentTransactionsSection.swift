//
//  RecentTransactionsSection.swift
//  SimplePayment
//
//  Shows recent transaction history
//

import SwiftUI

struct RecentTransactionsSection: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions")
                .font(.headline)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if transactions.isEmpty {
                EmptyTransactionsView()
            } else {
                ForEach(transactions.prefix(5)) { transaction in
                    TransactionRow(transaction: transaction)
                }

                NavigationLink {
                    TransactionHistoryView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
        }
        .task {
            await loadTransactions()
        }
    }

    private func loadTransactions() async {
        isLoading = true

        do {
            transactions = try await TransactionService.shared.fetchTransactions()
        } catch {
            print("Failed to load transactions: \(error)")
        }

        isLoading = false
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(transaction.type == .sent ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: transaction.type == .sent ? "arrow.up" : "arrow.down")
                        .foregroundStyle(transaction.type == .sent ? .red : .green)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type == .sent ? transaction.recipientName : transaction.senderName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .sent ? "-" : "+")\(formatAmount(transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type == .sent ? .red : .green)

                if transaction.status != .completed {
                    Text(transaction.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No transactions yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    RecentTransactionsSection()
        .padding()
}
