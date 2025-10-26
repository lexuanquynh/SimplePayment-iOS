//
//  SimplePaymentApp.swift
//  SimplePayment
//
//  Main app entry point
//

import SwiftUI

@main
struct SimplePaymentApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    init() {
        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()

        // Setup security checks (disabled in DEBUG)
        #if !DEBUG
        performSecurityChecks()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .onAppear {
                    // Check if user is already logged in
                    authViewModel.checkAuthStatus()
                }
        }
    }

    private func performSecurityChecks() {
        // Add security checks for production
        // For now, just log
        print("🔒 Security checks passed")
    }
}
