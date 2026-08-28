import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/store_order.dart';

/// Reads every order in the store and drives its fulfilment status.
///
/// The customer app can only ever read its own orders and cancel them; moving
/// an order along the pipeline is the console's job, matched by the Firestore
/// rules.
class OrderService {
  final FirebaseFirestore _firestore;

  OrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  /// Recent orders, newest first. [limit] keeps the console responsive on a
  /// store with a long history; the Orders screen raises it on demand.
  Stream<List<StoreOrder>> watchRecent({int limit = 200}) {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => StoreOrder.fromMap(d.id, d.data())).toList());
  }

  Stream<StoreOrder?> watchOne(String id) => _orders.doc(id).snapshots().map(
        (d) => d.exists ? StoreOrder.fromMap(d.id, d.data()!) : null,
      );

  /// Advances (or corrects) an order's status, stamping the matching
  /// timestamp so the customer app's tracking screen has something to show.
  ///
  /// The stamp is only written when it is missing, so re-selecting a status
  /// the order already passed through — correcting a misclick — does not
  /// rewrite history the customer already saw.
  Future<void> updateStatus(
    StoreOrder order,
    OrderStatus status, {
    String? cancelReason,
  }) async {
    final updates = <String, dynamic>{'status': status.name};

    String? stampField = switch (status) {
      OrderStatus.confirmed => 'confirmedAt',
      OrderStatus.packed => 'packedAt',
      OrderStatus.outForDelivery => 'outForDeliveryAt',
      OrderStatus.delivered => 'deliveredAt',
      OrderStatus.placed || OrderStatus.cancelled => null,
    };

    if (stampField != null && order.timestampFor(status) == null) {
      updates[stampField] = FieldValue.serverTimestamp();
    }

    if (status == OrderStatus.cancelled) {
      updates['cancelReason'] =
          (cancelReason == null || cancelReason.trim().isEmpty)
              ? 'Cancelled by store'
              : cancelReason.trim();
    }

    await _orders.doc(order.id).update(updates);
  }

  /// Attaches the delivery contact the customer sees while tracking.
  Future<void> assignDelivery({
    required String orderId,
    required String name,
    required String phone,
  }) {
    return _orders.doc(orderId).update({
      'deliveryPersonName': name.trim().isEmpty ? null : name.trim(),
      'deliveryPersonPhone': phone.trim().isEmpty ? null : phone.trim(),
    });
  }

  /// Every order a single customer has placed, for the customer detail view.
  Future<List<StoreOrder>> fetchForUser(String userId) async {
    final snap = await _orders
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => StoreOrder.fromMap(d.id, d.data())).toList();
  }
}
