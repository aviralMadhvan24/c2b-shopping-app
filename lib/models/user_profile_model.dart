class UserProfile {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final String? defaultAddressId;

  const UserProfile({
    required this.id,
    required this.createdAt,
    this.name,
    this.email,
    this.phone,
    this.defaultAddressId,
  });

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'defaultAddressId': defaultAddressId,
    };
  }

  factory UserProfile.fromMap(String id, Map<String, Object?> map) {
    return UserProfile(
      id: id,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      defaultAddressId: map['defaultAddressId'] as String?,
    );
  }
}
