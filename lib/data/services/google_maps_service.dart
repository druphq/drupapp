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

  /// Get detailed location info (name + address) from coordinates
  Future<Map<String, String?>> getLocationDetails(
    LocationModel location,
  ) async {
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
          final result = data['results'][0];

          // Get the name (first address component or point of interest)
          String? name;
          if (result['address_components'] != null &&
              result['address_components'].isNotEmpty) {
            name = result['address_components'][0]['long_name'];
          }

          // Get formatted address
          String? address = result['formatted_address'];

          return {'name': name, 'address': address};
        }
      }
      return {'name': null, 'address': null};
    } catch (e) {
      print('Error getting location details: $e');
      return {'name': null, 'address': null};
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
  Future<List<Map<String, dynamic>>> searchNigerianAddresses(
    String query,
  ) async {
    try {
      // Add "Nigeria" to the query to ensure we get Nigerian addresses
      final searchQuery = query.isEmpty ? 'Nigeria' : '$query Nigeria';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=${Uri.encodeComponent(searchQuery)}&'
        'region=ng&'
        'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Limit to 5 results and extract only place IDs
          final placeIds = (data['results'] as List)
              .take(5)
              .map((place) => place['place_id'] as String)
              .toList();

          // Fetch all place details concurrently
          final detailsFutures = placeIds.map(
            (placeId) => _getPlaceDetails(placeId),
          );
          final detailsResults = await Future.wait(detailsFutures);

          // Filter out null results and return
          return detailsResults
              .where((details) => details != null)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('Error searching Nigerian addresses: $e\n$stackTrace');
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

        if (data['status'] == 'OK') {
          // Limit to 5 results and extract only place IDs
          final placeIds = (data['results'] as List)
              .take(5)
              .map((place) => place['place_id'] as String)
              .toList();

          // Fetch all place details concurrently
          final detailsFutures = placeIds.map(
            (placeId) => _getPlaceDetails(placeId),
          );
          final detailsResults = await Future.wait(detailsFutures);

          // Filter out null results and return
          return detailsResults
              .where((details) => details != null)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('Error searching Nigerian airports: $e\n$stackTrace');
      return [];
    }
  }

  /// Load all Nigerian airports
  Future<List<Map<String, dynamic>>> loadNigerianAirports() async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=${Uri.encodeComponent('airport Nigeria')}&'
        'type=airport&'
        'region=ng&'
        'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Get all place IDs
          final placeIds = (data['results'] as List)
              .map((place) => place['place_id'] as String)
              .toList();

          // Fetch all place details concurrently
          final detailsFutures = placeIds.map(
            (placeId) => _getPlaceDetails(placeId),
          );
          final detailsResults = await Future.wait(detailsFutures);

          // Filter out null results and return
          return detailsResults
              .where((details) => details != null)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }

      return [];
    } catch (e, stackTrace) {
      debugPrint('Error loading Nigerian airports: $e\n$stackTrace');
      return [];
    }
  }

  /// Get detailed information for a place using Place Details API
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&'
        'fields=name,address_components,geometry&'
        'key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final addressComponents = result['address_components'] as List;
          final normalizedAddress = normalizeAddressComponents(
            addressComponents,
          );

          return {
            'name': result['name'],
            'address': normalizedAddress,
            'latitude': result['geometry']['location']['lat'],
            'longitude': result['geometry']['location']['lng'],
            'placeId': placeId,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching place details for $placeId: $e');
      return null;
    }
  }

  /// Normalize address components to a clean format
  String normalizeAddressComponents(List components) {
    String? city;
    String? state;
    String? country;

    for (final c in components) {
      final types = List<String>.from(c['types']);

      if (types.contains('locality')) {
        city = c['long_name'];
      } else if (types.contains('administrative_area_level_1')) {
        state = c['long_name'];
      } else if (types.contains('country')) {
        country = c['long_name'];
      }
    }

    // Priority order:
    // City, Country
    if (city != null && country != null) {
      return '$city, $country';
    }

    // State, Country
    if (state != null && country != null) {
      return '$state, $country';
    }

    // City only
    if (city != null) return city;

    // State only
    if (state != null) return state;

    // Country only
    if (country != null) return country;

    return '';
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

 

