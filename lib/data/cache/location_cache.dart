import 'dart:convert';

import 'package:drup/core/cache/cache_manager.dart';
import 'package:drup/core/constants/constants.dart';

class LocationCache {
  
  static Future<bool> cachedAirports(
    List<Map<String, dynamic>> airports,
  ) async {
    final List<String> stringAirports = [];
    final cacheManager = CacheManager.instance;

    for (final airportData in airports) {
      stringAirports.add(json.encode(airportData));
    }
    return await cacheManager.storePref(
      AppConstants.airportsKey,
      stringAirports,
    );
  }

  static Future<List<Map<String, dynamic>>> getCachedAirports() async {
    final List<Map<String, dynamic>> airportsData = [];

    final airportsString = await CacheManager.instance.getPref(
      AppConstants.airportsKey,
    );

    if (airportsString != null && airportsString.isNotEmpty) {
      for (final airport in airportsString) {
        airportsData.add(json.decode(airport));
      }
    }
    return airportsData;
  }
}