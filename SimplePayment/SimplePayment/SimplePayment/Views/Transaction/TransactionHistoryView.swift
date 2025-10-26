//
//  TransactionHistoryView.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Full transaction history
//

import SwiftUI

struct TransactionHistoryView: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Transaction History")
            .searchable(text: $searchText, prompt: "Search transactions")
            .refreshable {
                await loadTransactions()
            }
            .task {
                await loadTransactions()
            }
            .overlay {
                if isLoading && transactions.isEmpty {
                    ProgressView()
                } else if transactions.isEmpty {
                    EmptyTransactionsView()
                }
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return transactions
        }

        return transactions.filter { transaction in
            transaction.recipientName.localizedCaseInsensitiveContains(searchText) ||
            transaction.senderName.localizedCaseInsensitiveContains(searchText) ||
            transaction.note?.localizedCaseInsensitiveContains(searchText) == true
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

#Preview {
    TransactionHistoryView()
}
