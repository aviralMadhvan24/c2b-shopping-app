import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../models/store_order.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'admin_shell.dart';
import 'order_detail_screen.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersWithStatsProvider);
    final search = ref.watch(customerSearchProvider).trim().toLowerCase();

    return customersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorPanel(
        error: e,
        onRetry: () => ref.invalidate(customersProvider),
      ),
      data: (all) {
        final customers = all.where((c) {
          if (search.isEmpty) return true;
          return c.displayName.toLowerCase().contains(search) ||
              (c.email ?? '').toLowerCase().contains(search) ||
              (c.phone ?? '').contains(search);
        }).toList();

        final buyers = all.where((c) => c.orderCount > 0).length;
        final revenue = all.fold<double>(0, (total, c) => total + c.lifetimeValue);

        return AdminPage(
          children: [
            PageHeader(
              title: 'Customers',
              subtitle: '${all.length} signed up · $buyers have ordered · '
                  '${Money.format(revenue)} lifetime',
            ),
            SearchField(
              hint: 'Search by name, email or phone',
              value: ref.watch(customerSearchProvider),
              onChanged: (v) =>
                  ref.read(customerSearchProvider.notifier).state = v,
            ),
            const SizedBox(height: 16),
            Card(
              child: customers.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: all.isEmpty
                          ? 'No customers yet'
                          : 'Nobody matches that search',
                      message: all.isEmpty
                          ? 'Everyone who signs up in the Niyati Mart app appears '
                              'here, along with what they have spent.'
                          : null,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < customers.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _CustomerRow(customer: customers[i]),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNarrow = MediaQuery.sizeOf(context).width < 780;

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _CustomerDialog(customer: customer),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: customer.orderCount > 0
                  ? AdminColors.primarySoft
                  : AdminColors.background,
              child: Text(
                customer.initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: customer.orderCount > 0
                      ? AdminColors.primary
                      : AdminColors.textGrey,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (customer.email != null && customer.email!.isNotEmpty)
                        customer.email!,
                      if (customer.phone != null && customer.phone!.isNotEmpty)
                        customer.phone!,
                    ].join(' · '),
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
            if (!isNarrow)
              Expanded(
                flex: 2,
                child: Text(
                  customer.lastOrderAt == null
                      ? customer.createdAt == null
                          ? ''
                          : 'Joined ${Dates.date(customer.createdAt!)}'
                      : 'Last order ${Dates.relative(customer.lastOrderAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textLight,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(customer.lifetimeValue),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: customer.lifetimeValue > 0
                        ? AdminColors.textDark
                        : AdminColors.textLight,
                  ),
                ),
                Text(
                  customer.orderCount == 0
                      ? 'No orders'
                      : '${customer.orderCount} order'
                          '${customer.orderCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AdminColors.textGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: AdminColors.textLight),
          ],
        ),
      ),
    );
  }
}

/// One customer's card: contact details and their order history.
class _CustomerDialog extends ConsumerWidget {
  const _CustomerDialog({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reuses the already-streamed order list rather than issuing a per-customer
    // query, so opening a customer costs nothing.
    final orders = (ref.watch(ordersProvider).valueOrNull ?? const <StoreOrder>[])
        .where((o) => o.userId == customer.id)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AdminColors.primarySoft,
            child: Text(
              customer.initials,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AdminColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.displayName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${customer.orderCount} order'
                  '${customer.orderCount == 1 ? '' : 's'} · '
                  '${Money.format(customer.lifetimeValue)} lifetime',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AdminColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customer.email != null && customer.email!.isNotEmpty)
                _Line(Icons.mail_outline, customer.email!),
              if (customer.phone != null && customer.phone!.isNotEmpty)
                _Line(Icons.phone_outlined, customer.phone!),
              if (customer.createdAt != null)
                _Line(
                  Icons.calendar_today_outlined,
                  'Joined ${Dates.date(customer.createdAt!)}',
                ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Order history',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'This customer has not ordered yet.',
                    style: TextStyle(fontSize: 12.5, color: AdminColors.textGrey),
                  ),
                )
              else
                for (final order in orders)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: order.status.softColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        order.status.icon,
                        size: 16,
                        color: order.status.color,
                      ),
                    ),
                    title: Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${Dates.date(order.createdAt)} · ${order.status.label}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: Text(
                      Money.format(order.total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AdminColors.textGrey),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
