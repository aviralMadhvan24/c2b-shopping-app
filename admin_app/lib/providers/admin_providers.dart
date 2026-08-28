import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../models/dashboard_stats.dart';
import '../models/product.dart';
import '../models/store_order.dart';
import '../models/store_section.dart';
import '../services/admin_auth_service.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/section_service.dart';
import '../services/storage_service.dart';

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

final adminAuthServiceProvider =
    Provider<AdminAuthService>((ref) => AdminAuthService());

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final sectionServiceProvider = Provider<SectionService>(
  (ref) => SectionService(productService: ref.watch(productServiceProvider)),
);

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

final customerServiceProvider =
    Provider<CustomerService>((ref) => CustomerService());

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

// ---------------------------------------------------------------------------
// Session
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(adminAuthServiceProvider).authStateChanges,
);

/// The signed-in user's admin record, or null when they hold none.
///
/// This is what gates the console. It stays a stream so that revoking an
/// admin's access closes their open session rather than waiting for a reload.
final currentAdminProvider = StreamProvider<AdminUser?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(adminAuthServiceProvider).watchAdmin(user.uid);
});

// ---------------------------------------------------------------------------
// Data
//
// These providers are the console's single read of each collection: the
// dashboard, the tables and the detail screens all watch the same streams, so
// two screens can never show different numbers for the same thing.
// ---------------------------------------------------------------------------

final productsProvider = StreamProvider<List<AdminProduct>>(
  (ref) => ref.watch(productServiceProvider).watchAll(),
);

final sectionsProvider = StreamProvider<List<StoreSection>>(
  (ref) => ref.watch(sectionServiceProvider).watchAll(),
);

final ordersProvider = StreamProvider<List<StoreOrder>>(
  (ref) => ref.watch(orderServiceProvider).watchRecent(),
);

final customersProvider = StreamProvider<List<Customer>>(
  (ref) => ref.watch(customerServiceProvider).watchAll(),
);

/// Customers joined to their order history.
final customersWithStatsProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customers = ref.watch(customersProvider);
  final orders = ref.watch(ordersProvider);
  return customers.whenData(
    (list) => CustomerService.withOrderStats(list, orders.valueOrNull ?? const []),
  );
});

final singleOrderProvider = StreamProvider.family<StoreOrder?, String>(
  (ref, id) => ref.watch(orderServiceProvider).watchOne(id),
);

/// Every dashboard figure, derived from the order and product streams.
final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final orders = ref.watch(ordersProvider);
  final products = ref.watch(productsProvider);

  // Surface a real error rather than an endless spinner if either read fails
  // (most likely: this account is not an admin, so the rules deny the query).
  if (orders.hasError) {
    return AsyncValue.error(orders.error!, orders.stackTrace!);
  }
  if (products.hasError) {
    return AsyncValue.error(products.error!, products.stackTrace!);
  }
  final orderList = orders.valueOrNull;
  final productList = products.valueOrNull;
  if (orderList == null || productList == null) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(
    DashboardStats.from(orders: orderList, products: productList),
  );
});

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

/// Which item in the sidebar is selected.
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Free-text filter on the products table.
final productSearchProvider = StateProvider<String>((ref) => '');

/// Section filter on the products table; null means "all sections".
final productSectionFilterProvider = StateProvider<String?>((ref) => null);

/// Status filter on the orders table; null means "all statuses".
final orderStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);

/// Free-text filter on the orders table.
final orderSearchProvider = StateProvider<String>((ref) => '');

/// Free-text filter on the customers table.
final customerSearchProvider = StateProvider<String>((ref) => '');
