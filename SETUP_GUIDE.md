# Quick Setup Guide - RideShare App

## 🚀 Quick Start (5 Minutes)

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Get Google Maps API Key

1. Go to: https://console.cloud.google.com/
2. Create a new project
3. Enable these APIs:
   - Maps SDK for Android: 
   - Maps SDK for iOS: 
   - Directions API
   - Places API
   - Geocoding API
4. Create API Key

### Step 3: Configure API Key

**Update App Code:**
Edit `lib/core/constants/constants.dart`:
```dart
static const String googleMapsApiKey = 'YOUR_API_KEY_HERE';
```

**For Android:**
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**For iOS:**
Edit `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyBhAsnf51Xiy--EkHLmv2jsBuWeGA3yPEE")
```

### Step 4: Run the App
```bash
flutter run
```

## 📱 Testing the App

### Test as Rider:
1. Login with any email (e.g., `test@example.com` / `password`)
2. Tap on map to select pickup location
3. Switch to "Destination" tab and tap again
4. Click "Calculate Fare"
5. Click "Request Ride"
6. View live tracking

### Test as Driver:
1. Check "Login as Driver" on login screen
2. Login with any credentials
3. Toggle availability to "AVAILABLE"
4. Accept incoming ride requests
5. Complete the trip

## ⚙️ Platform-Specific Setup

### iOS Additional Steps:
```bash
cd ios
pod install
cd ..
```

Edit `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location for ride services</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location for tracking</string>
```

### Android Permissions:
Already configured in `AndroidManifest.xml`:
- ✅ Internet permission
- ✅ Fine location permission
- ✅ Coarse location permission

## 🔧 Troubleshooting

### Issue: "Google Maps not loading"
**Solution:** 
- Verify API key is correctly set
- Check all required APIs are enabled
- Wait 5 minutes after enabling APIs

### Issue: "Location permission denied"
**Solution:**
- Check device settings
- Allow location permissions
- Restart the app

### Issue: "Build fails"
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Key Features to Test

✅ Google Maps rendering
✅ Location selection
✅ Route calculation with polyline
✅ Fare estimation
✅ Ride request flow
✅ Driver-side request acceptance
✅ Live location updates (simulated)
✅ Trip completion flow

## 🎯 Demo Credentials

**Any email/password works!** This is a demo app.

Examples:
- Rider: `rider@test.com` / `password`
- Driver: `driver@test.com` / `password` (check "Login as Driver")

## 📊 App Architecture

```
Provider Pattern → State Management
GoRouter → Navigation
Clean Architecture → Code Organization
Mock Services → Backend simulation
```

## 🔗 Important Files

- **Constants:** `lib/core/constants/constants.dart`
- **Main Entry:** `lib/main.dart`
- **Home Screen:** `lib/ui/screens/home_screen.dart`
- **Driver Screen:** `lib/ui/screens/driver_map_screen.dart`

## 💡 Tips

1. **Run two devices/emulators** to test rider and driver simultaneously
2. **Mock data** - 5 drivers are pre-initialized near San Francisco
3. **Location simulation** - Driver movement is simulated for testing
4. **No backend required** - Everything runs locally

## 🎨 Customization

### Change Colors:
Edit `lib/core/theme/app_colors.dart`

### Change Fare Rates:
Edit `lib/core/constants/constants.dart`
```dart
static const double baseFare = 2.5;
static const double perKmRate = 1.5;
```

### Change Mock Drivers:
Edit `lib/data/repositories/driver_repository.dart`

## ✅ Final Checklist

- [ ] Flutter installed
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Google Maps API key obtained
- [ ] API key configured in 3 places
- [ ] iOS pods installed (if testing on iOS)
- [ ] Location permissions granted on device
- [ ] App runs successfully

## 📞 Need Help?

Check the full README.md for detailed documentation.

---

**Ready to ride! 🚗💨**
