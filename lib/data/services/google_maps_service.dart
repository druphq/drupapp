import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../core/constants/constants.dart';
import '../models/location_model.dart';

class GoogleMapsService {
  final String _apiKey = AppConstants.googleMapsApiKey;

  /// Get directions between two locations
  Future<Map<String, dynamic>?> getDirections(
    LocationModel origin,
    LocationModel destination,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          return {
            'distance': leg['distance']['value'] / 1000, // km
            'duration': leg['duration']['value'] / 60, // minutes
            'polylinePoints': route['overview_polyline']['points'],
            'startAddress': leg['start_address'],
            'endAddress': leg['end_address'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  /// Decode polyline to list of LatLng
  List<LatLng> decodePolyline(String encodedPolyline) {
    try {
      List<PointLatLng> result = PolylinePoints.decodePolyline(encodedPolyline);
      return result
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } catch (e) {
      print('Error decoding polyline: $e');
      return [];
    }
  }

  /// Get address from coordinates (Reverse Geocoding)
  Future<String?> getAddressFromCoordinates(LocationModel location) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}&'
        'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] as String;
        }
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  /// Search places by query
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=$query&'
        'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(
            data['results'].map(
              (place) => {
                'name': place['name'],
                'address': place['formatted_address'],
                'latitude': place['geometry']['location']['lat'],
                'longitude': place['geometry']['location']['lng'],
              },
            ),
          );
        }
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  /// Search for airports in Nigeria only
  Future<List<Map<String, dynamic>>> searchNigerianAirports(
    String query,
  ) async {
    try {
      // Add "airport Nigeria" to the query to ensure we get Nigerian airports
      final searchQuery = query.isEmpty
          ? 'airport Nigeria'
          : '$query airport Nigeria';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=${Uri.encodeComponent(searchQuery)}&'
        'type=airport&'
        'region=ng&'
        'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print(data);

        if (data['status'] == 'OK') {
          final results = List<Map<String, dynamic>>.from(
            data['results'].map(
              (place) => {
                'name': place['name'],
                'address': place['formatted_address'],
                'latitude': place['geometry']['location']['lat'],
                'longitude': place['geometry']['location']['lng'],
                'placeId': place['place_id'],
              },
            ),
          );
          return results;
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('Error searching Nigerian airports: $e\n$stackTrace');
      return [];
    }
  }

  /// Get route polyline points between two locations
  Future<List<LatLng>> getRoutePolyline(
    LocationModel origin,
    LocationModel destination,
  ) async {
    try {
      final directions = await getDirections(origin, destination);
      if (directions != null && directions['polylinePoints'] != null) {
        return decodePolyline(directions['polylinePoints']);
      }
      return [];
    } catch (e) {
      print('Error getting route polyline: $e');
      return [];
    }
  }
}
