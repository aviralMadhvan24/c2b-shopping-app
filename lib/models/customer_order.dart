import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  placed,
  confirmed,
  packed,
  outForDelivery,
  delivered,
  cancelled,
}

class CustomerOrder {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee; // 0 if above ₹499
  final double total;
  final String deliveryAddressId;
  final String deliveryAddress; // formatted address string
  final OrderStatus status;
  final String paymentMethod; // 'COD'
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? packedAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;
  final String? cancelReason;

  const CustomerOrder({
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

  // Firestore path: orders/{orderId}

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'deliveryAddressId': deliveryAddressId,
      'deliveryAddress': deliveryAddress,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'packedAt': packedAt != null ? Timestamp.fromDate(packedAt!) : null,
      'outForDeliveryAt': outForDeliveryAt != null ? Timestamp.fromDate(outForDeliveryAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'deliveryPersonName': deliveryPersonName,
      'deliveryPersonPhone': deliveryPersonPhone,
      'cancelReason': cancelReason,
    };
  }

  factory CustomerOrder.fromMap(String id, Map<String, dynamic> map) {
    return CustomerOrder(
      id: id,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userPhone: map['userPhone'] as String,
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      deliveryFee: (map['deliveryFee'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      deliveryAddressId: map['deliveryAddressId'] as String,
      deliveryAddress: map['deliveryAddress'] as String,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.placed,
      ),
      paymentMethod: map['paymentMethod'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
      packedAt: map['packedAt'] != null
          ? (map['packedAt'] as Timestamp).toDate()
          : null,
      outForDeliveryAt: map['outForDeliveryAt'] != null
          ? (map['outForDeliveryAt'] as Timestamp).toDate()
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      deliveryPersonName: map['deliveryPersonName'] as String?,
      deliveryPersonPhone: map['deliveryPersonPhone'] as String?,
      cancelReason: map['cancelReason'] as String?,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double lineTotal;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'lineTotal': lineTotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      productImage: map['productImage'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      lineTotal: (map['lineTotal'] as num).toDouble(),
    );
  }
}
