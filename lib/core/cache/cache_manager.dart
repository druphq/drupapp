import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

///* Storage Keys starting with `app_` (i.e. app_[key_name]) are termed
///* [App-wide] keys and must not be cleared on User actions within the
///* application, unless when manually cleared from Phone Setting, while
///* [User-based] keys are declared normally with no prefixes (i.e. [key_name])

class CacheManager {
  //Static variable as a single entrypoint to this class
  static final CacheManager instance = CacheManager._();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  ///private Constructor
  CacheManager._();

  ///SharedPreferences initializer
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('CacheManager initialization failed: $e');
      debugPrint('StackTrace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  ///Ensure initialization before any operation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _prefs == null) {
      await init();
    }
  }

  ///Storage Agent
  ///* Stores an entry with a given [key] and [value] in the persistent storage
  Future<bool> storePref(String key, dynamic value) async {
    try {
      if (key.trim().isEmpty) {
        debugPrint('CacheManager: Cannot store with empty key');
        return false;
      }

      await _ensureInitialized();

      if (value is String) {
        return await _prefs!.setString(key, value);
      } else if (value is int) {
        return await _prefs!.setInt(key, value);
      } else if (value is double) {
        return await _prefs!.setDouble(key, value);
      } else if (value is List<String>) {
        return await _prefs!.setStringList(key, value);
      } else if (value is bool) {
        return await _prefs!.setBool(key, value);
      } else {
        debugPrint(
          'CacheManager: Unsupported type for key $key: ${value.runtimeType}',
        );
        throw FormatException('Unsupported type: ${value.runtimeType}');
      }
    } catch (e, stackTrace) {
      debugPrint('CacheManager: Error storing $key: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  ///Value Retriever
  ///* Retrieves an entry with the given [key] from persistent storage
  Future<dynamic> getPref(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.get(key);
    } catch (e, stackTrace) {
      debugPrint('CacheManager: Error getting $key: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }

  ///Typed value retrievers for better type safety
  Future<String?> getString(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.getString(key);
    } catch (e) {
      debugPrint('CacheManager: Error getting string $key: $e');
      return null;
    }
  }

  Future<int?> getInt(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.getInt(key);
    } catch (e) {
      debugPrint('CacheManager: Error getting int $key: $e');
      return null;
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.getBool(key);
    } catch (e) {
      debugPrint('CacheManager: Error getting bool $key: $e');
      return null;
    }
  }

  Future<double?> getDouble(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.getDouble(key);
    } catch (e) {
      debugPrint('CacheManager: Error getting double $key: $e');
      return null;
    }
  }

  Future<List<String>?> getStringList(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.getStringList(key);
    } catch (e) {
      debugPrint('CacheManager: Error getting string list $key: $e');
      return null;
    }
  }

  ///Remove all entries from persistent storage that are not [app-wide]
  Future<bool> clearPrefs() async {
    try {
      await _ensureInitialized();

      final keys = _prefs!.getKeys();
      final keysToRemove = keys
          .where((key) => !key.startsWith('app_'))
          .toList();

      for (final key in keysToRemove) {
        await _prefs!.remove(key);
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('CacheManager: Error clearing prefs: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  ///Remove an entry with [key] from persistent storage
  ///that is not [app-wide]
  Future<bool> clearPref(String key) async {
    try {
      await _ensureInitialized();

      //Check whether key is [App-wide] or [User-based]
      if (key.startsWith('app_')) {
        debugPrint('CacheManager: Cannot clear app-wide key: $key');
        return false;
      }

      return await _prefs!.remove(key);
    } catch (e, stackTrace) {
      debugPrint('CacheManager: Error clearing pref $key: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Removes all preferences for this app from persistent storage
  Future<bool> clearCache() async {
    try {
      await _ensureInitialized();
      return await _prefs!.clear();
    } catch (e, stackTrace) {
      debugPrint('CacheManager: Error clearing cache: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  Future<bool> checkPref(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.containsKey(key);
    } catch (e, stackTrace) {
      debugPrint('CacheManager: Error checking pref $key: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  Future<dynamic> readPrefFromObject(String key1, String key2) async {
    try {
      if (await checkPref(key1)) {
        final jsonString = _prefs!.getString(key1);

        if (jsonString == null) {
          return null;
        }

        final decodedObject = json.decode(jsonString);

        if (decodedObject is Map && decodedObject.containsKey(key2)) {
          return decodedObject[key2];
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('CacheManager: Error reading object $key1.$key2: $e');
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }
}
