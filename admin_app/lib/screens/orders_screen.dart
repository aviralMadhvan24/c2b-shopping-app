import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_order.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'admin_shell.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final statusFilter = ref.watch(orderStatusFilterProvider);
    final search = ref.watch(orderSearchProvider).trim().toLowerCase();

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorPanel(
        error: e,
        onRetry: () => ref.invalidate(ordersProvider),
      ),
      data: (allOrders) {
        final orders = allOrders.where((o) {
          if (statusFilter != null && o.status != statusFilter) return false;
          if (search.isEmpty) return true;
          // Searching an order means searching for whatever the owner has in
          // hand: an order number off a slip, a customer name, a phone number.
          return o.id.toLowerCase().contains(search) ||
              o.userName.toLowerCase().contains(search) ||
              o.userPhone.contains(search) ||
              o.items.any((i) => i.productName.toLowerCase().contains(search));
        }).toList();

        final revenue = orders
            .where((o) => o.status != OrderStatus.cancelled)
            .fold<double>(0, (total, o) => total + o.total);

        return AdminPage(
          children: [
            PageHeader(
              title: 'Orders',
              subtitle: orders.length == allOrders.length
                  ? '${allOrders.length} orders · ${Money.format(revenue)}'
                  : '${orders.length} of ${allOrders.length} orders · '
                      '${Money.format(revenue)}',
            ),
            _Filters(counts: _countByStatus(allOrders), total: allOrders.length),
            const SizedBox(height: 16),
            Card(
              child: orders.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: allOrders.isEmpty
                          ? 'No orders yet'
                          : 'No orders match this filter',
                      message: allOrders.isEmpty
                          ? 'Orders placed in the Niyati Mart app appear here the '
                              'moment a customer checks out.'
                          : 'Try clearing the search box or picking a different '
                              'status.',
                      action: allOrders.isEmpty
                          ? null
                          : OutlinedButton(
                              onPressed: () {
                                ref.read(orderSearchProvider.notifier).state = '';
                                ref.read(orderStatusFilterProvider.notifier).state =
                                    null;
                              },
                              child: const Text('Clear filters'),
                            ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < orders.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _OrderRow(order: orders[i]),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  static Map<OrderStatus, int> _countByStatus(List<StoreOrder> orders) {
    final counts = {for (final s in OrderStatus.values) s: 0};
    for (final o in orders) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }
    return counts;
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.counts, required this.total});

  final Map<OrderStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(orderStatusFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          hint: 'Search by order number, customer, phone or product',
          value: ref.watch(orderSearchProvider),
          onChanged: (v) => ref.read(orderSearchProvider.notifier).state = v,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                count: total,
                selected: selected == null,
                color: AdminColors.textDark,
                onTap: () =>
                    ref.read(orderStatusFilterProvider.notifier).state = null,
              ),
              for (final status in OrderStatus.values)
                _FilterChip(
                  label: status.label,
                  count: counts[status] ?? 0,
                  selected: selected == status,
                  color: status.color,
                  onTap: () => ref.read(orderStatusFilterProvider.notifier).state =
                      selected == status ? null : status,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? color : AdminColors.card,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? color : AdminColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AdminColors.textDark,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AdminColors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AdminColors.textGrey,
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

class _OrderRow extends ConsumerWidget {
  const _OrderRow({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = order.status.next;
    final isNarrow = MediaQuery.sizeOf(context).width < 820;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: order.status.softColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(order.status.icon, size: 20, color: order.status.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          order.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Pill(
                        label: order.status.label,
                        color: order.status.color,
                        background: order.status.softColor,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#${order.id} · ${order.itemCount} item'
                    '${order.itemCount == 1 ? '' : 's'} · ${Dates.relative(order.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AdminColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (!isNarrow) ...[
              Expanded(
                flex: 2,
                child: Text(
                  order.deliveryAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textGrey,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(order.total),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  order.paymentMethod,
                  style: const TextStyle(fontSize: 11, color: AdminColors.textLight),
                ),
              ],
            ),
            if (next != null && !isNarrow) ...[
              const SizedBox(width: 14),
              // The one-tap advance: the whole point of the list view is that
              // the owner can work a queue of orders without opening each one.
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: next.color,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () async {
                  await ref.read(orderServiceProvider).updateStatus(order, next);
                  if (context.mounted) {
                    showToast(context, '#${order.id} → ${next.label}');
                  }
                },
                child: Text(_actionLabel(next)),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: AdminColors.textLight),
          ],
        ),
      ),
    );
  }

  static String _actionLabel(OrderStatus next) => switch (next) {
        OrderStatus.confirmed => 'Confirm',
        OrderStatus.packed => 'Mark packed',
        OrderStatus.outForDelivery => 'Send out',
        OrderStatus.delivered => 'Delivered',
        _ => next.label,
      };
}
