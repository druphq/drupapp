class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String userType; // 'rider' or 'driver'
  final double rating;
  final int totalRides;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.userType,
    this.rating = 5.0,
    this.totalRides = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'userType': userType,
      'rating': rating,
      'totalRides': totalRides,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      photoUrl: json['photoUrl'] as String?,
      userType: json['userType'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: json['totalRides'] as int? ?? 0,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? userType,
    double? rating,
    int? totalRides,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
    );
  }
}
