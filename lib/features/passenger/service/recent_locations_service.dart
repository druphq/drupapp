import 'dart:convert';
import '../../../core/cache/cache_manager.dart';
import '../model/location_model.dart';

/// Service to cache and retrieve recent locations
class RecentLocationsService {
  static const String _cacheKey = 'recent_locations';
  static const int _maxRecentLocations = 5;

  final CacheManager _cacheManager;

  RecentLocationsService(this._cacheManager);

  /// Get recent locations from cache
  Future<List<LocationModel>> getRecentLocations() async {
    try {
      final jsonString = await _cacheManager.getString(_cacheKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => LocationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a location to recent locations cache
  /// Adds to the beginning of the list and removes duplicates
  Future<void> addRecentLocation(LocationModel location) async {
    try {
      final recentLocations = await getRecentLocations();

      // Remove duplicate if exists (same coordinates)
      recentLocations.removeWhere(
        (loc) =>
            loc.latitude == location.latitude &&
            loc.longitude == location.longitude,
      );

      // Add new location at the beginning
      recentLocations.insert(0, location);

      // Keep only the most recent locations
      final trimmedList = recentLocations.take(_maxRecentLocations).toList();

      // Save to cache
      final jsonString = json.encode(
        trimmedList.map((loc) => loc.toJson()).toList(),
      );
      await _cacheManager.storePref(_cacheKey, jsonString);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Clear all recent locations
  Future<void> clearRecentLocations() async {
    await _cacheManager.clearPref(_cacheKey);
  }
}
