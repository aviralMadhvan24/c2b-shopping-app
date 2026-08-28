import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../providers/pagination_provider.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

/// Resolves the product ids held in the wishlist into full [Product]s.
///
/// The wishlist itself only stores ids (that is all that is synced to
/// Firestore), so the catalog has to be consulted to render cards. Ids that
/// no longer resolve — a delisted product — are dropped rather than failing
/// the whole screen.
final wishlistProductsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) async {
    final ids = ref.watch(wishlistProvider).items.keys.toList();
    if (ids.isEmpty) return const [];

    final repository = ref.watch(productRepositoryProvider);
    final results = await Future.wait(
      ids.map((id) async {
        try {
          return await repository.fetchProductById(id);
        } catch (_) {
          return null;
        }
      }),
    );
    return results.whereType<Product>().toList();
  },
);

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key, this.showAppBar = true});

  /// When embedded as a home tab the surrounding scaffold already supplies
  /// an app bar, so the screen renders its own only when pushed as a route.
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProductsProvider);

    final body = wishlistAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (_, _) => _Message(
        icon: Icons.error_outline,
        title: 'Could not load your wishlist',
        subtitle: 'Check your connection and try again.',
        action: FilledButton(
          onPressed: () => ref.invalidate(wishlistProductsProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const _Message(
            icon: Icons.favorite_border,
            title: 'Your wishlist is empty',
            subtitle: 'Tap the heart on any product to save it here.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              isWishlisted: true,
              onFavoriteTap: () =>
                  ref.read(wishlistProvider.notifier).removeItem(product.id),
            );
          },
        );
      },
    );

    if (!showAppBar) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('My Wishlist', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: body,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
