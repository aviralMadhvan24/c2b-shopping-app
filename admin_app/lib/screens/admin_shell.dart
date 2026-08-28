import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_order.dart';
import '../providers/admin_providers.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_theme.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'sections_screen.dart';
import 'settings_screen.dart';

/// The console frame: a permanent sidebar on a desktop-width window, a drawer
/// on anything narrower, with the selected section filling the rest.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.admin});

  final AdminUser admin;

  static const _destinations = <_Destination>[
    _Destination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _Destination('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
    _Destination('Products', Icons.inventory_2_outlined, Icons.inventory_2),
    _Destination('Sections', Icons.category_outlined, Icons.category),
    _Destination('Customers', Icons.people_outline, Icons.people),
    _Destination('Settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);
    // Below this the sidebar would eat too much of the page, so it becomes a
    // drawer instead — the same breakpoint the tables use to switch layout.
    final isWide = MediaQuery.sizeOf(context).width >= 1000;

    final body = switch (index) {
      0 => const DashboardScreen(),
      1 => const OrdersScreen(),
      2 => const ProductsScreen(),
      3 => const SectionsScreen(),
      4 => const CustomersScreen(),
      _ => const SettingsScreen(),
    };

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: AdminColors.sidebar,
              child: _Sidebar(
                admin: admin,
                selected: index,
                onSelect: (i) {
                  ref.read(navIndexProvider.notifier).state = i;
                  Navigator.pop(context);
                },
              ),
            ),
      appBar: isWide
          ? null
          : AppBar(
              title: Text(_destinations[index].label),
              actions: [
                const _PendingOrdersBadge(),
                const SizedBox(width: 8),
              ],
            ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 244,
              child: Material(
                color: AdminColors.sidebar,
                child: _Sidebar(
                  admin: admin,
                  selected: index,
                  onSelect: (i) => ref.read(navIndexProvider.notifier).state = i,
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination(this.label, this.icon, this.selectedIcon);
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.admin,
    required this.selected,
    required this.onSelect,
  });

  final AdminUser admin;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The count of orders waiting on the owner, shown against Orders so the
    // work to be done is visible without opening the tab.
    final pending = ref.watch(ordersProvider).maybeWhen(
          data: (orders) => orders
              .where((o) =>
                  o.status == OrderStatus.placed ||
                  o.status == OrderStatus.confirmed)
              .length,
          orElse: () => 0,
        );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niyati Mart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        'Store console',
                        style: TextStyle(
                          color: Color(0xFF8FA6C9),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < AdminShell._destinations.length; i++)
                  _NavItem(
                    destination: AdminShell._destinations[i],
                    selected: i == selected,
                    badge: i == 1 && pending > 0 ? pending : null,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1D3358), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AdminColors.primaryLight,
                  child: Text(
                    admin.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        admin.role,
                        style: const TextStyle(
                          color: Color(0xFF8FA6C9),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout, size: 19, color: Color(0xFF8FA6C9)),
                  onPressed: () => ref.read(adminAuthServiceProvider).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? AdminColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          hoverColor: AdminColors.sidebarHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 19,
                  color: selected ? Colors.white : const Color(0xFF9DB2D1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD3DEEE),
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminColors.orange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact pending-order count for the narrow-window app bar, where the
/// sidebar badge is not visible.
class _PendingOrdersBadge extends ConsumerWidget {
  const _PendingOrdersBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(ordersProvider).maybeWhen(
          data: (orders) => orders
              .where((o) =>
                  o.status == OrderStatus.placed ||
                  o.status == OrderStatus.confirmed)
              .length,
          orElse: () => 0,
        );
    if (pending == 0) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AdminColors.orangeSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$pending to action',
          style: const TextStyle(
            color: AdminColors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Page heading used by every screen so titles line up across the console.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AdminColors.textGrey,
                  ),
                ),
              ],
            ],
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ),
    );
  }
}

/// Standard page padding, scrollable, with a max width so tables do not
/// stretch to absurd line lengths on a wide monitor.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
