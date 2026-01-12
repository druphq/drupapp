import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Calculate bearing between two coordinates
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  /// Generate a random location within a radius (in km)
  static Map<String, double> getRandomLocationNearby(
    double centerLat,
    double centerLng,
    double radiusInKm,
  ) {
    final random = Random();

    // Convert radius from kilometers to degrees
    final radiusInDegrees = radiusInKm / 111.0;

    final u = random.nextDouble();
    final v = random.nextDouble();

    final w = radiusInDegrees * sqrt(u);
    final t = 2 * pi * v;

    final x = w * cos(t);
    final y = w * sin(t);

    final newLat = x + centerLat;
    final newLng = y + centerLng;

    return {'latitude': newLat, 'longitude': newLng};
  }

  /// Interpolate position between two points
  static Map<String, double> interpolatePosition(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double fraction,
  ) {
    return {
      'latitude': lat1 + (lat2 - lat1) * fraction,
      'longitude': lon1 + (lon2 - lon1) * fraction,
    };
  }

  /// Estimate time to reach destination (in minutes)
  static int estimateTravelTime(double distanceKm, double speedKmH) {
    return (distanceKm / speedKmH * 60).ceil();
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Format duration for display
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }
}
