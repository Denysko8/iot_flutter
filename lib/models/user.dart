class User {
  final String name;
  final String email;
  final String password;

  const User({
    required this.name,
    required this.email,
    required this.password,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? password,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
