# iOS App Security Hardening Guide
## Advanced Security Measures for Payment App

---

## 1. Jailbreak Detection

### Why It Matters
Jailbroken devices bypass iOS security restrictions, making your app vulnerable to:
- Modified system files
- Debugging and reverse engineering
- Malicious tweaks intercepting data
- Bypassed security features

### Implementation

```swift
import UIKit

class JailbreakDetector {

    static let shared = JailbreakDetector()

    // Main detection method
    func isJailbroken() -> Bool {
        // Check multiple indicators
        return checkSuspiciousFiles() ||
               checkSuspiciousApps() ||
               checkSystemDirectoryWritable() ||
               checkCydiaURLScheme() ||
               checkFork() ||
               checkSymbolicLinks() ||
               checkDyldEnvironmentVariables()
    }

    // Method 1: Check for common jailbreak files
    private func checkSuspiciousFiles() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/private/var/lib/apt",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/usr/bin/sshd",
            "/usr/libexec/sftp-server",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/bin/bash",
            "/bin/sh",
            "/usr/libexec/ssh-keysign",
            "/usr/libexec/cydia",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia",
            "/usr/bin/ssh"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }

            // Also check if we can open the file
            if let file = fopen(path, "r") {
                fclose(file)
                return true
            }
        }

        return false
    }

    // Method 2: Check for jailbreak apps
    private func checkSuspiciousApps() -> Bool {
        let schemes = ["cydia://", "undecimus://", "sileo://", "zbra://"]

        for scheme in schemes {
            if let url = URL(string: scheme) {
                if UIApplication.shared.canOpenURL(url) {
                    return true
                }
            }
        }

        return false
    }

    // Method 3: Check if we can write to system directories
    private func checkSystemDirectoryWritable() -> Bool {
        let testPath = "/private/jailbreak_test.txt"

        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // Should not be able to write here
        } catch {
            return false // Good, can't write to system
        }
    }

    // Method 4: Check Cydia URL scheme
    private func checkCydiaURLScheme() -> Bool {
        if let url = URL(string: "cydia://package/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }

    // Method 5: Check if fork() is available (should fail on non-jailbroken)
    private func checkFork() -> Bool {
        let result = fork()
        if result >= 0 {
            if result > 0 {
                // Parent process - kill child
                kill(result, SIGTERM)
            }
            return true // Jailbroken
        }
        return false // Normal behavior
    }

    // Method 6: Check for symbolic links
    private func checkSymbolicLinks() -> Bool {
        do {
            let path = "/Applications"
            let attributes = try FileManager.default.attributesOfItem(atPath: path)

            if let fileType = attributes[.type] as? FileAttributeType {
                return fileType == .typeSymbolicLink
            }
        } catch {
            return false
        }
        return false
    }

    // Method 7: Check for suspicious environment variables
    private func checkDyldEnvironmentVariables() -> Bool {
        let suspiciousVars = ["DYLD_INSERT_LIBRARIES", "_MSSafeMode"]

        for variable in suspiciousVars {
            if let value = getenv(variable), String(cString: value).count > 0 {
                return true
            }
        }

        return false
    }
}

// Usage in AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Check for jailbreak
        if JailbreakDetector.shared.isJailbroken() {
            handleJailbrokenDevice()
            return false
        }

        return true
    }

    private func handleJailbrokenDevice() {
        // Option 1: Block the app completely
        showJailbreakAlert()

        // Option 2: Restrict features (recommended for better UX)
        // - Disable sending money
        // - Disable withdrawals
        // - Show warning banner
        // - Log to analytics
    }

    private func showJailbreakAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Security Warning",
                message: "This device appears to be jailbroken. For your security, this app cannot run on modified devices.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
                exit(0)
            })

            // Present alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
}
```

---

## 2. Debugger Detection

### Prevent Debugging and Reverse Engineering

```swift
import Foundation
import Darwin

class DebuggerDetector {

    static let shared = DebuggerDetector()

    // Check if debugger is attached
    func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        if result != 0 {
            return false
        }

        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // Continuous monitoring (call in background)
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.isDebuggerAttached() {
                self.handleDebuggerDetected()
            }
        }
    }

    private func handleDebuggerDetected() {
        // Option 1: Exit immediately
        exit(0)

        // Option 2: Crash intentionally
        // fatalError("Debugger detected")

        // Option 3: Clear sensitive data and show error
        // clearSensitiveData()
        // showDebuggerAlert()
    }

    // Anti-debugging using ptrace
    func disablePtrace() {
        #if !DEBUG
        // Prevent debugger attachment using ptrace
        let PT_DENY_ATTACH: Int32 = 31
        ptrace(PT_DENY_ATTACH, 0, nil, 0)
        #endif
    }
}

// Call in AppDelegate
extension AppDelegate {
    func setupDebuggerProtection() {
        #if !DEBUG
        DebuggerDetector.shared.disablePtrace()
        DebuggerDetector.shared.startMonitoring()
        #endif
    }
}
```

---

## 3. SSL Pinning (Certificate Pinning)

### Prevent Man-in-the-Middle Attacks

```swift
import Foundation
import Security

class SSLPinningManager: NSObject {

    // Your server's certificate hashes (public key hashes)
    private let certificateHashes: Set<String> = [
        "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Replace with your actual certificate hash
        "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="  // Backup certificate
    ]

    // Validate server trust
    func validateServerTrust(_ serverTrust: SecTrust, domain: String?) -> Bool {
        // Get certificate chain
        guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return false
        }

        // Check each certificate
        for certificate in certificates {
            if let publicKey = SecCertificateCopyKey(certificate) {
                let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?

                if let data = publicKeyData {
                    let hash = sha256(data: data)

                    if certificateHashes.contains(hash) {
                        return true
                    }
                }
            }
        }

        return false
    }

    // Calculate SHA256 hash
    private func sha256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        let hashData = Data(hash)
        return "sha256/" + hashData.base64EncodedString()
    }
}

// URLSession Delegate Implementation
class SecureURLSessionDelegate: NSObject, URLSessionDelegate {

    private let sslPinning = SSLPinningManager()

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Validate SSL certificate
        if sslPinning.validateServerTrust(serverTrust, domain: challenge.protectionSpace.host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Invalid certificate - block connection
            completionHandler(.cancelAuthenticationChallenge, nil)

            // Log security incident
            logSecurityEvent("SSL Pinning failed for host: \(challenge.protectionSpace.host)")
        }
    }

    private func logSecurityEvent(_ message: String) {
        // Send to your security logging service
        print("🚨 SECURITY: \(message)")
    }
}

// Usage
class APIClient {
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30

        return URLSession(
            configuration: configuration,
            delegate: SecureURLSessionDelegate(),
            delegateQueue: nil
        )
    }()

    func makeRequest(url: URL) async throws -> Data {
        let (data, _) = try await session.data(from: url)
        return data
    }
}
```

---

## 4. Runtime Integrity Checks

### Detect Code Injection and Tampering

```swift
import Foundation
import CommonCrypto

class IntegrityChecker {

    static let shared = IntegrityChecker()

    // Check if app bundle has been modified
    func verifyAppIntegrity() -> Bool {
        return checkBundleSignature() &&
               checkExecutableHash() &&
               checkInfoPlistIntegrity()
    }

    // Method 1: Check bundle signature
    private func checkBundleSignature() -> Bool {
        guard let bundlePath = Bundle.main.bundlePath as CFString? else {
            return false
        }

        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(
            bundlePath as CFURL,
            SecCSFlags(),
            &staticCode
        )

        if status != errSecSuccess {
            return false
        }

        guard let code = staticCode else {
            return false
        }

        let verifyStatus = SecStaticCodeCheckValidity(
            code,
            SecCSFlags(rawValue: kSecCSCheckAllArchitectures),
            nil
        )

        return verifyStatus == errSecSuccess
    }

    // Method 2: Check executable hash
    private func checkExecutableHash() -> Bool {
        guard let executablePath = Bundle.main.executablePath else {
            return false
        }

        guard let data = FileManager.default.contents(atPath: executablePath) else {
            return false
        }

        let hash = sha256Hash(data: data)

        // Compare with known good hash (store this securely, obfuscate in code)
        let knownGoodHash = "YOUR_EXECUTABLE_HASH_HERE" // Replace with actual hash

        return hash == knownGoodHash
    }

    // Method 3: Check Info.plist integrity
    private func checkInfoPlistIntegrity() -> Bool {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            return false
        }

        // Check critical keys
        guard let bundleId = infoDictionary["CFBundleIdentifier"] as? String,
              bundleId == "com.yourcompany.paymentapp" else {
            return false
        }

        // Check if SignerIdentity exists (indicates proper signing)
        if infoDictionary["SignerIdentity"] == nil {
            return false
        }

        return true
    }

    // Check for injected libraries
    func checkForInjectedLibraries() -> Bool {
        let suspiciousLibraries = [
            "SubstrateLoader.dylib",
            "SubstrateInserter.dylib",
            "MobileSubstrate",
            "Substrate",
            "Cydia",
            "SSLKillSwitch",
            "Flex"
        ]

        for i in 0..<_dyld_image_count() {
            if let imageName = _dyld_get_image_name(i) {
                let name = String(cString: imageName)

                for suspicious in suspiciousLibraries {
                    if name.contains(suspicious) {
                        return true // Injected library found
                    }
                }
            }
        }

        return false
    }

    private func sha256Hash(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Usage
extension AppDelegate {
    func performIntegrityChecks() {
        #if !DEBUG
        if !IntegrityChecker.shared.verifyAppIntegrity() {
            handleTamperedApp()
        }

        if IntegrityChecker.shared.checkForInjectedLibraries() {
            handleInjectedLibraries()
        }
        #endif
    }

    private func handleTamperedApp() {
        // App has been modified - exit
        print("🚨 App integrity check failed")
        exit(0)
    }

    private func handleInjectedLibraries() {
        // Suspicious libraries detected
        print("🚨 Injected libraries detected")
        exit(0)
    }
}
```

---

## 5. Screen Recording & Screenshot Prevention

### Protect Sensitive Information

```swift
import UIKit

class ScreenProtection {

    static let shared = ScreenProtection()

    // Prevent screenshots on sensitive screens
    func preventScreenCapture(on view: UIView) {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        view.addSubview(textField)
        view.layer.superlayer?.addSublayer(textField.layer)
        textField.layer.sublayers?.first?.addSublayer(view.layer)
    }

    // Alternative: Blur screen when recording detected
    func setupScreenRecordingDetection(for window: UIWindow) {
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            if UIScreen.main.isCaptured {
                self.handleScreenRecording(window: window)
            } else {
                self.removeBlur(from: window)
            }
        }
    }

    private func handleScreenRecording(window: UIWindow) {
        // Add blur overlay
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.tag = 999 // Tag to identify later
        window.addSubview(blurView)

        // Add warning label
        let label = UILabel()
        label.text = "Screen recording detected\nSensitive content hidden"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.frame = window.bounds
        blurView.contentView.addSubview(label)
    }

    private func removeBlur(from window: UIWindow) {
        window.subviews.first { $0.tag == 999 }?.removeFromSuperview()
    }

    // Prevent screenshots on specific view controllers
    func secureViewController(_ viewController: UIViewController) {
        // Method 1: Use secure text field trick
        let field = UITextField()
        field.isSecureTextEntry = true
        viewController.view.addSubview(field)
        viewController.view.layer.superlayer?.addSublayer(field.layer)
        field.layer.sublayers?.first?.addSublayer(viewController.view.layer)

        // Method 2: Detect screenshot attempts
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleScreenshotTaken(on: viewController)
        }
    }

    private func handleScreenshotTaken(on viewController: UIViewController) {
        // Log the event
        print("🚨 Screenshot taken on secure screen")

        // Show warning
        let alert = UIAlertController(
            title: "Screenshot Detected",
            message: "Taking screenshots of sensitive information is not allowed for security reasons.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)

        // Optionally: Log out user or lock app
        // SecurityManager.shared.lockApp()
    }
}

// Usage in SwiftUI
struct SecureView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SecureViewController {
        let vc = SecureViewController()
        ScreenProtection.shared.secureViewController(vc)
        return vc
    }

    func updateUIViewController(_ uiViewController: SecureViewController, context: Context) {}
}

class SecureViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Your secure content here
    }
}
```

---

## 6. Secure Data Storage

### Keychain Best Practices

```swift
import Security
import Foundation

class SecureStorage {

    static let shared = SecureStorage()

    // Save sensitive data to Keychain
    func save(_ data: Data, for key: String, requireBiometric: Bool = false) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: requireBiometric ?
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly :
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Add biometric protection if required
        if requireBiometric {
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet, // Requires Face ID/Touch ID
                nil
            )

            var queryWithBiometric = query
            queryWithBiometric[kSecAttrAccessControl as String] = access

            SecItemDelete(queryWithBiometric as CFDictionary)
            let status = SecItemAdd(queryWithBiometric as CFDictionary, nil)

            guard status == errSecSuccess else {
                throw KeychainError.unableToSave
            }
        } else {
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)

            guard status == errSecSuccess else {
                throw KeychainError.unableToSave
            }
        }
    }

    // Retrieve data from Keychain
    func get(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.unableToRetrieve
        }

        return result as? Data
    }

    // Delete from Keychain
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }

    // Clear all app data (logout)
    func clearAll() {
        let secClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        for secClass in secClasses {
            let query: [String: Any] = [kSecClass as String: secClass]
            SecItemDelete(query as CFDictionary)
        }
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
}

// Helper extensions
extension SecureStorage {
    func saveString(_ string: String, for key: String, requireBiometric: Bool = false) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unableToSave
        }
        try save(data, for: key, requireBiometric: requireBiometric)
    }

    func getString(_ key: String) throws -> String? {
        guard let data = try get(key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func saveCodable<T: Codable>(_ object: T, for key: String, requireBiometric: Bool = false) throws {
        let data = try JSONEncoder().encode(object)
        try save(data, for: key, requireBiometric: requireBiometric)
    }

    func getCodable<T: Codable>(_ key: String, as type: T.Type) throws -> T? {
        guard let data = try get(key) else {
            return nil
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

// Usage example
class AuthService {
    func saveAuthToken(_ token: String) {
        do {
            // Save with biometric protection
            try SecureStorage.shared.saveString(
                token,
                for: "auth_token",
                requireBiometric: true
            )
        } catch {
            print("Failed to save token: \(error)")
        }
    }

    func getAuthToken() -> String? {
        try? SecureStorage.shared.getString("auth_token")
    }
}
```

---

## 7. Code Obfuscation

### Make Reverse Engineering Harder

```swift
// String obfuscation
class StringObfuscator {
    // Instead of storing plaintext strings like:
    // let apiKey = "sk_live_12345abcde"

    // Store them obfuscated:
    static func deobfuscate(_ obfuscated: [UInt8]) -> String {
        let key: UInt8 = 0xAC // Change this key
        let deobfuscated = obfuscated.map { $0 ^ key }
        return String(bytes: deobfuscated, encoding: .utf8) ?? ""
    }

    // Usage:
    static var apiKey: String {
        // Original: "sk_live_12345"
        let obfuscated: [UInt8] = [255, 203, 175, 200, 201, 238, 205, 173, 169, 168, 165, 164, 163]
        return deobfuscate(obfuscated)
    }
}

// API endpoint obfuscation
class APIEndpoints {
    private static let baseComponents: [UInt8] = [47, 47, 47, 47] // Obfuscated

    static var baseURL: String {
        // Reconstruct at runtime instead of hardcoding
        let scheme = String(data: Data([104, 116, 116, 112, 115]), encoding: .utf8)!
        let host = String(data: Data([97, 112, 105, 46, 101, 120, 97, 109, 112, 108, 101, 46, 99, 111, 109]), encoding: .utf8)!
        return "\(scheme)://\(host)"
    }
}
```

---

## 8. Network Security

### Secure API Communication

```swift
import Foundation

class SecureAPIClient {

    // Add custom headers for security
    func createSecureRequest(url: URL, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)

        // Security headers
        request.setValue(createNonce(), forHTTPHeaderField: "X-Request-Nonce")
        request.setValue(createTimestamp(), forHTTPHeaderField: "X-Request-Timestamp")
        request.setValue(createSignature(url: url, body: body), forHTTPHeaderField: "X-Request-Signature")
        request.setValue(getDeviceId(), forHTTPHeaderField: "X-Device-ID")
        request.setValue(getAppVersion(), forHTTPHeaderField: "X-App-Version")

        // Prevent caching of sensitive data
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        return request
    }

    // Generate unique nonce for each request
    private func createNonce() -> String {
        UUID().uuidString
    }

    // Add timestamp to prevent replay attacks
    private func createTimestamp() -> String {
        String(Int(Date().timeIntervalSince1970))
    }

    // Create HMAC signature
    private func createSignature(url: URL, body: Data?) -> String {
        let message = url.absoluteString + (body?.base64EncodedString() ?? "")
        // In production, use a secure key from Keychain
        let key = "your-secret-key"

        return hmacSHA256(message: message, key: key)
    }

    private func hmacSHA256(message: String, key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
               key, key.count,
               message, message.count,
               &digest)
        return Data(digest).base64EncodedString()
    }

    private func getDeviceId() -> String {
        // Get or create persistent device ID
        if let deviceId = try? SecureStorage.shared.getString("device_id") {
            return deviceId
        }

        let newId = UUID().uuidString
        try? SecureStorage.shared.saveString(newId, for: "device_id")
        return newId
    }

    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
```

---

## 9. Security Manager - Main Coordinator

```swift
import UIKit

class SecurityManager {

    static let shared = SecurityManager()

    private var isAppLocked = false
    private var backgroundTime: Date?

    // Run all security checks
    func performSecurityChecks() -> Bool {
        var passed = true

        #if !DEBUG
        // 1. Jailbreak detection
        if JailbreakDetector.shared.isJailbroken() {
            logSecurityEvent("Jailbreak detected")
            passed = false
        }

        // 2. Debugger detection
        if DebuggerDetector.shared.isDebuggerAttached() {
            logSecurityEvent("Debugger detected")
            exit(0) // Immediate exit
        }

        // 3. Integrity check
        if !IntegrityChecker.shared.verifyAppIntegrity() {
            logSecurityEvent("App integrity check failed")
            passed = false
        }

        // 4. Check for injected libraries
        if IntegrityChecker.shared.checkForInjectedLibraries() {
            logSecurityEvent("Injected libraries detected")
            passed = false
        }
        #endif

        return passed
    }

    // App lifecycle security
    func setupAppLifecycleSecurity() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        backgroundTime = Date()

        // Clear clipboard
        UIPasteboard.general.items = []

        // Hide sensitive data in app switcher
        blurAppSnapshot()
    }

    @objc private func appWillEnterForeground() {
        // Check if app was in background too long
        if let bgTime = backgroundTime,
           Date().timeIntervalSince(bgTime) > 300 { // 5 minutes
            requireReauthentication()
        }

        removeBlur()
    }

    private func blurAppSnapshot() {
        guard let window = UIApplication.shared.windows.first else { return }

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = window.bounds
        blurView.tag = 888
        window.addSubview(blurView)
    }

    private func removeBlur() {
        UIApplication.shared.windows.first?.subviews
            .first { $0.tag == 888 }?
            .removeFromSuperview()
    }

    func requireReauthentication() {
        isAppLocked = true
        // Show biometric authentication screen
        NotificationCenter.default.post(name: .requireAuth, object: nil)
    }

    func lockApp() {
        isAppLocked = true
        // Clear sensitive data from memory
        clearSensitiveData()
        // Show lock screen
        NotificationCenter.default.post(name: .appLocked, object: nil)
    }

    private func clearSensitiveData() {
        // Clear any cached sensitive data
        URLCache.shared.removeAllCachedResponses()
    }

    private func logSecurityEvent(_ message: String) {
        print("🚨 SECURITY: \(message)")
        // Send to your logging service
        // Analytics.logEvent("security_event", parameters: ["message": message])
    }
}

extension Notification.Name {
    static let requireAuth = Notification.Name("requireAuth")
    static let appLocked = Notification.Name("appLocked")
}
```

---

## 10. Complete AppDelegate Setup

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 1. Perform all security checks
        let securityPassed = SecurityManager.shared.performSecurityChecks()

        if !securityPassed {
            showSecurityAlert()
            return true // Don't exit immediately, show alert first
        }

        // 2. Setup continuous monitoring
        #if !DEBUG
        DebuggerDetector.shared.disablePtrace()
        DebuggerDetector.shared.startMonitoring()
        #endif

        // 3. Setup app lifecycle security
        SecurityManager.shared.setupAppLifecycleSecurity()

        // 4. Setup screen recording detection
        if let window = window {
            ScreenProtection.shared.setupScreenRecordingDetection(for: window)
        }

        return true
    }

    private func showSecurityAlert() {
        let alert = UIAlertController(
            title: "Security Alert",
            message: "This app cannot run in the current environment due to security restrictions.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
            exit(0)
        })

        window?.rootViewController?.present(alert, animated: true)
    }
}
```

---

## 11. Security Checklist

### Pre-Release Security Audit

```
✅ Jailbreak Detection
   - Multiple detection methods implemented
   - Handles jailbroken devices gracefully

✅ Debugger Protection
   - Debugger attachment blocked
   - Continuous monitoring active
   - Ptrace disabled in production

✅ SSL Pinning
   - Certificate pinning implemented
   - Backup certificates configured
   - MITM attacks prevented

✅ Code Integrity
   - Bundle signature verification
   - Executable hash checking
   - Injected library detection

✅ Screen Protection
   - Screenshots prevented on sensitive screens
   - Screen recording detection active
   - Blur overlay when recording

✅ Secure Storage
   - Sensitive data in Keychain only
   - Biometric protection for critical data
   - No plaintext credentials

✅ Code Obfuscation
   - API keys obfuscated
   - Endpoints obfuscated
   - String encryption for secrets

✅ Network Security
   - HTTPS only
   - Request signing
   - Replay attack prevention

✅ App Lifecycle
   - Auto-lock after inactivity
   - Blur snapshot in app switcher
   - Re-authentication required

✅ Memory Protection
   - Sensitive data cleared on logout
   - No sensitive data in logs
   - Cache cleared appropriately
```

---

## Summary

This comprehensive security implementation provides:

1. **Jailbreak Detection**: Multiple methods to detect modified devices
2. **Debugger Protection**: Prevent debugging and code injection
3. **SSL Pinning**: Prevent man-in-the-middle attacks
4. **Runtime Integrity**: Detect app tampering
5. **Screen Protection**: Prevent screenshots/recording
6. **Secure Storage**: Keychain with biometric protection
7. **Code Obfuscation**: Make reverse engineering harder
8. **Network Security**: Signed requests, HTTPS only
9. **Lifecycle Security**: Auto-lock, blur snapshots
10. **Centralized Management**: Single security coordinator

**Remember:**
- Security is a balance between protection and user experience
- Test thoroughly in DEBUG mode (most checks disabled)
- Update security measures regularly
- Monitor security incidents
- Have a plan for when security is compromised
