import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';
import '../models/store_order.dart';

/// Reads the shopper list from `users` and enriches it with spend figures
/// derived from `orders`.
///
/// Spend is computed here rather than denormalised onto the user document,
/// because the console already streams the order list for the dashboard —
/// joining in memory keeps the numbers exact and costs no extra reads.
class CustomerService {
  final FirebaseFirestore _firestore;

  CustomerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<List<Customer>> watchAll() {
    return _users.snapshots().map(
          (snap) =>
              snap.docs.map((d) => Customer.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Joins customers to their orders. Cancelled orders are excluded from
  /// lifetime value — money that was never collected is not revenue — but
  /// still count toward [Customer.orderCount] so the history reads honestly.
  static List<Customer> withOrderStats(
    List<Customer> customers,
    List<StoreOrder> orders,
  ) {
    final byUser = <String, List<StoreOrder>>{};
    for (final order in orders) {
      byUser.putIfAbsent(order.userId, () => []).add(order);
    }

    final enriched = customers.map((customer) {
      final theirs = byUser[customer.id] ?? const <StoreOrder>[];
      final spend = theirs
          .where((o) => o.status != OrderStatus.cancelled)
          .fold<double>(0, (total, o) => total + o.total);
      DateTime? last;
      for (final o in theirs) {
        if (last == null || o.createdAt.isAfter(last)) last = o.createdAt;
      }
      return customer.withOrderStats(
        orderCount: theirs.length,
        lifetimeValue: spend,
        lastOrderAt: last,
      );
    }).toList();

    enriched.sort((a, b) {
      // Paying customers first, then by how much they have spent; everyone
      // who has never ordered falls to the bottom, alphabetically.
      final byValue = b.lifetimeValue.compareTo(a.lifetimeValue);
      if (byValue != 0) return byValue;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return enriched;
  }
}
