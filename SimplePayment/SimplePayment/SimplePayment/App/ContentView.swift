//
//  ContentView.swift
//  SimplePayment
//
//  Root view that handles navigation between auth and main app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthenticationView()
                    .transition(.opacity)
            }

            // Network status banner
            VStack {
                if !networkMonitor.isConnected {
                    NetworkStatusBanner()
                        .transition(.move(edge: .top))
                }
                Spacer()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
}
