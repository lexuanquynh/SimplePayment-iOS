# SimplePayment iOS App

A secure, offline-first payment application built with SwiftUI, optimized for low network connectivity.

## Features

- ✅ **Offline-First Architecture**: Send money even without internet connection
- ✅ **Secure Storage**: Bank-level encryption using Keychain
- ✅ **Low Bandwidth Optimization**: Works on 2G/3G networks
- ✅ **Real-time Balance Updates**: Instant UI updates with background sync
- ✅ **Transaction Queue**: Auto-sync pending transactions when online
- ✅ **Network Monitoring**: Adaptive behavior based on connection quality
- ✅ **Modern SwiftUI**: Clean, declarative UI code

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Architecture

### Core Components

```
SimplePayment/
├── App/
│   ├── SimplePaymentApp.swift       # App entry point
│   └── ContentView.swift            # Root view
├── Core/
│   ├── Network/
│   │   ├── NetworkMonitor.swift     # Network connectivity monitoring
│   │   └── APIClient.swift          # API client with retry logic
│   └── Storage/
│       ├── SecureStorage.swift      # Keychain wrapper
│       └── CacheManager.swift       # Two-layer caching
├── Models/
│   ├── User.swift                   # User model
│   ├── Transaction.swift            # Transaction model
│   └── Wallet.swift                 # Wallet model
├── ViewModels/
│   ├── AuthViewModel.swift          # Authentication logic
│   └── WalletViewModel.swift        # Wallet operations
├── Services/
│   └── TransactionService.swift     # Transaction handling
└── Views/
    ├── Auth/                        # Login/Register
    ├── Home/                        # Dashboard
    ├── Transaction/                 # Send money, history
    ├── Profile/                     # User profile
    └── Components/                  # Reusable components
```

## Getting Started

### 1. Open the Project

```bash
cd SimplePayment
open SimplePayment.xcodeproj
```

### 2. Configure Bundle Identifier

1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Change Bundle Identifier to your own (e.g., `com.yourname.simplepayment`)

### 3. Update API Endpoint

In `Core/Network/APIClient.swift`, update the `baseURL`:

```swift
private let baseURL = "https://your-api-endpoint.com/v1"
```

### 4. Build and Run

1. Select a simulator or device
2. Press `Cmd + R` to build and run

## Key Features Explained

### Offline-First Architecture

The app uses a queue system for transactions:

1. **User sends money offline** → Saved locally
2. **Connection returns** → Auto-sync to server
3. **Server confirms** → Update UI

```swift
// Transactions are queued when offline
await TransactionService.shared.sendMoney(
    amount: 100,
    to: recipientId,
    recipientName: "John Doe",
    from: currentUserId,
    senderName: "Me"
)
```

### Two-Layer Caching

- **Layer 1**: In-memory cache (instant access)
- **Layer 2**: Disk cache (persistent)

```swift
// Cache balance for 5 minutes
await CacheManager.shared.set(balance, for: "wallet", ttl: 300)

// Retrieve from cache
let balance = await CacheManager.shared.get("wallet", as: Wallet.self)
```

### Network Monitoring

Automatically detects connection quality and adapts:

```swift
if networkMonitor.isLowBandwidth {
    // Use compressed images
    // Reduce API calls
    // Prioritize critical data
}
```

## API Integration

### Required Endpoints

Your backend should implement these endpoints:

#### Auth
- `POST /auth/login` - User login
- `POST /auth/register` - User registration

#### User
- `GET /user/profile` - Get user profile

#### Wallet
- `GET /wallet/balance` - Get wallet balance

#### Transactions
- `GET /transactions` - Get transaction history
- `POST /transactions/send` - Send money
- `GET /transactions/:id` - Get transaction details

### Request Format

All requests include these headers:

```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
X-Request-ID: {uuid}
```

### Response Format

Standard response format:

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

## Security

### Implemented Security Measures

- ✅ **Keychain Storage**: All sensitive data encrypted
- ✅ **SSL Pinning**: Prevent MITM attacks (configurable)
- ✅ **Request Signing**: HMAC signatures (configurable)
- ✅ **No Plaintext Passwords**: Never stored
- ✅ **Automatic Logout**: After inactivity

### Production Checklist

Before releasing to production:

1. [ ] Enable SSL pinning in `APIClient.swift`
2. [ ] Add jailbreak detection
3. [ ] Implement biometric authentication
4. [ ] Add request signing
5. [ ] Enable code obfuscation
6. [ ] Add crash reporting (Firebase/Sentry)
7. [ ] Implement proper error tracking

## Testing

### Unit Tests

```bash
Cmd + U  # Run all tests
```

### Network Simulation

1. Open **Settings** app on simulator
2. **Developer** → **Network Link Conditioner**
3. Enable and select profile (2G, 3G, etc.)

## Performance Optimization

### Implemented Optimizations

- Request compression (gzip)
- Image caching
- Pagination for lists
- Background sync
- Efficient memory management

### Performance Targets

- App launch: < 2 seconds
- Transaction send: < 1 second (online)
- UI animations: 60 FPS
- Memory usage: < 100 MB

## Troubleshooting

### Common Issues

**App crashes on launch**
- Check bundle identifier is correct
- Verify iOS deployment target is 16.0+

**Network requests fail**
- Update `baseURL` in `APIClient.swift`
- Check Info.plist has correct permissions

**Transactions not syncing**
- Verify network connection
- Check console logs for errors
- Ensure API endpoints are correct

## Future Enhancements

- [ ] Biometric authentication (Face ID/Touch ID)
- [ ] QR code scanning
- [ ] Push notifications
- [ ] Bank account linking
- [ ] Receipt generation
- [ ] Multi-currency support
- [ ] Dark mode
- [ ] iPad support

## License

MIT License - Feel free to use this code for your own projects.

## Support

For issues or questions:
- Check the code documentation
- Review the architecture documents
- Create an issue in the repository

---

Built with ❤️ using SwiftUI
