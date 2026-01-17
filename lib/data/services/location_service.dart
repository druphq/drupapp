import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get location details (name + address)
      final details = await _getLocationDetails(
        position.latitude,
        position.longitude,
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        name: details['name'],
        address: details['address'],
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

  /// Get location details (name + address) from coordinates
  Future<Map<String, String?>> _getLocationDetails(
    double lat,
    double lng,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Name: Use the most specific available
        String? name = place.name ?? place.street ?? place.subLocality;

        // Address: Build formatted address
        String? address = [
          place.street,
          place.subLocality,
          place.locality,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        return {'name': name, 'address': address.isNotEmpty ? address : null};
      }
      return {'name': null, 'address': null};
    } catch (e) {
      print('Error getting location details: $e');
      return {'name': null, 'address': null};
    }
  }

  void dispose() {
    stopLocationTracking();
  }
}
