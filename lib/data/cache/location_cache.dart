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

// class HomeLocalSourceImpl extends HomeLocalSource {
//   @override
//   Future<bool> cacheAccount(AccountModel accountModel) async {
//     return await CacheManager.instance.storePref(
//       accountKey,
//       accountModel.toJson,
//     );
//   }

//   @override
//   Future<AccountModel?> getAccountModel() async {
//     final accountString =
//         await CacheManager.instance.getPref(accountKey) as String?;
//     if (accountString != null && accountString.isNotEmpty) {
//       return AccountModel.fromJson(accountString);
//     }
//     return null;
//   }

//   @override
//   Future<bool> cacheDynamicAccount(DynamicAccount dynamicAccount) async {
//     return await CacheManager.instance.storePref(
//       dynamicAccountKey,
//       dynamicAccount.toStringify,
//     );
//   }

//   @override
//   Future<DynamicAccount?> getDynamicAccount() async {
//     final dynamicAccountString =
//         await CacheManager.instance.getPref(dynamicAccountKey) as String?;
//     if (dynamicAccountString != null && dynamicAccountString.isNotEmpty) {
//       return DynamicAccount.fromJson(dynamicAccountString);
//     }
//     return null;
//   }

//   @override
//   Future<bool> clearAccount() async {
//     return await CacheManager.instance.storePref(accountKey, '');
//   }

//   @override
//   Future<bool> cacheNotifications(
//     List<NotificationInfoModel> notifications,
//   ) async {
//     final List<String> stringNotifications = [];
//     final cacheManager = CacheManager.instance;

//     for (final notificationData in notifications) {
//       stringNotifications.add(notificationData.toJson);
//     }

//     return await cacheManager.storePref(
//       notificationPrefKey,
//       stringNotifications,
//     );
//   }

//   @override
//   Future<List<NotificationInfoModel>> getCachedNotification() async {
//     final List<NotificationInfoModel> notificationsData = [];

//     final notificationsString = await CacheManager.instance.getPref(
//       notificationPrefKey,
//     );

//     if (notificationsString != null && notificationsString.isNotEmpty) {
//       for (final notification in notificationsString) {
//         notificationsData.add(NotificationInfoModel.fromJson(notification));
//       }
//     }
//     return notificationsData;
//   }
// }
