import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'admin_shell.dart';
import 'product_editor_screen.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final search = ref.watch(productSearchProvider).trim().toLowerCase();
    final sectionFilter = ref.watch(productSectionFilterProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorPanel(
        error: e,
        onRetry: () => ref.invalidate(productsProvider),
      ),
      data: (all) {
        final products = all.where((p) {
          if (sectionFilter != null && p.category != sectionFilter) return false;
          if (search.isEmpty) return true;
          return p.name.toLowerCase().contains(search) ||
              p.category.toLowerCase().contains(search) ||
              (p.brand ?? '').toLowerCase().contains(search) ||
              (p.sku ?? '').toLowerCase().contains(search);
        }).toList();

        return AdminPage(
          children: [
            PageHeader(
              title: 'Products',
              subtitle: products.length == all.length
                  ? '${all.length} product${all.length == 1 ? '' : 's'} in the catalog'
                  : '${products.length} of ${all.length} products',
              actions: [
                FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Add product'),
                ),
              ],
            ),
            const _ProductFilters(),
            const SizedBox(height: 16),
            Card(
              child: products.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: all.isEmpty
                          ? 'No products yet'
                          : 'Nothing matches this filter',
                      message: all.isEmpty
                          ? 'Add your first product and it appears in the Niyati '
                              'Mart app straight away.'
                          : 'Try a different search term or section.',
                      action: all.isEmpty
                          ? FilledButton.icon(
                              onPressed: () => _openEditor(context),
                              icon: const Icon(Icons.add, size: 19),
                              label: const Text('Add product'),
                            )
                          : OutlinedButton(
                              onPressed: () {
                                ref.read(productSearchProvider.notifier).state = '';
                                ref
                                    .read(productSectionFilterProvider.notifier)
                                    .state = null;
                              },
                              child: const Text('Clear filters'),
                            ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < products.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _ProductRow(product: products[i]),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  static void _openEditor(BuildContext context, [AdminProduct? product]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductEditorScreen(product: product)),
    );
  }
}

class _ProductFilters extends ConsumerWidget {
  const _ProductFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(sectionsProvider).valueOrNull ?? const [];
    final selected = ref.watch(productSectionFilterProvider);
    final search = ref.watch(productSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          hint: 'Search products by name, brand or SKU',
          value: search,
          onChanged: (v) => ref.read(productSearchProvider.notifier).state = v,
        ),
        if (sections.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SectionChip(
                  label: 'All sections',
                  selected: selected == null,
                  onTap: () =>
                      ref.read(productSectionFilterProvider.notifier).state = null,
                ),
                for (final section in sections)
                  _SectionChip(
                    label: section.name,
                    icon: section.icon,
                    selected: selected == section.name,
                    onTap: () => ref
                        .read(productSectionFilterProvider.notifier)
                        .state = selected == section.name ? null : section.name,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AdminColors.primary : AdminColors.card,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AdminColors.primary : AdminColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? Colors.white : AdminColors.textGrey,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AdminColors.textDark,
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

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});

  final AdminProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNarrow = MediaQuery.sizeOf(context).width < 860;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductEditorScreen(product: product)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            ImageThumb(url: product.image, size: 52, radius: 10),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.name.isEmpty ? 'Untitled product' : product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!product.active) ...[
                        const SizedBox(width: 8),
                        const Pill(
                          label: 'Hidden',
                          color: AdminColors.textGrey,
                          dense: true,
                          icon: Icons.visibility_off_outlined,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      product.category.isEmpty ? 'No section' : product.category,
                      if (product.brand != null && product.brand!.isNotEmpty)
                        product.brand!,
                      if (product.variants.isNotEmpty)
                        '${product.variants.length} variants',
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
            if (!isNarrow) ...[
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Money.format(product.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.hasDiscount)
                      Text(
                        '${Money.format(product.mrp!)} · '
                        '${product.computedDiscountPercent}% off',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AdminColors.success,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: _StockCell(product: product)),
            ] else
              Text(
                Money.format(product.price),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            const SizedBox(width: 6),
            _RowMenu(product: product),
          ],
        ),
      ),
    );
  }
}

/// Stock with an inline stepper — restocking is the single most frequent edit
/// in a small shop, so it does not deserve a round trip through the editor.
class _StockCell extends ConsumerWidget {
  const _StockCell({required this.product});

  final AdminProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = product.isOutOfStock
        ? ('Out of stock', AdminColors.danger)
        : product.isLowStock
            ? ('${product.stock} left', AdminColors.orange)
            : ('${product.stock} in stock', AdminColors.textGrey);

    Future<void> adjust(int delta) async {
      await ref
          .read(productServiceProvider)
          .setStock(product.id, product.stock + delta);
    }

    return Row(
      children: [
        _StepButton(
          icon: Icons.remove,
          onTap: product.stock <= 0 ? null : () => adjust(-1),
        ),
        SizedBox(
          width: 96,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        _StepButton(icon: Icons.add, onTap: () => adjust(1)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminColors.background,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            size: 15,
            color: onTap == null ? AdminColors.textLight : AdminColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _RowMenu extends ConsumerWidget {
  const _RowMenu({required this.product});

  final AdminProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 19, color: AdminColors.textGrey),
      onSelected: (value) async {
        final service = ref.read(productServiceProvider);
        switch (value) {
          case 'edit':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductEditorScreen(product: product),
              ),
            );
          case 'toggle':
            await service.setActive(product.id, !product.active);
            if (context.mounted) {
              showToast(
                context,
                product.active
                    ? '"${product.name}" is hidden from the app.'
                    : '"${product.name}" is live in the app.',
              );
            }
          case 'duplicate':
            // Copying a product is how a shop adds the same shirt in a new
            // colour. The copy starts hidden so a half-edited duplicate never
            // shows up in the storefront.
            final copy = product.copyWith(
              id: '',
              name: '${product.name} (copy)',
              active: false,
              createdAt: DateTime.now(),
            );
            final id = await service.create(copy);
            if (context.mounted) {
              showToast(context, 'Duplicated. The copy is hidden until you publish it.');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductEditorScreen(
                    product: copy.copyWith(id: id),
                  ),
                ),
              );
            }
          case 'delete':
            final ok = await confirmDialog(
              context,
              title: 'Delete this product?',
              message: '"${product.name}" will be removed from the catalog and '
                  'will disappear from the app. Past orders keep their copy of '
                  'the item, so order history stays intact.',
            );
            if (!ok) return;
            await service.delete(product.id);
            if (context.mounted) showToast(context, 'Product deleted.');
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: _MenuRow(Icons.edit_outlined, 'Edit'),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: _MenuRow(
            product.active ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            product.active ? 'Hide from app' : 'Publish to app',
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: _MenuRow(Icons.copy_outlined, 'Duplicate'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuRow(Icons.delete_outline, 'Delete', color: AdminColors.danger),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AdminColors.textGrey),
        const SizedBox(width: 11),
        Text(label, style: TextStyle(fontSize: 13.5, color: color)),
      ],
    );
  }
}
