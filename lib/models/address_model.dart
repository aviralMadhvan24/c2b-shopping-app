class Address {
  final String id;
  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  const Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.line1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.line2,
    this.isDefault = false,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(String id, Map<String, Object?> map) {
    return Address(
      id: id,
      name: map['name'] as String,
      phone: map['phone'] as String,
      line1: map['line1'] as String,
      line2: map['line2'] as String?,
      city: map['city'] as String,
      state: map['state'] as String,
      postalCode: map['postalCode'] as String,
      country: map['country'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.line1 == line1 &&
        other.line2 == line2 &&
        other.city == city &&
        other.state == state &&
        other.postalCode == postalCode &&
        other.country == country &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(
      id, name, phone, line1, line2, city, state, postalCode, country, isDefault,
    );
  }
}
