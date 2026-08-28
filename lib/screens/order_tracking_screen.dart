import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/customer_order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/product_image.dart';

/// Represents a single step in the order tracking timeline.
class _TrackingStep {
  final String title;
  final String? dateTime;
  final _StepStatus status;

  const _TrackingStep({
    required this.title,
    this.dateTime,
    required this.status,
  });
}

enum _StepStatus { completed, current, pending }

/// Order Tracking Screen that listens to real-time Firestore order status.
class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderService = ref.watch(orderServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<CustomerOrder>(
        stream: orderService.watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.textLight, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load order details',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'Order not found',
                style: TextStyle(color: AppColors.textGrey, fontSize: 16),
              ),
            );
          }

          final order = snapshot.data!;
          final steps = _buildSteps(order);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderInfoCard(order),
                      const SizedBox(height: 24),
                      // Delivery Person Info
                      if (order.status == OrderStatus.outForDelivery &&
                          order.deliveryPersonName != null)
                        ...[
                          _buildDeliveryPersonCard(order),
                          const SizedBox(height: 24),
                        ],
                      // Timeline
                      const Text(
                        'Tracking Details',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(steps),
                      const SizedBox(height: 24),
                      // Order Items
                      _buildOrderItems(order),
                    ],
                  ),
                ),
              ),
              // Cancel Order button (only visible for cancellable statuses)
              if (order.status == OrderStatus.placed ||
                  order.status == OrderStatus.confirmed)
                _buildCancelButton(context, ref, order),
            ],
          );
        },
      ),
    );
  }

  List<_TrackingStep> _buildSteps(CustomerOrder order) {
    final dateFormatter = DateFormat('dd MMM, hh:mm a');

    _StepStatus statusFor(OrderStatus step) {
      final orderIndex = OrderStatus.values.indexOf(order.status);
      final stepIndex = OrderStatus.values.indexOf(step);

      if (order.status == OrderStatus.cancelled) {
        // If cancelled, show placed/confirmed as completed, rest as pending
        if (step == OrderStatus.placed) return _StepStatus.completed;
        if (step == OrderStatus.confirmed && order.confirmedAt != null) {
          return _StepStatus.completed;
        }
        return _StepStatus.pending;
      }

      if (stepIndex < orderIndex) return _StepStatus.completed;
      if (stepIndex == orderIndex) return _StepStatus.current;
      return _StepStatus.pending;
    }

    final steps = <_TrackingStep>[
      _TrackingStep(
        title: 'Order Placed',
        dateTime: dateFormatter.format(order.createdAt),
        status: statusFor(OrderStatus.placed),
      ),
      _TrackingStep(
        title: 'Confirmed',
        dateTime: order.confirmedAt != null
            ? dateFormatter.format(order.confirmedAt!)
            : null,
        status: statusFor(OrderStatus.confirmed),
      ),
      _TrackingStep(
        title: 'Packed',
        dateTime: order.packedAt != null
            ? dateFormatter.format(order.packedAt!)
            : null,
        status: statusFor(OrderStatus.packed),
      ),
      _TrackingStep(
        title: 'Out for Delivery',
        dateTime: order.outForDeliveryAt != null
            ? dateFormatter.format(order.outForDeliveryAt!)
            : null,
        status: statusFor(OrderStatus.outForDelivery),
      ),
      _TrackingStep(
        title: 'Delivered',
        dateTime: order.deliveredAt != null
            ? dateFormatter.format(order.deliveredAt!)
            : null,
        status: statusFor(OrderStatus.delivered),
      ),
    ];

    return steps;
  }

  Widget _buildOrderInfoCard(CustomerOrder order) {
    final statusLabel = _getStatusLabel(order.status);
    final statusColor = _getStatusColor(order.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order ID',
                style: TextStyle(color: AppColors.textDark, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '#${order.id}',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.textLight, size: 14),
              const SizedBox(width: 6),
              Text(
                'Order Date: ${DateFormat('dd MMM yyyy').format(order.createdAt)}',
                style: const TextStyle(color: AppColors.textDark, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.money, color: AppColors.textLight, size: 14),
              const SizedBox(width: 6),
              Text(
                'Payment: ${order.paymentMethod} • ${CurrencyFormatter.formatINR(order.total)}',
                style: const TextStyle(color: AppColors.textDark, fontSize: 13),
              ),
            ],
          ),
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: AppColors.success, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Estimated delivery: within 1-2 hours',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (order.status == OrderStatus.cancelled &&
              order.cancelReason != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    color: AppColors.danger, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reason: ${order.cancelReason}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryPersonCard(CustomerOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delivery_dining, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Partner',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  order.deliveryPersonName!,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (order.deliveryPersonPhone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    order.deliveryPersonPhone!,
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (order.deliveryPersonPhone != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, color: AppColors.success, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<_TrackingStep> steps) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return _buildTimelineItem(step, isLast);
      }),
    );
  }

  Widget _buildTimelineItem(_TrackingStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _buildStepCircle(step.status),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.status == _StepStatus.completed
                          ? AppColors.success
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Step content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: step.status == _StepStatus.pending
                          ? AppColors.textLight
                          : AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (step.dateTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.dateTime!,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(_StepStatus status) {
    switch (status) {
      case _StepStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.onPrimary, size: 14),
        );
      case _StepStatus.current:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.circle, color: AppColors.onPrimary, size: 10),
          ),
        );
      case _StepStatus.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textLight, width: 2),
          ),
        );
    }
  }

  Widget _buildOrderItems(CustomerOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${order.items.length})',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ProductImage(
                        source: item.productImage,
                        width: 40,
                        height: 40,
                        placeholderIconSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatINR(item.lineTotal),
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCancelButton(
      BuildContext context, WidgetRef ref, CustomerOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showCancelDialog(context, ref),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text(
              'CANCEL ORDER',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Cancel Order',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to cancel this order?',
              style: TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (optional)',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Keep Order',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final orderService = ref.read(orderServiceProvider);
                await orderService.cancelOrder(
                  orderId,
                  reasonController.text.trim().isEmpty
                      ? 'Cancelled by customer'
                      : reasonController.text.trim(),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return AppColors.gold;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.packed:
        return Colors.orange;
      case OrderStatus.outForDelivery:
        return AppColors.gold;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.danger;
    }
  }
}
