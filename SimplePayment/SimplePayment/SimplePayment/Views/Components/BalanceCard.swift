//
//  BalanceCard.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Balance display card
//

import SwiftUI

struct BalanceCard: View {
    @ObservedObject var viewModel: WalletViewModel
    @State private var isBalanceVisible = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Button {
                    withAnimation {
                        isBalanceVisible.toggle()
                    }
                } label: {
                    Image(systemName: isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(.white)
                }
            }

            HStack(alignment: .firstTextBaseline) {
                if viewModel.isRefreshing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isBalanceVisible ? viewModel.formattedBalance : "••••••")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            if let wallet = viewModel.wallet {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Available: \(formatAmount(wallet.availableBalance))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

#Preview {
    BalanceCard(viewModel: WalletViewModel())
        .padding()
}
