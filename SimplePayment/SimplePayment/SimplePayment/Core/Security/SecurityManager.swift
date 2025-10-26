//
//  SecurityManager.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Manages app security state and restrictions
//

import Foundation
import Combine

class SecurityManager: ObservableObject {

    static let shared = SecurityManager()

    @Published var isJailbroken = false
    @Published var securityAction: JailbreakDetector.JailbreakAction = .log
    @Published var shouldShowWarning = false

    private init() {}

    /// Performs all security checks on app launch
    func performSecurityChecks() {
        #if targetEnvironment(simulator)
        // Skip checks on simulator
        print("🔒 Security checks skipped (simulator)")
        return
        #else

        // Check for jailbreak
        let jailbreakDetected = JailbreakDetector.shared.isJailbroken()

        if jailbreakDetected {
            self.isJailbroken = true

            // Choose action based on build configuration
            #if DEBUG
            self.securityAction = .log
            #else
            self.securityAction = .restrict // Production: restrict sensitive features
            #endif

            // Execute the action
            let shouldContinue = JailbreakDetector.shared.handleJailbreak(action: securityAction)

            // Show warning for warn and restrict modes
            if securityAction == .warn || securityAction == .restrict {
                self.shouldShowWarning = true
            }

            // Exit app if block mode
            if !shouldContinue {
                print("🚫 App blocked due to jailbreak detection")
                // In production, you might want to show a final alert before exiting
                exit(0)
            }

            // Save jailbreak status for feature restrictions
            UserDefaults.standard.set(true, forKey: "isJailbroken")
        } else {
            print("✅ Security checks passed")
            UserDefaults.standard.set(false, forKey: "isJailbroken")
        }

        #endif
    }

    /// Check if a sensitive feature should be restricted
    /// - Parameter feature: The feature to check
    /// - Returns: true if feature is allowed, false if restricted
    func isFeatureAllowed(_ feature: SensitiveFeature) -> Bool {
        // If not jailbroken, all features allowed
        guard isJailbroken else { return true }

        // If jailbroken, check action mode
        switch securityAction {
        case .block:
            return false // All features blocked (app should have exited)

        case .restrict:
            // Restrict sensitive financial operations
            switch feature {
            case .sendMoney, .withdrawFunds, .addBankAccount:
                return false
            case .viewBalance, .viewTransactions, .updateProfile:
                return true
            }

        case .warn, .log:
            return true // Allow all features, just warn/log
        }
    }

    /// Dismiss the security warning banner
    func dismissWarning() {
        shouldShowWarning = false
    }
}

// MARK: - Sensitive Features

extension SecurityManager {
    enum SensitiveFeature {
        case sendMoney
        case withdrawFunds
        case addBankAccount
        case viewBalance
        case viewTransactions
        case updateProfile
    }
}
