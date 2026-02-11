import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      name: json['name'] as String?,
      address: json['address'] as String?,
    );
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? name,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, name, address];
}
