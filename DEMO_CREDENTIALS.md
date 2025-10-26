# Demo Credentials & Testing Guide

## 🎮 Demo Mode (Currently Active)

The app is currently in **MOCK MODE** for testing without a backend.

### How It Works

The app accepts **ANY** email and password combination when `useMockMode = true` in `AuthViewModel.swift`.

---

## 📧 Demo Credentials (You Can Use Anything!)

### Login
```
Email: demo@example.com
Password: password123

OR any email/password combination!
```

### Register
Just fill in the form with any values:
```
Name: Code toan bug
Email: john@example.com
Phone: +1234567890
Password: password123
```

---

## 🔧 Switching Between Mock and Real Backend

### Current Setting: Mock Mode ✅

**File:** `ViewModels/AuthViewModel.swift`

```swift
// Line 18
private let useMockMode = true  // ← Currently set to TRUE
```

### To Use Real Backend:

**Step 1:** Change the flag
```swift
private let useMockMode = false  // Set to false
```

**Step 2:** Update API endpoint in `Core/Network/APIClient.swift`
```swift
private let baseURL = "https://your-api-url.com/v1"  // Your real API
```

---

## 🧪 What Mock Mode Provides

### ✅ Working Features:
- Login with any credentials
- Register new users
- Token refresh (automatic session renewal)
- View profile
- Navigate through app
- Logout

### ⚠️ Limited Features (need real backend):
- Wallet balance shows as `$0.00`
- Cannot actually send/receive money
- No real transaction history
- No push notifications

---

## 📱 Testing the App

### Quick Test Flow:

1. **Launch App** → Shows login screen

2. **Option A: Login**
   - Email: `demo@example.com`
   - Password: `anything`
   - Tap "Log In"
   - Wait 1 second (simulated network delay)
   - ✅ Logged in as "Demo User"

3. **Option B: Register**
   - Fill in any details
   - Tap "Create Account"
   - Wait 1 second
   - ✅ Logged in with your name

4. **Explore App**
   - View dashboard
   - Check profile
   - Navigate tabs

5. **Logout**
   - Go to Profile tab
   - Tap "Log Out"
   - Returns to login screen

---

## 🔐 What Gets Saved

When you login in mock mode:

**Keychain Storage:**
```
auth_token: "mock-token-12345"
refresh_token: "mock-refresh-token"
current_user: { User object }
```

**User Object:**
```json
{
  "id": "demo-user-123",
  "name": "Demo User",
  "email": "demo@example.com",
  "phone": "+1234567890",
  "createdAt": "2025-01-26T10:30:00Z"
}
```

---

## 🔄 Token Refresh (Demo Mode)

The app now supports **automatic token refresh** in demo mode!

### How It Works

When your authentication token expires, the app can automatically refresh it:

```swift
// AuthViewModel has a new method
try await authViewModel.refreshToken()
```

### In Demo Mode:

- **Simulates network delay**: 0.5 seconds
- **Generates new tokens**: With timestamp for uniqueness
  ```
  auth_token: "mock-token-1738000000"
  refresh_token: "mock-refresh-token-1738000000"
  ```
- **Prints confirmation**: Check console for "✅ Mock token refreshed"

### In Production Mode:

- **Calls `/auth/refresh` endpoint**
- **Sends refresh token** from Keychain
- **Receives new tokens** from server
- **Updates Keychain** automatically

### Testing Token Refresh

You can manually test token refresh:

1. Login to the app
2. In your code, call:
   ```swift
   Task {
       try await authViewModel.refreshToken()
   }
   ```
3. Check console for: `✅ Mock token refreshed: mock-token-...`

---

## 🛠️ Adding Mock Data for Testing

Want to test with wallet balance and transactions? You can extend the mock mode:

### Add Mock Wallet (Optional)

**File:** `ViewModels/WalletViewModel.swift`

```swift
// Add this property
private let useMockMode = true

// Update loadBalance() method
func loadBalance() async {
    if useMockMode {
        // Mock wallet with balance
        self.wallet = Wallet(
            userId: "demo-user-123",
            balance: 1250.50,
            availableBalance: 1250.50,
            frozenBalance: 0
        )
        return
    }

    // Real API call...
}
```

### Add Mock Transactions (Optional)

**File:** `Services/TransactionService.swift`

```swift
// Add mock data
func fetchTransactions() async throws -> [Transaction] {
    if useMockMode {
        return [
            Transaction(
                amount: 100.00,
                recipientId: "user-2",
                recipientName: "Code toan bug",
                senderId: "demo-user-123",
                senderName: "Demo User",
                type: .sent,
                status: .completed,
                createdAt: Date().addingTimeInterval(-86400) // Yesterday
            ),
            Transaction(
                amount: 250.00,
                recipientId: "demo-user-123",
                recipientName: "Demo User",
                senderId: "user-3",
                senderName: "Codetoanbug",
                type: .received,
                status: .completed,
                createdAt: Date().addingTimeInterval(-172800) // 2 days ago
            )
        ]
    }

    // Real API call...
}
```

---

## 🚀 Production Checklist

Before releasing to production:

### Required Changes:

- [ ] Set `useMockMode = false` in `AuthViewModel.swift`
- [ ] Update `baseURL` in `APIClient.swift` with real API
- [ ] Implement real backend endpoints (see `BACKEND_ARCHITECTURE.md`)
- [ ] Remove or hide mock code from production build
- [ ] Add real error handling
- [ ] Enable SSL pinning
- [ ] Add jailbreak detection
- [ ] Test with real API

---

## 💡 Tips

### Resetting the App

To clear all data and start fresh:

**Option 1: In App**
- Tap "Log Out" (clears Keychain)

**Option 2: Simulator**
```bash
Device → Erase All Content and Settings
```

**Option 3: Delete App**
- Long press app icon → Delete App
- Reinstall

### Testing Offline Mode

1. Login with mock mode
2. Enable Airplane Mode on simulator
3. Try to send money
4. See it queue locally
5. Disable Airplane Mode
6. (Would auto-sync with real backend)

### Common Issues

**Q: Login doesn't work?**
A: Check that `useMockMode = true` in AuthViewModel.swift:18

**Q: No balance showing?**
A: This is normal - mock mode doesn't populate wallet data. Add mock wallet (see above).

**Q: Can't send money?**
A: Mock mode only handles authentication. Sending money needs a real backend or additional mock code.

---

## 📚 Related Documentation

- `README.md` - Full app documentation
- `BACKEND_ARCHITECTURE.md` - Backend API specifications
- `IOS_APP_ARCHITECTURE.md` - App architecture details
- `QUICKSTART.md` - Setup instructions

---

**Happy Testing! 🎉**
