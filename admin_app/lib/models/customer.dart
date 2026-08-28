/// A shopper, read from `users/{uid}` — the profile the customer app writes at
/// sign-up. The console never edits these documents; it only reads them, so
/// there is no `toMap`.
class Customer {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final DateTime? createdAt;

  // Filled in by CustomerService from the orders collection, because the user
  // document itself knows nothing about spending.
  final int orderCount;
  final double lifetimeValue;
  final DateTime? lastOrderAt;

  const Customer({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.createdAt,
    this.orderCount = 0,
    this.lifetimeValue = 0,
    this.lastOrderAt,
  });

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e.split('@').first;
    return 'Customer';
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final n = displayName;
    return (n.length >= 2 ? n.substring(0, 2) : n).toUpperCase();
  }

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    // The customer app stores createdAt as an ISO-8601 string, not a
    // Timestamp — parse defensively so one odd document cannot blank the list.
    DateTime? created;
    final raw = map['createdAt'];
    if (raw is String) created = DateTime.tryParse(raw);

    return Customer(
      id: id,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      createdAt: created,
    );
  }

  Customer withOrderStats({
    required int orderCount,
    required double lifetimeValue,
    DateTime? lastOrderAt,
  }) =>
      Customer(
        id: id,
        name: name,
        email: email,
        phone: phone,
        createdAt: createdAt,
        orderCount: orderCount,
        lifetimeValue: lifetimeValue,
        lastOrderAt: lastOrderAt,
      );
}
