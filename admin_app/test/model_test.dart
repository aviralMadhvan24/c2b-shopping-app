import 'package:flutter_test/flutter_test.dart';
import 'package:niyati_admin/models/customer.dart';
import 'package:niyati_admin/models/product.dart';
import 'package:niyati_admin/models/store_order.dart';
import 'package:niyati_admin/services/customer_service.dart';
import 'package:niyati_admin/utils/formatters.dart';

void main() {
  group('AdminProduct', () {
    test('keeps the storefront contract intact when written', () {
      const product = AdminProduct(
        id: 'p1',
        name: 'Kurta',
        image: 'https://example.com/a.jpg',
        price: 799,
        category: 'Clothes',
        stock: 4,
      );

      final map = product.toMap();
      // The customer app's Product.fromMap reads exactly these keys.
      for (final key in [
        'id',
        'name',
        'image',
        'price',
        'currencyCode',
        'category',
        'rating',
        'description',
        'variants',
      ]) {
        expect(map.containsKey(key), isTrue, reason: 'missing $key');
      }
      expect(map['currencyCode'], 'INR');
    });

    test('derives the discount badge from MRP instead of trusting a stale '
        'stored value', () {
      const product = AdminProduct(
        id: 'p1',
        name: 'Kurta',
        image: '',
        price: 800,
        mrp: 1000,
        // A wrong number left over from an earlier edit.
        discountPercent: 90,
        category: 'Clothes',
      );

      expect(product.computedDiscountPercent, 20);
      expect(product.toMap()['discountPercent'], 20);
    });

    test('writes no discount when MRP does not beat the price', () {
      const product = AdminProduct(
        id: 'p1',
        name: 'Kurta',
        image: '',
        price: 800,
        mrp: 800,
        category: 'Clothes',
      );

      expect(product.hasDiscount, isFalse);
      expect(product.toMap()['discountPercent'], isNull);
    });

    test('backfills the images list for products seeded before the console '
        'existed', () {
      final product = AdminProduct.fromMap('p1', {
        'name': 'Old product',
        'image': 'assets/products/shirt.jpg',
        'price': 500,
        'category': 'Clothes',
      });

      expect(product.images, ['assets/products/shirt.jpg']);
      expect(product.stock, 0);
      expect(product.active, isTrue);
    });

    test('flags stock states at the threshold boundary', () {
      const out = AdminProduct(
          id: 'a', name: '', image: '', price: 1, category: 'c', stock: 0);
      const low = AdminProduct(
          id: 'b', name: '', image: '', price: 1, category: 'c', stock: 5);
      const fine = AdminProduct(
          id: 'c', name: '', image: '', price: 1, category: 'c', stock: 6);

      expect(out.isOutOfStock, isTrue);
      expect(out.isLowStock, isFalse);
      expect(low.isLowStock, isTrue);
      expect(fine.isLowStock, isFalse);
    });
  });

  group('OrderStatus', () {
    test('walks the pipeline and stops at delivered', () {
      expect(OrderStatus.placed.next, OrderStatus.confirmed);
      expect(OrderStatus.outForDelivery.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
      expect(OrderStatus.cancelled.next, isNull);
    });

    test('parses unknown values as placed rather than throwing', () {
      expect(OrderStatus.parse('packed'), OrderStatus.packed);
      expect(OrderStatus.parse('nonsense'), OrderStatus.placed);
      expect(OrderStatus.parse(null), OrderStatus.placed);
    });

    test('names match the strings the customer app writes', () {
      expect(OrderStatus.outForDelivery.name, 'outForDelivery');
    });
  });

  group('CustomerService.withOrderStats', () {
    StoreOrder order(String userId, double total, DateTime at,
            {OrderStatus status = OrderStatus.delivered}) =>
        StoreOrder(
          id: 'o',
          userId: userId,
          userName: '',
          userPhone: '',
          items: const [],
          subtotal: total,
          deliveryFee: 0,
          total: total,
          deliveryAddressId: '',
          deliveryAddress: '',
          status: status,
          paymentMethod: 'COD',
          createdAt: at,
        );

    test('counts cancelled orders in history but not in lifetime value', () {
      final result = CustomerService.withOrderStats(
        [const Customer(id: 'u1', name: 'Asha')],
        [
          order('u1', 1000, DateTime(2026, 8, 1)),
          order('u1', 500, DateTime(2026, 8, 5), status: OrderStatus.cancelled),
        ],
      );

      expect(result.single.orderCount, 2);
      expect(result.single.lifetimeValue, 1000);
      expect(result.single.lastOrderAt, DateTime(2026, 8, 5));
    });

    test('sorts biggest spenders first and non-buyers last', () {
      final result = CustomerService.withOrderStats(
        [
          const Customer(id: 'u1', name: 'Small'),
          const Customer(id: 'u2', name: 'Big'),
          const Customer(id: 'u3', name: 'Never ordered'),
        ],
        [
          order('u1', 100, DateTime(2026, 8, 1)),
          order('u2', 900, DateTime(2026, 8, 1)),
        ],
      );

      expect(result.map((c) => c.id), ['u2', 'u1', 'u3']);
    });
  });

  group('Customer', () {
    test('falls back through name, email, then a generic label', () {
      expect(const Customer(id: 'u', name: 'Asha Devi').displayName, 'Asha Devi');
      expect(const Customer(id: 'u', email: 'asha@x.com').displayName, 'asha');
      expect(const Customer(id: 'u').displayName, 'Customer');
    });

    test('builds initials from one or two names', () {
      expect(const Customer(id: 'u', name: 'Asha Devi').initials, 'AD');
      expect(const Customer(id: 'u', name: 'Asha').initials, 'AS');
    });

    test('parses the ISO createdAt the customer app writes', () {
      final customer = Customer.fromMap('u1', {
        'name': 'Asha',
        'createdAt': '2026-08-01T10:00:00.000',
      });
      expect(customer.createdAt, DateTime(2026, 8, 1, 10));
    });

    test('survives a document with a missing or malformed createdAt', () {
      expect(Customer.fromMap('u1', {'name': 'A'}).createdAt, isNull);
      expect(
        Customer.fromMap('u1', {'createdAt': 'not a date'}).createdAt,
        isNull,
      );
    });
  });

  group('Money.compact', () {
    test('uses Indian units so the owner reads familiar numbers', () {
      expect(Money.compact(800), '₹800');
      expect(Money.compact(45600), '₹45.6K');
      expect(Money.compact(120000), '₹1.2L');
      expect(Money.compact(15000000), '₹1.5Cr');
    });
  });
}
