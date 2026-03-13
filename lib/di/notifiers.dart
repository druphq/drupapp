// Provider instance
import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/features/passenger/provider/user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// User notifier
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((
  ref,
) {
  return UserNotifier(ref);
});

// Ride notifier
final rideNotifierProvider = StateNotifierProvider<RideNotifier, RideState>((
  ref,
) {
  return RideNotifier(ref);
});
