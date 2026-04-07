class User {
  final String name;
  final String email;
  final String password;
  final String? city;
  final double? latitude;
  final double? longitude;

  const User({
    required this.name,
    required this.email,
    required this.password,
    this.city,
    this.latitude,
    this.longitude,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      city: map['city'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? password,
    String? city,
    double? latitude,
    double? longitude,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
