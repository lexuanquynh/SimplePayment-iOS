//
//  NetworkStatusBanner.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Network status indicator banner
//

import SwiftUI

struct NetworkStatusBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @StateObject private var transactionService = TransactionService.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                if !transactionService.pendingTransactions.isEmpty {
                    Text("\(transactionService.pendingTransactions.count) pending")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Spacer()

            if transactionService.isSyncing {
                ProgressView()
                    .tint(.white)
            }
        }
        .padding()
        .background(backgroundColor)
        .shadow(radius: 4)
    }

    private var statusText: String {
        if !networkMonitor.isConnected {
            return "Offline - Changes saved locally"
        } else if transactionService.isSyncing {
            return "Syncing..."
        } else if networkMonitor.connectionQuality == .poor {
            return "Slow connection - Using cached data"
        } else {
            return "Online"
        }
    }

    private var backgroundColor: Color {
        if !networkMonitor.isConnected {
            return .orange
        } else if networkMonitor.connectionQuality == .poor {
            return .yellow.opacity(0.8)
        } else {
            return .green
        }
    }
}

#Preview {
    NetworkStatusBanner()
        .environmentObject(NetworkMonitor.shared)
}
