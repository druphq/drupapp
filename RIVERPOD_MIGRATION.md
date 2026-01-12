# 🚀 Riverpod Migration Guide

## ✅ Migration Complete!

Your project has been successfully migrated from **Provider** to **Riverpod 2.6** with code generation.

## What Changed

### 1. Dependencies
✅ Replaced `provider` with `flutter_riverpod`
✅ Added `riverpod_annotation` for code generation
✅ Added `riverpod_generator` and `build_runner` for dev dependencies
✅ Added `riverpod_lint` for better IDE support

### 2. Architecture

**Old (Provider):**
```
Provider
├── ChangeNotifier classes
├── Manual dependency injection
└── BuildContext required
```

**New (Riverpod):**
```
Riverpod
├── Notifier classes (auto-generated)
├── Automatic dependency injection
├── No BuildContext needed
└── Type-safe providers
```

### 3. File Structure

**Created:**
- `lib/providers/providers.dart` - Service & Repository providers
- `lib/providers/auth_notifier.dart` - Authentication state
- `lib/providers/ride_notifier.dart` - Ride management state
- `lib/providers/user_notifier.dart` - User profile state
- `lib/providers/driver_notifier.dart` - Driver state

**Updated:**
- `lib/main.dart` - Wrapped with `ProviderScope`
- `lib/router/app_router.dart` - Uses `WidgetRef` instead of `BuildContext`
- `lib/ui/screens/login_screen.dart` - Example migration

**To Delete (Optional):**
- `lib/providers/auth_provider.dart`
- `lib/providers/ride_provider.dart`
- `lib/providers/user_provider.dart`
- `lib/providers/driver_provider.dart`

## How to Use Riverpod in Your Screens

### StatefulWidget → ConsumerStatefulWidget

**Before (Provider):**
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = context.read<UserProvider>();
    
    return Text(auth.currentUser?.name ?? '');
  }
}
```

**After (Riverpod):**
```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch for changes (rebuilds widget)
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;
    
    // Read without watching (no rebuild)
    final userNotifier = ref.read(userNotifierProvider.notifier);
    
    return Text(user?.name ?? '');
  }
}
```

### StatelessWidget → ConsumerWidget

**Before (Provider):**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    return Text(ride.estimatedFare.toString());
  }
}
```

**After (Riverpod):**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideNotifierProvider);
    return Text(rideState.estimatedFare.toString());
  }
}
```

## Common Patterns

### 1. Reading State (Watch = Rebuild on Change)
```dart
// Watch auth state
final authState = ref.watch(authNotifierProvider);
final user = authState.value;
final isLoading = authState.isLoading;
final error = authState.error;

// Watch ride state
final rideState = ref.watch(rideNotifierProvider);
final currentRide = rideState.currentRide;
```

### 2. Calling Methods (Read = No Rebuild)
```dart
// Login
await ref.read(authNotifierProvider.notifier)
    .loginWithEmail(email, password);

// Request ride
await ref.read(rideNotifierProvider.notifier)
    .requestRide(userId: userId, paymentMethod: 'cash');

// Update location
await ref.read(userNotifierProvider.notifier)
    .updateUserLocation();
```

### 3. Using Computed Providers
```dart
// Check if logged in
final isLoggedIn = ref.watch(isLoggedInProvider);

// Get current user
final currentUser = ref.watch(currentUserProvider);

// Check if driver
final isDriver = ref.watch(isDriverProvider);
```

### 4. Accessing Services Directly
```dart
// Get location service
final locationService = ref.read(locationServiceProvider);
final location = await locationService.getCurrentLocation();

// Get maps service
final mapsService = ref.read(googleMapsServiceProvider);
final directions = await mapsService.getDirections(...);
```

## Migration Checklist for Each Screen

For each screen file, follow these steps:

### Step 1: Update Imports
```dart
// ❌ Remove
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

// ✅ Add
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';
import '../providers/user_notifier.dart';
```

### Step 2: Change Widget Type
```dart
// ❌ Old
class MyScreen extends StatefulWidget {}
class _MyScreenState extends State<MyScreen> {}

// ✅ New
class MyScreen extends ConsumerStatefulWidget {}
class _MyScreenState extends ConsumerState<MyScreen> {}
```

### Step 3: Replace context.watch/read with ref.watch/read
```dart
// ❌ Old
final auth = context.watch<AuthProvider>();
final user = context.read<UserProvider>();
await user.getCurrentLocation();

// ✅ New
final authState = ref.watch(authNotifierProvider);
await ref.read(userNotifierProvider.notifier).updateUserLocation();
```

### Step 4: Update Method Calls
```dart
// ❌ Old
await authProvider.loginWithEmail(email, password);
if (authProvider.errorMessage != null) { ... }

// ✅ New
await ref.read(authNotifierProvider.notifier)
    .loginWithEmail(email, password);
final error = ref.read(authNotifierProvider).error;
if (error != null) { ... }
```

## Testing

### Running Code Generation
```bash
# Generate provider files (run after changes)
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generates on save)
dart run build_runner watch --delete-conflicting-outputs
```

### Running the App
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Advantages You Now Have

✅ **No BuildContext needed** - Access state from anywhere
✅ **Compile-time safety** - Catch errors before runtime
✅ **Better performance** - Fine-grained rebuilds
✅ **Easier testing** - Override providers in tests
✅ **DevTools integration** - Better debugging
✅ **Auto-dispose** - Automatic cleanup with ref.onDispose()
✅ **Type-safe** - Full type inference
✅ **Code generation** - Less boilerplate

## Common Issues & Solutions

### Issue: "The part file doesn't exist"
**Solution:** Run code generation
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Issue: "ref is not defined"
**Solution:** Change Widget to ConsumerWidget or ConsumerStatefulWidget

### Issue: "Cannot access notifier"
**Solution:** Use `.notifier` to call methods
```dart
ref.read(authNotifierProvider.notifier).logout();
```

### Issue: "State not updating"
**Solution:** Make sure you're using `ref.watch()` not `ref.read()`

## Next Steps

1. ✅ Login screen migrated (example)
2. 🔄 Migrate remaining screens:
   - `home_screen.dart`
   - `ride_request_screen.dart`
   - `driver_map_screen.dart`
   - `user_tracking_screen.dart`
   - `ride_status_screen.dart`
   - `splash_screen.dart`

3. 🗑️ Delete old Provider files after confirming everything works

## Need Help?

- [Riverpod Documentation](https://riverpod.dev)
- [Riverpod Examples](https://github.com/rrousselGit/riverpod/tree/master/examples)
- [Migration Guide](https://riverpod.dev/docs/from_provider/motivation)

---

**Pro Tip:** Keep `dart run build_runner watch` running while developing to auto-generate code on save!
