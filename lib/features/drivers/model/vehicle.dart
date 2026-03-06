/// Vehicle model matching the API response structure
class Vehicle {
  final String? type;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final String? licensePlate;
  final bool isVerified;
  final List<String> photos;

  Vehicle({
    this.type,
    this.make,
    this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.isVerified = false,
    this.photos = const [],
  });

  /// Display string: "Toyota Corolla" or "Unknown Vehicle"
  String get displayName {
    if (make != null && model != null) return '$make $model';
    if (make != null) return make!;
    return 'Unknown Vehicle';
  }

  /// Display string: "White Toyota Corolla 2021"
  String get fullDisplayName {
    final parts = <String>[];
    if (color != null) parts.add(color!);
    if (make != null) parts.add(make!);
    if (model != null) parts.add(model!);
    if (year != null) parts.add(year.toString());
    return parts.isNotEmpty ? parts.join(' ') : 'Unknown Vehicle';
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'isVerified': isVerified,
      'photos': photos,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      type: json['type'] as String?,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      color: json['color'] as String?,
      licensePlate: json['licensePlate'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Vehicle copyWith({
    String? type,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    bool? isVerified,
    List<String>? photos,
  }) {
    return Vehicle(
      type: type ?? this.type,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      isVerified: isVerified ?? this.isVerified,
      photos: photos ?? this.photos,
    );
  }

  @override
  String toString() => 'Vehicle($fullDisplayName, plate: $licensePlate)';
}
