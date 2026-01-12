import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude, 'address': address};
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String?,
    );
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }
}
