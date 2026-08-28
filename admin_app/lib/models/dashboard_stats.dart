import 'product.dart';
import 'store_order.dart';

/// Everything the dashboard shows, computed in one pass over the order and
/// product streams the console already holds. Keeping it a pure function of
/// those two lists means the dashboard cannot drift from the Orders and
/// Products screens — they are all reading the same numbers.
class DashboardStats {
  final double revenueTotal;
  final double revenueToday;
  final double revenueThisMonth;
  final int ordersTotal;
  final int ordersToday;
  final int ordersOpen;
  final int ordersNeedingAction;
  final int ordersDelivered;
  final int ordersCancelled;
  final double averageOrderValue;

  final int productsTotal;
  final int productsActive;
  final int outOfStock;
  final int lowStock;
  final int inventoryUnits;
  final double inventoryValue;

  final List<DaySales> last7Days;
  final List<TopProduct> topProducts;
  final List<SectionSales> salesBySection;
  final List<StoreOrder> recentOrders;

  const DashboardStats({
    this.revenueTotal = 0,
    this.revenueToday = 0,
    this.revenueThisMonth = 0,
    this.ordersTotal = 0,
    this.ordersToday = 0,
    this.ordersOpen = 0,
    this.ordersNeedingAction = 0,
    this.ordersDelivered = 0,
    this.ordersCancelled = 0,
    this.averageOrderValue = 0,
    this.productsTotal = 0,
    this.productsActive = 0,
    this.outOfStock = 0,
    this.lowStock = 0,
    this.inventoryUnits = 0,
    this.inventoryValue = 0,
    this.last7Days = const [],
    this.topProducts = const [],
    this.salesBySection = const [],
    this.recentOrders = const [],
  });

  /// [now] is injected so the "today" boundary is testable and so a single
  /// build uses one consistent clock.
  factory DashboardStats.from({
    required List<StoreOrder> orders,
    required List<AdminProduct> products,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final startOfToday = DateTime(clock.year, clock.month, clock.day);
    final startOfMonth = DateTime(clock.year, clock.month);

    // Cancelled orders are excluded from every revenue figure: that money was
    // never collected, and counting it would flatter the dashboard.
    final earning = orders.where((o) => o.status != OrderStatus.cancelled).toList();

    double revenueTotal = 0;
    double revenueToday = 0;
    double revenueThisMonth = 0;
    for (final o in earning) {
      revenueTotal += o.total;
      if (!o.createdAt.isBefore(startOfToday)) revenueToday += o.total;
      if (!o.createdAt.isBefore(startOfMonth)) revenueThisMonth += o.total;
    }

    final ordersToday =
        orders.where((o) => !o.createdAt.isBefore(startOfToday)).length;
    final ordersOpen = orders.where((o) => o.status.isOpen).length;
    // "Needs action" is the shop owner's to-do list: orders sitting at the
    // two statuses that only a human can move off.
    final ordersNeedingAction = orders
        .where((o) =>
            o.status == OrderStatus.placed || o.status == OrderStatus.confirmed)
        .length;

    // --- daily sales, last 7 days including today ---
    final days = <DaySales>[];
    for (var i = 6; i >= 0; i--) {
      final day = startOfToday.subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      final ofDay = earning.where(
        (o) => !o.createdAt.isBefore(day) && o.createdAt.isBefore(next),
      );
      days.add(DaySales(
        day: day,
        revenue: ofDay.fold<double>(0, (total, o) => total + o.total),
        orders: ofDay.length,
      ));
    }

    // --- best sellers by units sold ---
    final unitsByProduct = <String, TopProduct>{};
    for (final o in earning) {
      for (final item in o.items) {
        final existing = unitsByProduct[item.productId];
        unitsByProduct[item.productId] = TopProduct(
          productId: item.productId,
          name: item.productName,
          image: item.productImage,
          unitsSold: (existing?.unitsSold ?? 0) + item.quantity,
          revenue: (existing?.revenue ?? 0) + item.lineTotal,
        );
      }
    }
    final topProducts = unitsByProduct.values.toList()
      ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));

    // --- revenue per section, joined through the product catalog ---
    final sectionOfProduct = {for (final p in products) p.id: p.category};
    final bySection = <String, SectionSales>{};
    for (final o in earning) {
      for (final item in o.items) {
        final section = sectionOfProduct[item.productId] ?? 'Uncategorised';
        final existing = bySection[section];
        bySection[section] = SectionSales(
          section: section,
          revenue: (existing?.revenue ?? 0) + item.lineTotal,
          unitsSold: (existing?.unitsSold ?? 0) + item.quantity,
        );
      }
    }
    final salesBySection = bySection.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return DashboardStats(
      revenueTotal: revenueTotal,
      revenueToday: revenueToday,
      revenueThisMonth: revenueThisMonth,
      ordersTotal: orders.length,
      ordersToday: ordersToday,
      ordersOpen: ordersOpen,
      ordersNeedingAction: ordersNeedingAction,
      ordersDelivered:
          orders.where((o) => o.status == OrderStatus.delivered).length,
      ordersCancelled:
          orders.where((o) => o.status == OrderStatus.cancelled).length,
      averageOrderValue: earning.isEmpty ? 0 : revenueTotal / earning.length,
      productsTotal: products.length,
      productsActive: products.where((p) => p.active).length,
      outOfStock: products.where((p) => p.isOutOfStock).length,
      lowStock: products.where((p) => p.isLowStock).length,
      inventoryUnits: products.fold<int>(0, (total, p) => total + p.stock),
      inventoryValue:
          products.fold<double>(0, (total, p) => total + (p.price * p.stock)),
      last7Days: days,
      topProducts: topProducts.take(5).toList(),
      salesBySection: salesBySection,
      recentOrders: orders.take(6).toList(),
    );
  }
}

class DaySales {
  final DateTime day;
  final double revenue;
  final int orders;

  const DaySales({required this.day, required this.revenue, required this.orders});
}

class TopProduct {
  final String productId;
  final String name;
  final String image;
  final int unitsSold;
  final double revenue;

  const TopProduct({
    required this.productId,
    required this.name,
    required this.image,
    required this.unitsSold,
    required this.revenue,
  });
}

class SectionSales {
  final String section;
  final double revenue;
  final int unitsSold;

  const SectionSales({
    required this.section,
    required this.revenue,
    required this.unitsSold,
  });
}
