//
//  SendMoneyView.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Send money screen
//

import SwiftUI

struct SendMoneyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var walletViewModel = WalletViewModel()

    @State private var recipientId = ""
    @State private var recipientName = ""
    @State private var amount = ""
    @State private var note = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Recipient") {
                    TextField("Recipient ID or Email", text: $recipientId)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Recipient Name", text: $recipientName)
                        .textContentType(.name)
                }

                Section("Amount") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    if let wallet = walletViewModel.wallet {
                        HStack {
                            Text("Available:")
                            Spacer()
                            Text(formatAmount(wallet.availableBalance))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }

                Section("Note (Optional)") {
                    TextField("Add a note", text: $note)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        sendMoney()
                    } label: {
                        if isProcessing {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Send Money")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isProcessing)
                }
            }
            .navigationTitle("Send Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await walletViewModel.loadBalance()
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your payment has been \(NetworkMonitor.shared.isConnected ? "sent" : "queued and will be sent when you're back online").")
            }
        }
    }

    private var isValid: Bool {
        guard !recipientId.isEmpty,
              !recipientName.isEmpty,
              !amount.isEmpty,
              let amountDecimal = Decimal(string: amount),
              amountDecimal > 0 else {
            return false
        }

        if let wallet = walletViewModel.wallet {
            return amountDecimal <= wallet.availableBalance
        }

        return true
    }

    private func sendMoney() {
        guard let amountDecimal = Decimal(string: amount),
              let currentUser = authViewModel.currentUser else {
            return
        }

        isProcessing = true
        errorMessage = nil

        Task {
            do {
                _ = try await TransactionService.shared.sendMoney(
                    amount: amountDecimal,
                    to: recipientId,
                    recipientName: recipientName,
                    from: currentUser.id,
                    senderName: currentUser.name,
                    note: note.isEmpty ? nil : note
                )

                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }

            isProcessing = false
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
    SendMoneyView()
        .environmentObject(AuthViewModel())
}
