# Quick Start Guide - SimplePayment iOS App

## Step 1: Create Xcode Project

Since we can't create the `.xcodeproj` file directly, follow these steps:

### 1.1 Open Xcode
```bash
open -a Xcode
```

### 1.2 Create New Project
1. Click **"Create a new Xcode project"**
2. Select **iOS** → **App**
3. Click **Next**

### 1.3 Configure Project
```
Product Name: SimplePayment
Team: (Select your team)
Organization Identifier: com.yourname
Bundle Identifier: com.yourname.SimplePayment
Interface: SwiftUI
Language: Swift
Storage: None (we'll use our custom implementation)
Include Tests: ✓ (optional)
```

4. Click **Next**
5. Save location: Select the `SimplePayment` folder (NOT the inner one)
6. Click **Create**

## Step 2: Replace Default Files

Xcode created some default files. We need to replace them:

### 2.1 Delete Default Files
In Xcode's Project Navigator, **delete** these files (select "Move to Trash"):
- `SimplePaymentApp.swift` (the default one)
- `ContentView.swift` (the default one)
- `Assets.xcassets` (keep this for now)
- `Preview Content` folder (optional)

### 2.2 Add Our Files to Xcode

1. In Finder, navigate to the `SimplePayment/SimplePayment` folder
2. Drag these folders into Xcode's Project Navigator:
   - `App`
   - `Core`
   - `Models`
   - `ViewModels`
   - `Services`
   - `Views`
   - `Utilities`
   - `Resources`

3. When prompted, select:
   - ✓ **Copy items if needed** (if prompted)
   - ✓ **Create groups**
   - ✓ **Add to target: SimplePayment**

### 2.3 Add Info.plist
1. Drag `Info.plist` into the project root in Xcode
2. In Build Settings, search for "Info.plist File"
3. Set the path to: `SimplePayment/Info.plist`

## Step 3: Configure Build Settings

### 3.1 Set Deployment Target
1. Select project in Project Navigator
2. Select **SimplePayment** target
3. **General** tab
4. **Minimum Deployments**: iOS 16.0

### 3.2 Configure Signing
1. **Signing & Capabilities** tab
2. Check **Automatically manage signing**
3. Select your **Team**
4. Bundle Identifier will auto-populate

## Step 4: Add Required Frameworks

Some frameworks are needed for the app to work:

1. Select project → **SimplePayment** target
2. **General** tab → **Frameworks, Libraries, and Embedded Content**
3. Click **+** and add:
   - No additional frameworks needed (all are built-in)

## Step 5: Update API Endpoint

### 5.1 Open `Core/Network/APIClient.swift`

Find this line:
```swift
private let baseURL = "https://api.simplepayment.com/v1"
```

Replace with your backend API:
```swift
private let baseURL = "https://your-backend-api.com/v1"
```

### 5.2 For Testing Without Backend

If you don't have a backend yet, you can use mock data:

1. Open `Services/TransactionService.swift`
2. Temporarily comment out API calls
3. Use hardcoded test data

Example:
```swift
// Instead of:
let transactions: [Transaction] = try await apiClient.request(.transactions)

// Use:
let transactions = [
    Transaction(
        amount: 100.00,
        recipientId: "test1",
        recipientName: "Code toan bug",
        senderId: "me",
        senderName: "Me",
        type: .sent,
        status: .completed
    )
]
```

## Step 6: Build and Run

### 6.1 Select Target
- Choose a simulator: **iPhone 15 Pro** (or any iOS 16+ device)

### 6.2 Build
- Press **⌘ + B** (Cmd + B) to build
- Fix any errors if they appear

### 6.3 Run
- Press **⌘ + R** (Cmd + R) to run
- The app should launch in the simulator

## Step 7: Test Offline Functionality

### 7.1 Enable Network Link Conditioner

**On Simulator:**
1. Open **Settings** app in simulator
2. Scroll down to **Developer**
3. Enable **Network Link Conditioner**
4. Select **100% Loss** or **Edge** (2G)

**On Mac:**
1. Open **System Settings**
2. **Developer** (if installed)
3. Enable **Network Link Conditioner**

### 7.2 Test Offline Features

1. Launch app
2. Login (will fail if offline - test with backend first)
3. Enable airplane mode or 100% packet loss
4. Try to send money
5. See transaction queued with orange indicator
6. Disable airplane mode
7. Watch transaction sync automatically

## Common Issues & Solutions

### Issue: "No such module" errors

**Solution:**
- Clean build folder: **⌘ + Shift + K**
- Rebuild: **⌘ + B**

### Issue: Files not found

**Solution:**
- Ensure all files are in correct folders
- Check file is added to target (File Inspector → Target Membership)

### Issue: Preview crashes

**Solution:**
- Previews might not work without proper environment objects
- Run on simulator instead
- Or update preview code:

```swift
#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
}
```

### Issue: Build errors in CacheManager

**Solution:**
The `AnyCodable` implementation is simplified. For production, use a proper library like:
- https://github.com/Flight-School/AnyCodable

Or replace with specific types.

### Issue: Keychain errors on simulator

**Solution:**
- Reset simulator: **Device** → **Erase All Content and Settings**
- Or delete app and reinstall

## Project Structure Overview

```
SimplePayment/
├── SimplePayment/
│   ├── App/
│   │   ├── SimplePaymentApp.swift       ← App entry point (@main)
│   │   └── ContentView.swift            ← Root view
│   │
│   ├── Core/
│   │   ├── Network/
│   │   │   ├── NetworkMonitor.swift     ← Detects online/offline
│   │   │   └── APIClient.swift          ← API requests with retry
│   │   └── Storage/
│   │       ├── SecureStorage.swift      ← Keychain wrapper
│   │       └── CacheManager.swift       ← Two-layer caching
│   │
│   ├── Models/
│   │   ├── User.swift                   ← User model
│   │   ├── Transaction.swift            ← Transaction model
│   │   └── Wallet.swift                 ← Wallet model
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift          ← Auth state & logic
│   │   └── WalletViewModel.swift        ← Wallet operations
│   │
│   ├── Services/
│   │   └── TransactionService.swift     ← Handles offline queue
│   │
│   └── Views/
│       ├── Auth/                        ← Login/Register
│       ├── Home/                        ← Dashboard
│       ├── Transaction/                 ← Send money, history
│       ├── Profile/                     ← User profile
│       └── Components/                  ← Reusable UI components
│
└── README.md
```

## Next Steps

### 1. **Backend Integration**
   - Implement the required API endpoints
   - See `README.md` for API specifications

### 2. **Add Security Features**
   - Enable SSL pinning (see `IOS_APP_SECURITY.md`)
   - Add biometric authentication
   - Implement jailbreak detection

### 3. **Add Features**
   - QR code scanning
   - Push notifications
   - Receipt generation
   - Contact integration

### 4. **Testing**
   - Write unit tests
   - Test on different network speeds
   - Test offline scenarios
   - Test on real devices

### 5. **App Store Preparation**
   - Add app icons
   - Create screenshots
   - Write app description
   - Submit for review

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Network Framework](https://developer.apple.com/documentation/network)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Getting Help

If you encounter issues:

1. **Check the code comments** - Most files have detailed explanations
2. **Read the architecture docs** - See `IOS_APP_ARCHITECTURE.md`
3. **Review security guide** - See `IOS_APP_SECURITY.md`
4. **Clean and rebuild** - Often fixes mysterious issues

## Development Tips

### Use SwiftUI Previews
Add previews to your views for faster iteration:

```swift
#Preview {
    YourView()
        .environmentObject(AuthViewModel())
}
```

### Debug Network Issues
Add breakpoints in `APIClient.swift` to see requests/responses

### Monitor Performance
Use Instruments (⌘ + I) to check:
- Memory usage
- Network activity
- Time profiler

### Test on Real Device
Simulator is great, but test on real device for:
- Network conditions
- Performance
- Battery usage
- Face ID/Touch ID

Good luck with your app! 🚀
