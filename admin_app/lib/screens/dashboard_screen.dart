import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import '../models/store_order.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'admin_shell.dart';
import 'order_detail_screen.dart';

/// The console's front page: what came in today, what needs doing, and what
/// is running out.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorPanel(
        error: e,
        onRetry: () {
          ref.invalidate(ordersProvider);
          ref.invalidate(productsProvider);
        },
      ),
      data: (s) => AdminPage(
        children: [
          PageHeader(
            title: 'Dashboard',
            subtitle: 'Everything happening in the store right now',
            actions: [
              if (s.ordersNeedingAction > 0)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.orange,
                  ),
                  onPressed: () {
                    ref.read(orderStatusFilterProvider.notifier).state = null;
                    ref.read(navIndexProvider.notifier).state = 1;
                  },
                  icon: const Icon(Icons.bolt, size: 18),
                  label: Text('${s.ordersNeedingAction} orders need action'),
                ),
            ],
          ),
          _StatGrid(stats: s),
          const SizedBox(height: 16),
          if (s.outOfStock > 0 || s.lowStock > 0) ...[
            _StockAlert(stats: s),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final salesChart = PanelCard(
                title: 'Sales this week',
                subtitle: 'Revenue per day, cancelled orders excluded',
                child: SizedBox(
                  height: 240,
                  child: _RevenueChart(days: s.last7Days),
                ),
              );
              final sectionBreakdown = PanelCard(
                title: 'Sales by section',
                subtitle: 'Which parts of the store are earning',
                child: _SectionBreakdown(sections: s.salesBySection),
              );

              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    salesChart,
                    const SizedBox(height: 16),
                    sectionBreakdown,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: salesChart),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: sectionBreakdown),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final recent = PanelCard(
                title: 'Latest orders',
                action: TextButton(
                  onPressed: () => ref.read(navIndexProvider.notifier).state = 1,
                  child: const Text('View all'),
                ),
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentOrders(orders: s.recentOrders),
              );
              final best = PanelCard(
                title: 'Best sellers',
                subtitle: 'By units sold, all time',
                padding: const EdgeInsets.only(bottom: 8),
                child: _TopProducts(products: s.topProducts),
              );

              if (constraints.maxWidth < 900) {
                return Column(
                  children: [recent, const SizedBox(height: 16), best],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: recent),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: best),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends ConsumerWidget {
  const _StatGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = <Widget>[
      StatTile(
        label: 'Revenue today',
        value: Money.format(stats.revenueToday),
        caption: '${stats.ordersToday} order${stats.ordersToday == 1 ? '' : 's'} today',
        icon: Icons.payments_outlined,
        color: AdminColors.success,
      ),
      StatTile(
        label: 'Revenue this month',
        value: Money.format(stats.revenueThisMonth),
        caption: 'All time ${Money.compact(stats.revenueTotal)}',
        icon: Icons.trending_up,
        color: AdminColors.primary,
      ),
      StatTile(
        label: 'Open orders',
        value: '${stats.ordersOpen}',
        caption: '${stats.ordersNeedingAction} waiting on you',
        icon: Icons.local_shipping_outlined,
        color: AdminColors.orange,
        onTap: () => ref.read(navIndexProvider.notifier).state = 1,
      ),
      StatTile(
        label: 'Average order',
        value: Money.format(stats.averageOrderValue),
        caption: '${stats.ordersTotal} orders total',
        icon: Icons.receipt_outlined,
        color: AdminColors.teal,
      ),
      StatTile(
        label: 'Products live',
        value: '${stats.productsActive}',
        caption: stats.productsTotal == stats.productsActive
            ? 'All published'
            : '${stats.productsTotal - stats.productsActive} hidden',
        icon: Icons.inventory_2_outlined,
        color: AdminColors.purple,
        onTap: () => ref.read(navIndexProvider.notifier).state = 2,
      ),
      StatTile(
        label: 'Stock value',
        value: Money.compact(stats.inventoryValue),
        caption: '${stats.inventoryUnits} units on hand',
        icon: Icons.warehouse_outlined,
        color: AdminColors.primaryLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tiles are sized by how many fit at a readable width rather than a
        // fixed column count, so the grid reflows cleanly from phone to
        // ultrawide without a stack of breakpoints.
        const spacing = 16.0;
        final columns = (constraints.maxWidth / 250).floor().clamp(1, 6);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _StockAlert extends ConsumerWidget {
  const _StockAlert({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parts = <String>[
      if (stats.outOfStock > 0)
        '${stats.outOfStock} out of stock',
      if (stats.lowStock > 0) '${stats.lowStock} running low',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stats.outOfStock > 0 ? AdminColors.dangerSoft : AdminColors.orangeSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (stats.outOfStock > 0 ? AdminColors.danger : AdminColors.orange)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: stats.outOfStock > 0 ? AdminColors.danger : AdminColors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Inventory needs attention — ${parts.join(', ')}.',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(productSectionFilterProvider.notifier).state = null;
              ref.read(productSearchProvider.notifier).state = '';
              ref.read(navIndexProvider.notifier).state = 2;
            },
            child: const Text('Review stock'),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.days});

  final List<DaySales> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'No sales data yet',
      );
    }

    final maxRevenue = days.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);
    // A flat zero axis would collapse every bar to nothing; give an empty
    // week a nominal ceiling so the chart still draws its grid.
    final maxY = maxRevenue <= 0 ? 100.0 : maxRevenue * 1.25;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AdminColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  Money.compact(value),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AdminColors.textLight,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Dates.weekday(days[i].day),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textGrey,
                        ),
                      ),
                      Text(
                        Dates.short(days[i].day),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AdminColors.textLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AdminColors.textDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = days[group.x];
              return BarTooltipItem(
                '${Money.format(day.revenue)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: '${day.orders} order${day.orders == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFFB9C4D4),
                      fontWeight: FontWeight.w400,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].revenue,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  // The last bar is today — highlighted so the owner's eye
                  // lands on the number they care about most.
                  color: i == days.length - 1
                      ? AdminColors.primary
                      : AdminColors.primaryLight.withValues(alpha: 0.45),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionBreakdown extends StatelessWidget {
  const _SectionBreakdown({required this.sections});

  final List<SectionSales> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox(
        height: 240,
        child: EmptyState(
          icon: Icons.pie_chart_outline,
          title: 'Nothing sold yet',
          message: 'Section revenue appears here once orders come in.',
        ),
      );
    }

    const palette = [
      AdminColors.primary,
      AdminColors.teal,
      AdminColors.orange,
      AdminColors.purple,
      AdminColors.success,
    ];
    final total = sections.fold<double>(0, (sum, s) => sum + s.revenue);

    return SizedBox(
      height: 240,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: [
                  for (var i = 0; i < sections.length; i++)
                    PieChartSectionData(
                      value: sections[i].revenue,
                      color: palette[i % palette.length],
                      radius: 42,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < sections.length && i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: palette[i % palette.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      sections[i].section,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  Text(
                    total == 0
                        ? '—'
                        : '${((sections[i].revenue / total) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({required this.orders});

  final List<StoreOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Orders placed in the Niyati Mart app land here instantly.',
      );
    }

    return Column(
      children: [
        for (final order in orders)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order.id),
              ),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: order.status.softColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(order.status.icon, size: 19, color: order.status.color),
            ),
            title: Text(
              order.userName,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '#${order.id} · ${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · '
              '${Dates.relative(order.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AdminColors.textGrey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(order.total),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Pill(
                  label: order.status.label,
                  color: order.status.color,
                  background: order.status.softColor,
                  dense: true,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.products});

  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyState(
        icon: Icons.local_fire_department_outlined,
        title: 'No sales yet',
        message: 'Your best sellers show up here after the first order.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < products.length; i++)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                ImageThumb(url: products[i].image, size: 40),
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AdminColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              products[i].name,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${products[i].unitsSold} sold',
              style: const TextStyle(fontSize: 12, color: AdminColors.textGrey),
            ),
            trailing: Text(
              Money.compact(products[i].revenue),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
