//
//  ContentView.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Root view that handles navigation between auth and main app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var securityManager: SecurityManager

    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthenticationView()
                    .transition(.opacity)
            }

            // Status banners
            VStack(spacing: 0) {
                // Security warning banner (highest priority)
                if securityManager.shouldShowWarning {
                    SecurityWarningBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Network status banner
                if !networkMonitor.isConnected {
                    NetworkStatusBanner()
                        .transition(.move(edge: .top))
                }

                Spacer()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: networkMonitor.isConnected)
        .animation(.easeInOut, value: securityManager.shouldShowWarning)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
}
