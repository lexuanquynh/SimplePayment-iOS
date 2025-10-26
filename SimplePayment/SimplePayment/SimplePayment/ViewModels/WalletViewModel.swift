//
//  WalletViewModel.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Handles wallet operations
//

import Foundation
import Combine

class WalletViewModel: ObservableObject {
    @Published var wallet: Wallet?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    @MainActor
    func loadBalance() async {
        // Try cache first (instant display)
        if let cached: Wallet = await CacheManager.shared.get("wallet", as: Wallet.self) {
            self.wallet = cached
        }

        // Fetch fresh data in background
        await refreshBalance()
    }

    @MainActor
    func refreshBalance() async {
        isRefreshing = true
        errorMessage = nil

        do {
            let response: BalanceResponse = try await apiClient.request(.balance)

            // Update wallet
            self.wallet = response.wallet

            // Cache for 5 minutes
            await CacheManager.shared.set(response.wallet, for: "wallet", ttl: 300)

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isRefreshing = false
    }

    var formattedBalance: String {
        guard let wallet = wallet else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = wallet.currency
        return formatter.string(from: wallet.balance as NSDecimalNumber) ?? "$0.00"
    }
}
