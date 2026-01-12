# RideShare - Flutter Ride-Hailing Application

A complete Flutter mobile application for ride-hailing with Google Maps integration, live tracking, routing, and ride request dispatch system.

## 🚀 Features

### Core Features
- **Google Maps Integration** - Real-time map rendering with markers and polylines
- **Live Location Tracking** - Real-time driver location updates
- **Route Calculation** - Google Directions API integration for route planning
- **Ride Request System** - Complete flow from request to completion
- **Driver Dispatch** - Real-time ride request broadcasting to drivers
- **Fare Estimation** - Dynamic fare calculation based on distance and duration
- **Multi-Role Support** - Separate interfaces for riders and drivers

### User Features
- Select pickup and destination on map
- Search locations using Google Places API
- View fare estimate before requesting
- Track driver in real-time
- Live ETA updates
- Driver information display
- Trip progress monitoring

### Driver Features
- Online/Offline availability toggle
- Receive ride requests in real-time
- View ride details before accepting
- Navigate to pickup location
- Start and complete trips

## 📁 Project Architecture

```
lib/
├── main.dart                      # App entry point
├── core/
│   ├── theme/
│   │   ├── app_colors.dart       # Color palette
│   │   └── app_theme.dart        # Theme configuration
│   ├── constants/
│   │   └── constants.dart         # App constants
│   └── utils/
│       ├── location_helper.dart   # Location utilities
│       └── map_helper.dart        # Map utilities
├── data/
│   ├── models/
│   │   ├── user.dart
│   │   ├── driver.dart
│   │   ├── ride.dart
│   │   ├── ride_request.dart
│   │   └── location_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── location_service.dart
│   │   ├── google_maps_service.dart
│   │   └── ride_service.dart
│   └── repositories/
│       ├── user_repository.dart
│       ├── driver_repository.dart
│       └── ride_repository.dart
├── providers/
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── ride_provider.dart
│   └── driver_provider.dart
├── router/
│   └── app_router.dart            # GoRouter configuration
└── ui/
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── login_screen.dart
    │   ├── home_screen.dart
    │   ├── ride_request_screen.dart
    │   ├── driver_map_screen.dart
    │   ├── user_tracking_screen.dart
    │   └── ride_status_screen.dart
    └── widgets/
        ├── custom_button.dart
        ├── ride_request_card.dart
        └── driver_info_card.dart
```

## 🛠 Setup Instructions

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode
- Google Maps API Key

### 1. Clone the Repository
```bash
git clone <repository-url>
cd drup
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Google Maps API Setup

#### Get Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API
   - Places API
   - Geocoding API
4. Create credentials (API Key)

#### Configure API Key

**For Android:**
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest ...>
    <application ...>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_API_KEY_HERE"/>
    </application>
</manifest>
```

**For iOS:**
Edit `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Update App Constants:**
Edit `lib/core/constants/constants.dart`:
```dart
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
```

### 4. Platform Configuration

#### iOS Setup
```bash
cd ios
pod install
cd ..
```

Edit `ios/Runner/Info.plist` to add location permissions:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location for ride services</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location for ride tracking</string>
```

#### Android Setup
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET"/>
```

### 5. Run the App
```bash
# Run on connected device or simulator
flutter run

# For specific platform
flutter run -d android
flutter run -d ios
```

## 🧪 Testing the Application

### As a Rider
1. Launch the app
2. Login with any email/password (demo mode)
3. Tap on map to set pickup location
4. Switch to "Destination" and tap to set destination
5. Click "Calculate Fare" to see route and fare estimate
6. Click "Request Ride" to broadcast request
7. Wait for driver acceptance (or run driver app simultaneously)
8. Track driver approaching on map
9. Start and complete trip

### As a Driver
1. Launch the app
2. Check "Login as Driver" checkbox
3. Login with any credentials
4. Toggle availability to "AVAILABLE"
5. Wait for ride requests to appear
6. Accept a ride request
7. Navigate to pickup location
8. Start and complete trip

## 📱 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1                    # State management
  go_router: ^14.0.2                  # Navigation
  google_maps_flutter: ^2.5.3        # Maps
  geolocator: ^11.0.0                # Location
  geocoding: ^3.0.0                  # Reverse geocoding
  flutter_polyline_points: ^2.0.1   # Route polylines
  http: ^1.2.0                       # API calls
  uuid: ^4.3.3                       # Unique IDs
  intl: ^0.19.0                      # Formatting
  permission_handler: ^11.2.0        # Permissions
```

## 🎨 Design Patterns

- **Provider Pattern** - State management across the app
- **Repository Pattern** - Data access abstraction
- **Service Layer** - Business logic separation
- **Clean Architecture** - Clear separation of concerns

## ⚙️ Configuration

### Fare Calculation
Edit `lib/core/constants/constants.dart`:
```dart
static const double baseFare = 2.5;
static const double perKmRate = 1.5;
static const double perMinuteRate = 0.3;
static const double bookingFee = 1.0;
```

### Mock Data
The app includes mock driver data. To modify:
- Edit `lib/data/repositories/driver_repository.dart`
- Adjust `_initializeMockDrivers()` method

## 🔧 Troubleshooting

### Google Maps not showing
- Verify API key is correctly set in both Android and iOS
- Ensure all required APIs are enabled in Google Cloud Console
- Check API key restrictions

### Location permissions not working
- Verify permissions are added to AndroidManifest.xml (Android)
- Verify permissions are added to Info.plist (iOS)
- Request permissions at runtime

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Notes

- This is a demo application with mock backend
- Real-time features are simulated
- For production, integrate with actual backend services
- Add Firebase for real-time database and push notifications
- Implement proper authentication system
- Add payment gateway integration

## 🚦 App Flow

1. **Splash Screen** → Check authentication
2. **Login Screen** → Authenticate user/driver
3. **Home Screen** (Rider) → Select locations
4. **Ride Request** → View fare and confirm
5. **User Tracking** → Track driver approaching
6. **Ride Status** → Trip in progress
7. **Driver Map** (Driver) → Receive and accept requests

## 🔐 Security Considerations

For production deployment:
- Implement proper authentication (Firebase Auth, OAuth)
- Secure API keys using environment variables
- Add backend validation for all requests
- Implement rate limiting
- Add SSL pinning
- Encrypt sensitive data

## 📞 Support

For issues or questions:
- Check existing issues
- Create new issue with details
- Provide logs and screenshots

## 📄 License

This project is a demonstration application for educational purposes.

---

**Built with Flutter 💙**

