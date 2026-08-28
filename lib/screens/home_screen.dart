import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_state.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/pagination_provider.dart';
import '../providers/wishlist_provider.dart';
import '../repositories/app_repositories.dart';
import '../theme/app_theme.dart';
import '../services/order_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/auth_gate.dart' show guestModeProvider;
import '../widgets/bottom_navbar.dart';
import '../widgets/product_card.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

import '../repositories/address_repository.dart';
import 'address_screen.dart';
import 'cart_screen.dart';
import 'categories_screen_new.dart';
import '../models/section_model.dart';
import '../providers/section_provider.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart';
import '../widgets/product_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.repositories});

  final AppRepositories repositories;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int currentIndex = 0;
  String searchQuery = '';

  void _toggleWishlist(Product product) {
    final wishlistState = ref.read(wishlistProvider);
    if (wishlistState.items.containsKey(product.id)) {
      ref.read(wishlistProvider.notifier).removeItem(product.id);
    } else {
      ref.read(wishlistProvider.notifier).addItem(product.id);
    }
  }

  bool _isWishlisted(Product product) {
    final wishlistState = ref.watch(wishlistProvider);
    return wishlistState.items.containsKey(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final wishlistCount = ref.watch(wishlistProvider).itemCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.onPrimary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              'assets/brand/niyati-mark.png',
              width: 32,
              height: 32,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Niyati Mart',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            Text(
              'SHOP SMART, SAVE MORE',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.favorite_border,
                  color: AppColors.onPrimary,
                ),
                tooltip: 'Wishlist',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  );
                },
              ),
              if (wishlistCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$wishlistCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.onPrimary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
              ),
              if (cartState.distinctItemCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${cartState.distinctItemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildPage(),
          // Floating cart bar
          if (cartState.distinctItemCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFloatingCartBar(cartState),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        cartCount: cartState.distinctItemCount,
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }

  Widget _buildFloatingCartBar(CartState cartState) {
    final subtotal = cartState.subtotal;
    final itemCount = cartState.distinctItemCount;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag, color: AppColors.onPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatINR(subtotal),
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.onPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Cart',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: AppColors.textDark, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (currentIndex) {
      case 1:
        return const CategoriesScreenNew();
      case 2:
        return _buildSearch();
      case 3:
        return const OrderHistoryScreen();
      case 4:
        return _buildProfile();
      default:
        return _buildHomeBody();
    }
  }

  Widget _buildSearch() {
    final paginationState = ref.watch(paginationProvider);
    final products = paginationState.items;
    final filteredProducts = _filterProducts(products);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'Search for products, brands and more...',
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.textDark),
              suffixIcon: searchQuery.isEmpty
                  ? const Icon(Icons.mic_outlined, color: AppColors.textDark)
                  : IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDark),
                      onPressed: () => setState(() => searchQuery = ''),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, color: AppColors.textLight, size: 56),
                      SizedBox(height: 16),
                      Text(
                        'Search for products',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductCard(
                      product: product,
                      isWishlisted: _isWishlisted(product),
                      onFavoriteTap: () => _toggleWishlist(product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHomeBody() {
    final paginationState = ref.watch(paginationProvider);
    final notifier = ref.read(paginationProvider.notifier);
    final products = paginationState.items;

    if (products.isEmpty && paginationState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (products.isEmpty && paginationState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.textLight, size: 56),
            const SizedBox(height: 16),
            Text(paginationState.error!, style: const TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => notifier.loadNextPage(), child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        notifier.reset();
        await notifier.loadNextPage();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar, on a blue strip continuing the app bar
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () => setState(() => currentIndex = 2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppColors.textGrey, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search for products, brands and more...',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(Icons.mic_none, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Mega Sale Banner
            _buildMegaSaleBanner(),
            const SizedBox(height: 20),
            // Trust strip
            _buildTrustStrip(),
            const SizedBox(height: 20),
            // Top Categories
            _buildTopCategories(),
            const SizedBox(height: 20),
            // Best Offers section
            _buildBestOffers(products),
            const SizedBox(height: 18),
            // Promo Code Banner
            _buildPromoCodeBanner(),
            const SizedBox(height: 12),
            // Free Delivery Banner
            _buildFreeDeliveryBanner(),
            const SizedBox(height: 18),
            // Full catalogue grid so the page does not end on empty space
            _buildAllProducts(products),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMegaSaleBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.teal, AppColors.primary],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔥 MEGA SALE',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'UP TO 50% OFF',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'On Clothes, Laptops & Printers',
              style: TextStyle(color: AppColors.textDark, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SHOP NOW',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories() {
    // Sections come from the `sections` collection the admin console owns.
    // While they are loading, or if the store has none yet, the row is left
    // out entirely rather than showing an empty frame or a stale hardcoded
    // list that the shop may have renamed months ago.
    final sections = ref.watch(sectionsProvider).valueOrNull ?? const <StoreSection>[];
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Top Categories',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final cat = sections[index];
              final count = _categoryCount(cat.name);
              return GestureDetector(
                onTap: () => setState(() => currentIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.tealSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: AppColors.teal, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      if (count > 0)
                        Text(
                          '$count items',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Number of catalogue items in a section, shown on the category tile so
  /// the row carries some information instead of three bare icons.
  int _categoryCount(String label) {
    return ref
        .read(paginationProvider)
        .items
        .where((p) => p.category == label)
        .length;
  }

  /// The reassurance row from the brand sheet: delivery, payment, returns.
  Widget _buildTrustStrip() {
    const items = [
      [Icons.local_shipping_outlined, 'Free Delivery', 'Above ₹499'],
      [Icons.verified_user_outlined, 'Secure Payment', '100% Protected'],
      [Icons.assignment_return_outlined, 'Easy Returns', '7 Day Return'],
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                children: [
                  Icon(item[0] as IconData, color: AppColors.teal, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    item[1] as String,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item[2] as String,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The whole catalogue in a grid. Without this the home page ran out of
  /// content after one horizontal strip and ended on blank background.
  Widget _buildAllProducts(List<Product> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Explore All Products',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                isWishlisted: _isWishlisted(product),
                onFavoriteTap: () => _toggleWishlist(product),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBestOffers(List<Product> products) {
    final bestOffers = products.where((p) => p.hasDiscount).take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Best Offers For You',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => currentIndex = 1),
                child: const Text('View All', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bestOffers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context2, index) {
              final product = bestOffers[index];
              return _BestOfferCard(product: product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCodeBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_offer, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USE CODE NIYATI10',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Get 10% OFF on Your First Order',
                    style: TextStyle(color: AppColors.textDark, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeDeliveryBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping, color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FREE DELIVERY',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'On Orders Above ₹499',
                    style: TextStyle(color: AppColors.textDark, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildProfile() {
    final user = widget.repositories.authRepository.currentUser;
    final isGuest = user == null;
    final wishlistCount = ref.watch(wishlistProvider).itemCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          'My Account',
          style: TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _buildProfileTile(
          Icons.person_outline,
          'Account Details',
          user?.email ?? 'Browsing as guest',
          onTap: () => _showAccountDetails(user),
        ),
        _buildProfileTile(
          Icons.location_on_outlined,
          'Saved Addresses',
          isGuest ? 'Sign in to save addresses' : 'Manage delivery addresses',
          onTap: () => _openAddresses(user),
        ),
        _buildProfileTile(
          Icons.favorite_border,
          'My Wishlist',
          wishlistCount == 0
              ? 'No saved items yet'
              : '$wishlistCount saved ${wishlistCount == 1 ? 'item' : 'items'}',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WishlistScreen()),
          ),
        ),
        _buildProfileTile(
          Icons.receipt_long_outlined,
          'Order History',
          isGuest ? 'Sign in to see your orders' : 'View past orders',
          onTap: () => setState(() => currentIndex = 3),
        ),
        _buildProfileTile(
          Icons.help_outline,
          'Help & Support',
          'FAQs and contact us',
          onTap: _showHelp,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: isGuest
              ? FilledButton.icon(
                  onPressed: _exitGuestMode,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () async {
                    await widget.repositories.authRepository.signOut();
                  },
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Leaves guest mode so AuthGate falls back to the login screen.
  void _exitGuestMode() {
    ref.read(guestModeProvider.notifier).state = false;
  }

  void _showAccountDetails(User? user) {
    if (user == null) {
      _promptSignIn('Sign in to view your account details.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Account Details',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', user.displayName ?? 'Not set'),
            _detailRow('Email', user.email ?? 'Not set'),
            _detailRow(
              'Signed in with',
              user.providerData.isNotEmpty
                  ? user.providerData.first.providerId
                  : 'password',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textDark)),
        ],
      ),
    );
  }

  Future<void> _openAddresses(User? user) async {
    if (user == null) {
      _promptSignIn('Sign in to save delivery addresses.');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressScreen(
          addressRepository: AddressRepository(),
          currentUser: user,
        ),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _helpRow(
              Icons.local_shipping_outlined,
              'Delivery',
              'Orders arrive in 3-5 business days. Free above ${CurrencyFormatter.formatINR(OrderService.freeDeliveryThreshold)}.',
            ),
            _helpRow(
              Icons.payments_outlined,
              'Payment',
              'Cash on Delivery - pay when your order arrives.',
            ),
            _helpRow(
              Icons.cancel_outlined,
              'Cancellations',
              'Cancel free of charge until the order is shipped.',
            ),
            _helpRow(
              Icons.mail_outline,
              'Contact',
              'support@niyatimart.example - replies within 24 hours.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpRow(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _promptSignIn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        action: SnackBarAction(
          label: 'Sign in',
          textColor: AppColors.gold,
          onPressed: _exitGuestMode,
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Classes ───

class _BestOfferCard extends ConsumerWidget {
  final Product product;
  const _BestOfferCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    
    // Find cart item for this product
    final cartItem = cartState.items.values
        .where((item) => item.productId == product.id)
        .firstOrNull;
    final isInCart = cartItem != null;
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: product,
              isWishlisted: false,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(source: product.image),
                    if (product.hasDiscount)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discountPercent}% OFF',
                            style: const TextStyle(color: AppColors.onPrimary, fontSize: 9, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatINR(product.price),
                    style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  if (product.hasDiscount) ...[
                    Text(
                      CurrencyFormatter.formatINR(product.mrp!),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Add to cart button
                  _buildCartButton(ref, isInCart, quantity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(WidgetRef ref, bool isInCart, int quantity) {
    if (isInCart) {
      return Container(
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                final itemKey = '${product.id}_${product.id}';
                ref.read(cartProvider.notifier).decrementQuantity(itemKey);
              },
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: Icon(
                  quantity <= 1 ? Icons.delete_outline : Icons.remove,
                  color: AppColors.onPrimary,
                  size: 16,
                ),
              ),
            ),
            Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () {
                final itemKey = '${product.id}_${product.id}';
                ref.read(cartProvider.notifier).incrementQuantity(itemKey);
              },
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: AppColors.onPrimary, size: 16),
              ),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          ref.read(cartProvider.notifier).addItem(
            productId: product.id,
            variantId: product.id,
            price: product.price,
            productName: product.name,
            productImage: product.image,
            currencyCode: product.currencyCode,
          );
        },
        child: Container(
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.onPrimary, size: 14),
              SizedBox(width: 2),
              Text(
                'ADD',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
