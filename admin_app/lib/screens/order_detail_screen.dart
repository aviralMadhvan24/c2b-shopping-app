import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_order.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

/// One order, end to end: what was bought, where it goes, and the controls to
/// move it along.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(singleOrderProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        leading: const BackButton(),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorPanel(error: e),
        data: (order) {
          if (order == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Order not found',
              message: 'It may have been removed from the database.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final left = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusBar(order: order),
                        const SizedBox(height: 16),
                        _Items(order: order),
                      ],
                    );
                    final right = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CustomerCard(order: order),
                        const SizedBox(height: 16),
                        _DeliveryCard(order: order),
                        const SizedBox(height: 16),
                        _Timeline(order: order),
                      ],
                    );

                    if (constraints.maxWidth < 860) {
                      return Column(children: [left, const SizedBox(height: 16), right]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: left),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: right),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Current status plus the buttons that change it.
class _StatusBar extends ConsumerWidget {
  const _StatusBar({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = order.status.next;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: order.status.softColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(order.status.icon, color: order.status.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: order.status.color,
                        ),
                      ),
                      Text(
                        'Placed ${Dates.dateTime(order.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AdminColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Money.exact(order.total),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (order.cancelReason != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Cancelled: ${order.cancelReason}',
                  style: const TextStyle(fontSize: 13, color: AdminColors.danger),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (next != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: next.color),
                    onPressed: () => _setStatus(context, ref, next),
                    icon: Icon(next.icon, size: 18),
                    label: Text('Move to ${next.label.toLowerCase()}'),
                  ),
                // Any status is reachable from the menu, not just the next
                // one: a real shop occasionally has to correct a misclick, and
                // forcing them into the database to do it would be worse.
                PopupMenuButton<OrderStatus>(
                  onSelected: (status) => _setStatus(context, ref, status),
                  itemBuilder: (context) => [
                    for (final status in OrderStatus.values)
                      PopupMenuItem(
                        value: status,
                        enabled: status != order.status,
                        child: Row(
                          children: [
                            Icon(status.icon, size: 18, color: status.color),
                            const SizedBox(width: 10),
                            Text(status.label),
                          ],
                        ),
                      ),
                  ],
                  child: OutlinedButton.icon(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: AdminColors.textDark,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Change status'),
                  ),
                ),
                if (order.status.isOpen)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.danger,
                      side: const BorderSide(color: AdminColors.danger),
                    ),
                    onPressed: () => _cancel(context, ref),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel order'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus status,
  ) async {
    if (status == OrderStatus.cancelled) {
      await _cancel(context, ref);
      return;
    }
    try {
      await ref.read(orderServiceProvider).updateStatus(order, status);
      if (context.mounted) showToast(context, 'Order is now ${status.label}.');
    } catch (e) {
      if (context.mounted) showToast(context, '$e', isError: true);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The customer sees this reason on their order tracking screen.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Out of stock',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (reason == null) return;

    try {
      await ref.read(orderServiceProvider).updateStatus(
            order,
            OrderStatus.cancelled,
            cancelReason: reason,
          );
      if (context.mounted) showToast(context, 'Order cancelled.');
    } catch (e) {
      if (context.mounted) showToast(context, '$e', isError: true);
    }
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Items',
      subtitle: '${order.itemCount} unit${order.itemCount == 1 ? '' : 's'}',
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Row(
                children: [
                  ImageThumb(url: item.productImage, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Money.exact(item.price)} × ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Money.exact(item.lineTotal),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: [
                _SummaryLine('Subtotal', Money.exact(order.subtotal)),
                _SummaryLine(
                  'Delivery',
                  order.deliveryFee == 0 ? 'Free' : Money.exact(order.deliveryFee),
                  valueColor:
                      order.deliveryFee == 0 ? AdminColors.success : null,
                ),
                const SizedBox(height: 6),
                const Divider(height: 12),
                _SummaryLine(
                  'Total (${order.paymentMethod})',
                  Money.exact(order.total),
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.value, {this.bold = false, this.valueColor});

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14.5 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AdminColors.textDark : AdminColors.textGrey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15.5 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AdminColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(Icons.person_outline, order.userName),
          if (order.userPhone.isNotEmpty)
            _DetailRow(Icons.phone_outlined, order.userPhone, selectable: true),
          _DetailRow(
            Icons.location_on_outlined,
            order.deliveryAddress.isEmpty ? 'No address on file' : order.deliveryAddress,
            selectable: true,
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends ConsumerStatefulWidget {
  const _DeliveryCard({required this.order});

  final StoreOrder order;

  @override
  ConsumerState<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends ConsumerState<_DeliveryCard> {
  late final TextEditingController _name =
      TextEditingController(text: widget.order.deliveryPersonName ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.order.deliveryPersonPhone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(orderServiceProvider).assignDelivery(
            orderId: widget.order.id,
            name: _name.text,
            phone: _phone.text,
          );
      if (mounted) showToast(context, 'Delivery contact saved.');
    } catch (e) {
      if (mounted) showToast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Delivery person',
      subtitle: 'The customer sees this while tracking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save contact'),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final reached = OrderStatus.pipeline.indexOf(order.status);
    final cancelled = order.status == OrderStatus.cancelled;

    return PanelCard(
      title: 'Progress',
      child: Column(
        children: [
          for (var i = 0; i < OrderStatus.pipeline.length; i++)
            _TimelineStep(
              status: OrderStatus.pipeline[i],
              at: order.timestampFor(OrderStatus.pipeline[i]),
              // A cancelled order keeps the steps it actually completed but
              // stops claiming progress it never made.
              done: !cancelled && i <= reached,
              isLast: i == OrderStatus.pipeline.length - 1,
            ),
          if (cancelled)
            _TimelineStep(
              status: OrderStatus.cancelled,
              at: null,
              done: true,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.at,
    required this.done,
    required this.isLast,
  });

  final OrderStatus status;
  final DateTime? at;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? status.color : AdminColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? color : AdminColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                      color: done ? AdminColors.textDark : AdminColors.textLight,
                    ),
                  ),
                  if (at != null)
                    Text(
                      Dates.dateTime(at!),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AdminColors.textGrey,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.text, {this.selectable = false});

  final IconData icon;
  final String text;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AdminColors.textGrey),
          const SizedBox(width: 11),
          Expanded(
            child: selectable
                ? SelectableText(
                    text,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  )
                : Text(
                    text,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
          ),
        ],
      ),
    );
  }
}
