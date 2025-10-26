//
//  SimplePaymentApp.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Main app entry point
//

import SwiftUI

@main
struct SimplePaymentApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var securityManager = SecurityManager.shared

    init() {
        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()

        // Perform security checks (jailbreak detection)
        SecurityManager.shared.performSecurityChecks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .environmentObject(securityManager)
                .onAppear {
                    // Check if user is already logged in
                    authViewModel.checkAuthStatus()
                }
        }
    }
}
