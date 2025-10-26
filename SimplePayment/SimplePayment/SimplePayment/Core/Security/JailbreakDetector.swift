//
//  JailbreakDetector.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Detects jailbroken/rooted devices for security
//

import UIKit

class JailbreakDetector {

    static let shared = JailbreakDetector()

    private init() {}

    // MARK: - Main Detection Method

    /// Checks if device is jailbroken using multiple detection methods
    /// - Returns: true if jailbreak is detected, false otherwise
    func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        // Don't check on simulator
        return false
        #else

        return checkSuspiciousFiles() ||
               checkSuspiciousApps() ||
               checkSystemDirectoryWritable() ||
               checkCydiaURLScheme() ||
               checkFork() ||
               checkSymbolicLinks() ||
               checkDyldEnvironmentVariables() ||
               checkSuspiciousPaths()
        #endif
    }

    // MARK: - Detection Methods

    /// Method 1: Check for common jailbreak files and tools
    private func checkSuspiciousFiles() -> Bool {
        let jailbreakPaths = [
            // Cydia and package managers
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia",
            "/etc/apt",

            // Jailbreak tools
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Applications/Snoop-itConfig.app",

            // Mobile Substrate
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/Library/MobileSubstrate/DynamicLibraries/",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",

            // SSH and system tools
            "/usr/sbin/sshd",
            "/usr/bin/sshd",
            "/usr/libexec/ssh-keysign",
            "/usr/libexec/sftp-server",
            "/bin/bash",
            "/bin/sh",

            // Common jailbreak directories
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",

            // Other tools
            "/usr/libexec/cydia",
            "/usr/bin/ssh"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("🚨 Jailbreak detected: File exists at \(path)")
                return true
            }

            // Try to open the file
            if let file = fopen(path, "r") {
                fclose(file)
                print("🚨 Jailbreak detected: Can open file at \(path)")
                return true
            }
        }

        return false
    }

    /// Method 2: Check for jailbreak apps using URL schemes
    private func checkSuspiciousApps() -> Bool {
        let schemes = [
            "cydia://",
            "undecimus://",
            "sileo://",
            "zbra://",
            "filza://",
            "activator://"
        ]

        for scheme in schemes {
            if let url = URL(string: scheme) {
                if UIApplication.shared.canOpenURL(url) {
                    print("🚨 Jailbreak detected: Can open URL scheme \(scheme)")
                    return true
                }
            }
        }

        return false
    }

    /// Method 3: Check if we can write to system directories
    private func checkSystemDirectoryWritable() -> Bool {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString).txt"

        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            // If we got here, we were able to write (jailbroken)
            try? FileManager.default.removeItem(atPath: testPath)
            print("🚨 Jailbreak detected: Can write to system directory")
            return true
        } catch {
            // Good - we can't write to system directories
            return false
        }
    }

    /// Method 4: Check Cydia URL scheme
    private func checkCydiaURLScheme() -> Bool {
        if let url = URL(string: "cydia://package/com.example.package") {
            if UIApplication.shared.canOpenURL(url) {
                print("🚨 Jailbreak detected: Cydia URL scheme available")
                return true
            }
        }
        return false
    }

    /// Method 5: Check if fork() is available (should fail on non-jailbroken devices)
    private func checkFork() -> Bool {
        // Note: fork() is restricted on iOS and will cause sandbox violations
        // On jailbroken devices, sandbox restrictions are bypassed
        // We use dlsym to check if fork is available without directly calling it

        let handle = dlopen(nil, RTLD_NOW)
        let forkPtr = dlsym(handle, "fork")
        dlclose(handle)

        if forkPtr != nil {
            // fork symbol is available - suspicious on iOS
            print("🚨 Jailbreak detected: fork() symbol accessible")
            return true
        }

        return false
    }

    /// Method 6: Check for symbolic links in system directories
    private func checkSymbolicLinks() -> Bool {
        let paths = [
            "/Applications",
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/arm-apple-darwin9",
            "/usr/include",
            "/usr/libexec",
            "/usr/share"
        ]

        for path in paths {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                if let fileType = attributes[.type] as? FileAttributeType {
                    if fileType == .typeSymbolicLink {
                        print("🚨 Jailbreak detected: Symbolic link at \(path)")
                        return true
                    }
                }
            } catch {
                // Can't check this path, continue
                continue
            }
        }

        return false
    }

    /// Method 7: Check for suspicious environment variables
    private func checkDyldEnvironmentVariables() -> Bool {
        let suspiciousVars = [
            "DYLD_INSERT_LIBRARIES",
            "_MSSafeMode",
            "_SafeMode"
        ]

        for variable in suspiciousVars {
            if let value = getenv(variable) {
                let stringValue = String(cString: value)
                if !stringValue.isEmpty {
                    print("🚨 Jailbreak detected: Environment variable \(variable) = \(stringValue)")
                    return true
                }
            }
        }

        return false
    }

    /// Method 8: Check for suspicious system paths
    private func checkSuspiciousPaths() -> Bool {
        let paths = [
            "/bin/sh",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                // Additional check: try to read
                if let _ = try? String(contentsOfFile: path) {
                    print("🚨 Jailbreak detected: Can read system file at \(path)")
                    return true
                }
            }
        }

        return false
    }
}

// MARK: - Jailbreak Actions

extension JailbreakDetector {

    /// Different strategies for handling jailbroken devices
    enum JailbreakAction {
        case block          // Completely block the app
        case warn           // Show warning but allow usage
        case restrict       // Allow basic usage but restrict sensitive features
        case log            // Just log the detection, don't interfere
    }

    /// Handle jailbreak detection based on chosen strategy
    /// - Parameter action: The action to take when jailbreak is detected
    /// - Returns: true if app should continue, false if app should exit
    func handleJailbreak(action: JailbreakAction) -> Bool {
        guard isJailbroken() else {
            return true // Not jailbroken, continue normally
        }

        switch action {
        case .block:
            return false // Exit the app

        case .warn:
            // Show warning but allow usage
            print("⚠️ Warning: Jailbreak detected but allowing usage")
            return true

        case .restrict:
            // Log and continue (restrictions handled elsewhere)
            print("⚠️ Jailbreak detected: Restricting sensitive features")
            return true

        case .log:
            // Just log, don't interfere
            print("ℹ️ Jailbreak detected (logging only)")
            return true
        }
    }
}
