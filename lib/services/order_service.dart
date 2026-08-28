import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import '../models/cart_item_model.dart';
import '../models/customer_order.dart';

/// Service for managing orders with COD payment in Firestore.
///
/// Firestore collection: orders/{orderId}
class OrderService {
  final FirebaseFirestore _firestore;

  OrderService({required FirebaseFirestore firestore}) : _firestore = firestore;

  /// The free delivery threshold in INR.
  static const double freeDeliveryThreshold = 499.0;

  /// The delivery fee when subtotal is below threshold.
  static const double standardDeliveryFee = 40.0;

  /// Places a new order with COD payment.
  ///
  /// Calculates delivery fee: ₹0 if subtotal >= 499, else ₹40.
  /// Generates order number: NM + last 8 digits of timestamp.
  Future<CustomerOrder> placeOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required List<CartItem> cartItems,
    required Address deliveryAddress,
  }) async {
    // Calculate subtotal from cart items
    final subtotal = cartItems.fold<double>(
      0,
      (total, item) => total + (item.price * item.quantity),
    );

    // Calculate delivery fee
    final deliveryFee =
        subtotal >= freeDeliveryThreshold ? 0.0 : standardDeliveryFee;

    final total = subtotal + deliveryFee;

    // Generate order ID: NM + last 8 digits of timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final orderNumber = 'NM${timestamp.substring(timestamp.length - 8)}';

    // Format delivery address string
    final formattedAddress = _formatAddress(deliveryAddress);

    // Convert cart items to order items
    final orderItems = cartItems.map((cartItem) {
      return OrderItem(
        productId: cartItem.productId,
        productName: cartItem.productName,
        productImage: cartItem.productImage,
        price: cartItem.price,
        quantity: cartItem.quantity,
        lineTotal: cartItem.price * cartItem.quantity,
      );
    }).toList();

    final now = DateTime.now();

    final order = CustomerOrder(
      id: orderNumber,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      deliveryAddressId: deliveryAddress.id,
      deliveryAddress: formattedAddress,
      status: OrderStatus.placed,
      paymentMethod: 'COD',
      createdAt: now,
    );

    // Write to Firestore
    await _firestore.collection('orders').doc(orderNumber).set(order.toMap());

    return order;
  }

  /// Gets real-time order status stream.
  Stream<CustomerOrder> watchOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .where((snapshot) => snapshot.exists)
        .map((snapshot) =>
            CustomerOrder.fromMap(snapshot.id, snapshot.data()!));
  }

  /// Gets all orders for a user, ordered by creation date descending.
  Stream<List<CustomerOrder>> watchUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Cancels an order (only if status is 'placed' or 'confirmed').
  ///
  /// Throws if order cannot be cancelled.
  Future<void> cancelOrder(String orderId, String reason) async {
    final docRef = _firestore.collection('orders').doc(orderId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Order not found');
    }

    final currentStatus = snapshot.data()!['status'] as String;

    if (currentStatus != OrderStatus.placed.name &&
        currentStatus != OrderStatus.confirmed.name) {
      throw Exception(
          'Order cannot be cancelled. Current status: $currentStatus');
    }

    await docRef.update({
      'status': OrderStatus.cancelled.name,
      'cancelReason': reason,
    });
  }

  /// Formats an Address into a readable string.
  String _formatAddress(Address address) {
    final parts = <String>[
      address.line1,
      if (address.line2 != null && address.line2!.isNotEmpty) address.line2!,
      '${address.city}, ${address.state} ${address.postalCode}',
      address.country,
    ];
    return parts.join(', ');
  }
}

/// Riverpod provider for OrderService.
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(firestore: FirebaseFirestore.instance);
});
