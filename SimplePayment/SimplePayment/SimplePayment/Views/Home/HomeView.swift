//
//  HomeView.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Main dashboard screen
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var walletViewModel = WalletViewModel()
    @StateObject private var transactionService = TransactionService.shared

    @State private var showingSendMoney = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance card
                    BalanceCard(viewModel: walletViewModel)
                        .padding(.horizontal)

                    // Quick actions
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Send",
                            icon: "arrow.up.circle.fill",
                            color: .blue
                        ) {
                            showingSendMoney = true
                        }

                        QuickActionButton(
                            title: "Request",
                            icon: "arrow.down.circle.fill",
                            color: .green
                        ) {
                            // TODO: Implement request money
                        }

                        QuickActionButton(
                            title: "QR Code",
                            icon: "qrcode",
                            color: .purple
                        ) {
                            // TODO: Implement QR code
                        }
                    }
                    .padding(.horizontal)

                    // Pending transactions
                    if !transactionService.pendingTransactions.isEmpty {
                        PendingTransactionsSection(
                            transactions: transactionService.pendingTransactions,
                            isSyncing: transactionService.isSyncing
                        )
                        .padding(.horizontal)
                    }

                    // Recent transactions
                    RecentTransactionsSection()
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Hello, \(authViewModel.currentUser?.name.components(separatedBy: " ").first ?? "User")!")
            .refreshable {
                await walletViewModel.refreshBalance()
            }
            .task {
                await walletViewModel.loadBalance()
            }
            .sheet(isPresented: $showingSendMoney) {
                SendMoneyView()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
