import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

/// Mirrors the customer app's `OrderStatus`. The `name` of each value is what
/// is written to Firestore, so the two enums must stay in the same spelling.
enum OrderStatus {
  placed,
  confirmed,
  packed,
  outForDelivery,
  delivered,
  cancelled;

  String get label => switch (this) {
        OrderStatus.placed => 'Placed',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.packed => 'Packed',
        OrderStatus.outForDelivery => 'Out for delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        OrderStatus.placed => AdminColors.orange,
        OrderStatus.confirmed => AdminColors.primaryLight,
        OrderStatus.packed => AdminColors.purple,
        OrderStatus.outForDelivery => AdminColors.teal,
        OrderStatus.delivered => AdminColors.success,
        OrderStatus.cancelled => AdminColors.danger,
      };

  Color get softColor => switch (this) {
        OrderStatus.placed => AdminColors.orangeSoft,
        OrderStatus.confirmed => AdminColors.primarySoft,
        OrderStatus.packed => AdminColors.purpleSoft,
        OrderStatus.outForDelivery => AdminColors.tealSoft,
        OrderStatus.delivered => AdminColors.successSoft,
        OrderStatus.cancelled => AdminColors.dangerSoft,
      };

  IconData get icon => switch (this) {
        OrderStatus.placed => Icons.receipt_long_outlined,
        OrderStatus.confirmed => Icons.check_circle_outline,
        OrderStatus.packed => Icons.inventory_2_outlined,
        OrderStatus.outForDelivery => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.task_alt,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  /// The fulfilment ladder, in the order the shop works through it.
  /// `cancelled` is deliberately absent: it is a jump off the ladder, offered
  /// as a separate destructive action rather than a "next step".
  static const List<OrderStatus> pipeline = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.packed,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  /// The single status the shop would move this order to next, or null when
  /// the order is finished (delivered) or dead (cancelled).
  OrderStatus? get next {
    final i = pipeline.indexOf(this);
    if (i < 0 || i >= pipeline.length - 1) return null;
    return pipeline[i + 1];
  }

  bool get isOpen => this != OrderStatus.delivered && this != OrderStatus.cancelled;

  static OrderStatus parse(String? raw) => OrderStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => OrderStatus.placed,
      );
}

/// An order as the console sees it — the same document the customer app wrote
/// at `orders/{orderId}`.
class StoreOrder {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<StoreOrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddressId;
  final String deliveryAddress;
  final OrderStatus status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? packedAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;
  final String? cancelReason;

  const StoreOrder({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddressId,
    required this.deliveryAddress,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.confirmedAt,
    this.packedAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.deliveryPersonName,
    this.deliveryPersonPhone,
    this.cancelReason,
  });

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  /// Timestamp for each rung of the ladder, for the order timeline.
  DateTime? timestampFor(OrderStatus status) => switch (status) {
        OrderStatus.placed => createdAt,
        OrderStatus.confirmed => confirmedAt,
        OrderStatus.packed => packedAt,
        OrderStatus.outForDelivery => outForDeliveryAt,
        OrderStatus.delivered => deliveredAt,
        OrderStatus.cancelled => null,
      };

  factory StoreOrder.fromMap(String id, Map<String, dynamic> map) {
    DateTime? at(String key) => (map[key] as Timestamp?)?.toDate();
    return StoreOrder(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Customer',
      userPhone: map['userPhone'] as String? ?? '',
      items: (map['items'] as List<dynamic>? ?? const [])
          .map((i) => StoreOrderItem.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      deliveryAddressId: map['deliveryAddressId'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      status: OrderStatus.parse(map['status'] as String?),
      paymentMethod: map['paymentMethod'] as String? ?? 'COD',
      createdAt: at('createdAt') ?? DateTime.now(),
      confirmedAt: at('confirmedAt'),
      packedAt: at('packedAt'),
      outForDeliveryAt: at('outForDeliveryAt'),
      deliveredAt: at('deliveredAt'),
      deliveryPersonName: map['deliveryPersonName'] as String?,
      deliveryPersonPhone: map['deliveryPersonPhone'] as String?,
      cancelReason: map['cancelReason'] as String?,
    );
  }
}

class StoreOrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double lineTotal;

  const StoreOrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.lineTotal,
  });

  factory StoreOrderItem.fromMap(Map<String, dynamic> map) => StoreOrderItem(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        productImage: map['productImage'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0,
      );
}
