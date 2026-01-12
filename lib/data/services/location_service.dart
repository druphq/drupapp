import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/location_model.dart';

class LocationService {
  StreamController<LocationModel>? _locationController;

  /// Get location permission status
  Future<bool> hasPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current location
  Future<LocationModel?> getCurrentLocation() async {
    try {
      bool hasPerms = await hasPermission();
      if (!hasPerms) {
        hasPerms = await requestPermission();
        if (!hasPerms) return null;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start location tracking stream
  Stream<LocationModel> startLocationTracking() {
    _locationController = StreamController<LocationModel>.broadcast();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final location = LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _locationController?.add(location);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );

    return _locationController!.stream;
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _locationController?.close();
    _locationController = null;
  }

  /// Get location stream (if active)
  Stream<LocationModel>? get locationStream => _locationController?.stream;

  /// Calculate distance between two locations (in kilometers)
  double calculateDistance(LocationModel from, LocationModel to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000;
  }

  /// Calculate bearing between two locations
  double calculateBearing(LocationModel from, LocationModel to) {
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  void dispose() {
    stopLocationTracking();
  }
}
