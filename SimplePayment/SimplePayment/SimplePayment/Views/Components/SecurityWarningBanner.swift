//
//  SecurityWarningBanner.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Warning banner for jailbroken devices
//

import SwiftUI

struct SecurityWarningBanner: View {
    @EnvironmentObject var securityManager: SecurityManager
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main banner
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title3)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Security Warning")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(bannerMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Info button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }

                // Close button
                Button(action: {
                    withAnimation {
                        securityManager.dismissWarning()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(warningColor)

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your device appears to be jailbroken or modified.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.95))

                    if securityManager.securityAction == .restrict {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Restricted features:")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)

                            restrictedFeaturesList
                        }
                    }

                    Text("For your security, some features may be limited. Using modified devices can expose your financial data to security risks.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(warningColor.opacity(0.9))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var bannerMessage: String {
        switch securityManager.securityAction {
        case .restrict:
            return "Some features are restricted"
        case .warn:
            return "Your device security is compromised"
        case .log, .block:
            return "Security issue detected"
        }
    }

    private var warningColor: Color {
        switch securityManager.securityAction {
        case .restrict, .block:
            return Color.red.opacity(0.95)
        case .warn:
            return Color.orange.opacity(0.95)
        case .log:
            return Color.yellow.opacity(0.95)
        }
    }

    private var restrictedFeaturesList: some View {
        VStack(alignment: .leading, spacing: 4) {
            featureRow(icon: "paperplane.fill", text: "Sending money")
            featureRow(icon: "arrow.down.circle.fill", text: "Withdrawing funds")
            featureRow(icon: "creditcard.fill", text: "Adding bank accounts")
        }
        .padding(.leading, 8)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    VStack {
        SecurityWarningBanner()
            .environmentObject({
                let manager = SecurityManager.shared
                manager.isJailbroken = true
                manager.securityAction = .restrict
                manager.shouldShowWarning = true
                return manager
            }())

        Spacer()
    }
}
