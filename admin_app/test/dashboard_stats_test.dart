import 'package:flutter_test/flutter_test.dart';
import 'package:niyati_admin/models/dashboard_stats.dart';
import 'package:niyati_admin/models/product.dart';
import 'package:niyati_admin/models/store_order.dart';

/// The dashboard is the number the owner trusts to decide whether the day went
/// well. These cover the ways it could quietly lie.
void main() {
  final now = DateTime(2026, 8, 23, 14, 0);

  StoreOrder order({
    required String id,
    required double total,
    required DateTime at,
    OrderStatus status = OrderStatus.delivered,
    String userId = 'u1',
    List<StoreOrderItem> items = const [],
  }) {
    return StoreOrder(
      id: id,
      userId: userId,
      userName: 'Test Customer',
      userPhone: '9999999999',
      items: items,
      subtotal: total,
      deliveryFee: 0,
      total: total,
      deliveryAddressId: 'a1',
      deliveryAddress: 'Somewhere',
      status: status,
      paymentMethod: 'COD',
      createdAt: at,
    );
  }

  StoreOrderItem item(String productId, String name, int qty, double price) =>
      StoreOrderItem(
        productId: productId,
        productName: name,
        productImage: '',
        price: price,
        quantity: qty,
        lineTotal: price * qty,
      );

  AdminProduct product({
    required String id,
    required String category,
    int stock = 10,
    double price = 100,
    bool active = true,
  }) =>
      AdminProduct(
        id: id,
        name: 'Product $id',
        image: '',
        price: price,
        category: category,
        stock: stock,
        active: active,
      );

  group('revenue', () {
    test('excludes cancelled orders from every revenue figure', () {
      final stats = DashboardStats.from(
        now: now,
        products: const [],
        orders: [
          order(id: '1', total: 1000, at: now),
          order(id: '2', total: 500, at: now, status: OrderStatus.cancelled),
        ],
      );

      expect(stats.revenueTotal, 1000);
      expect(stats.revenueToday, 1000);
      expect(stats.revenueThisMonth, 1000);
      // ...but the cancelled order is still part of the order history.
      expect(stats.ordersTotal, 2);
      expect(stats.ordersCancelled, 1);
    });

    test('averages over earning orders only, so a cancellation does not '
        'drag the average down', () {
      final stats = DashboardStats.from(
        now: now,
        products: const [],
        orders: [
          order(id: '1', total: 1000, at: now),
          order(id: '2', total: 2000, at: now),
          order(id: '3', total: 9999, at: now, status: OrderStatus.cancelled),
        ],
      );

      expect(stats.averageOrderValue, 1500);
    });

    test('"today" starts at midnight, not 24 hours ago', () {
      final stats = DashboardStats.from(
        now: now,
        products: const [],
        orders: [
          order(id: 'today', total: 100, at: DateTime(2026, 8, 23, 0, 1)),
          order(id: 'lastnight', total: 700, at: DateTime(2026, 8, 22, 23, 59)),
        ],
      );

      expect(stats.revenueToday, 100);
      expect(stats.ordersToday, 1);
      expect(stats.revenueTotal, 800);
    });

    test('month total spans the calendar month, not the last 30 days', () {
      final stats = DashboardStats.from(
        now: now,
        products: const [],
        orders: [
          order(id: 'thismonth', total: 300, at: DateTime(2026, 8, 1)),
          order(id: 'lastmonth', total: 400, at: DateTime(2026, 7, 31, 23, 59)),
        ],
      );

      expect(stats.revenueThisMonth, 300);
      expect(stats.revenueTotal, 700);
    });
  });

  group('work queue', () {
    test('counts only the statuses a human has to move', () {
      final stats = DashboardStats.from(
        now: now,
        products: const [],
        orders: [
          order(id: '1', total: 10, at: now, status: OrderStatus.placed),
          order(id: '2', total: 10, at: now, status: OrderStatus.confirmed),
          order(id: '3', total: 10, at: now, status: OrderStatus.outForDelivery),
          order(id: '4', total: 10, at: now, status: OrderStatus.delivered),
          order(id: '5', total: 10, at: now, status: OrderStatus.cancelled),
        ],
      );

      expect(stats.ordersNeedingAction, 2);
      // Open = everything not finished or dead.
      expect(stats.ordersOpen, 3);
      expect(stats.ordersDelivered, 1);
    });
  });

  group('inventory', () {
    test('separates out-of-stock from low-stock and values the shelf', () {
      final stats = DashboardStats.from(
        now: now,
        orders: const [],
        products: [
          product(id: 'a', category: 'Clothes', stock: 0, price: 500),
          product(id: 'b', category: 'Clothes', stock: 3, price: 200),
          product(id: 'c', category: 'Clothes', stock: 50, price: 100),
          product(id: 'd', category: 'Clothes', stock: 5, price: 10, active: false),
        ],
      );

      expect(stats.outOfStock, 1);
      // stock 3 and stock 5 are both at or below the threshold of 5.
      expect(stats.lowStock, 2);
      expect(stats.productsTotal, 4);
      expect(stats.productsActive, 3);
      expect(stats.inventoryUnits, 58);
      expect(stats.inventoryValue, 0 + 600 + 5000 + 50);
    });
  });

  group('breakdowns', () {
    test('ranks best sellers by units, summing across orders', () {
      final stats = DashboardStats.from(
        now: now,
        products: const [],
        orders: [
          order(id: '1', total: 300, at: now, items: [
            item('p1', 'Kurta', 1, 100),
            item('p2', 'Laptop', 2, 100),
          ]),
          order(id: '2', total: 500, at: now, items: [
            item('p1', 'Kurta', 5, 100),
          ]),
        ],
      );

      expect(stats.topProducts.first.productId, 'p1');
      expect(stats.topProducts.first.unitsSold, 6);
      expect(stats.topProducts.first.revenue, 600);
      expect(stats.topProducts[1].unitsSold, 2);
    });

    test('joins sales to sections through the catalog, and files products '
        'that no longer exist under Uncategorised', () {
      final stats = DashboardStats.from(
        now: now,
        products: [
          product(id: 'p1', category: 'Clothes'),
        ],
        orders: [
          order(id: '1', total: 300, at: now, items: [
            item('p1', 'Kurta', 1, 100),
            // Sold before the product was deleted from the catalog.
            item('gone', 'Old thing', 1, 200),
          ]),
        ],
      );

      final sections = {for (final s in stats.salesBySection) s.section: s.revenue};
      expect(sections['Clothes'], 100);
      expect(sections['Uncategorised'], 200);
    });

    test('always reports exactly seven days, ending today', () {
      final stats = DashboardStats.from(
        now: now,
        products: const [],
        orders: [order(id: '1', total: 100, at: now)],
      );

      expect(stats.last7Days, hasLength(7));
      expect(stats.last7Days.last.day, DateTime(2026, 8, 23));
      expect(stats.last7Days.first.day, DateTime(2026, 8, 17));
      expect(stats.last7Days.last.revenue, 100);
      expect(stats.last7Days.first.revenue, 0);
    });
  });

  group('empty store', () {
    test('reports zeros rather than dividing by zero', () {
      final stats = DashboardStats.from(
        now: now,
        orders: const [],
        products: const [],
      );

      expect(stats.revenueTotal, 0);
      expect(stats.averageOrderValue, 0);
      expect(stats.topProducts, isEmpty);
      expect(stats.last7Days, hasLength(7));
    });
  });
}
