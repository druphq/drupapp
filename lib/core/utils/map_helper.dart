import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MapHelper {
  /// Create custom marker for pickup location
  static Marker createPickupMarker(LatLng position, {String? id}) {
    return Marker(
      markerId: MarkerId(id ?? 'pickup'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Pickup Location'),
    );
  }

  /// Create custom marker for destination
  static Marker createDestinationMarker(LatLng position, {String? id}) {
    return Marker(
      markerId: MarkerId(id ?? 'destination'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destination'),
    );
  }

  /// Create custom marker for driver
  static Marker createDriverMarker(
    LatLng position,
    String driverId, {
    String? driverName,
    double? rotation,
  }) {
    return Marker(
      markerId: MarkerId('driver_$driverId'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: rotation ?? 0.0,
      infoWindow: InfoWindow(
        title: driverName ?? 'Driver',
        snippet: 'On the way',
      ),
    );
  }

  /// Create polyline for route
  static Polyline createRoutePolyline(
    List<LatLng> points, {
    String? id,
    Color? color,
    int? width,
  }) {
    return Polyline(
      polylineId: PolylineId(id ?? 'route'),
      points: points,
      color: color ?? AppColors.routeColor,
      width: width ?? 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
  }

  /// Calculate bounds for multiple coordinates
  static LatLngBounds calculateBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Animate camera to position
  static Future<void> animateCameraToPosition(
    GoogleMapController controller,
    LatLng position, {
    double zoom = 15.0,
  }) async {
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  /// Animate camera to bounds
  static Future<void> animateCameraToBounds(
    GoogleMapController controller,
    LatLngBounds bounds, {
    double padding = 100,
  }) async {
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  /// Get default map style (optional)
  static String? getMapStyle() {
    // You can return custom map style JSON here
    return null;
  }
}
