import 'package:flutter/material.dart';
import '../config/production_settings.dart';
import '../models/product_model.dart';
import '../repositories/app_repositories.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/product_card.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repositories});

  final AppRepositories repositories;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  String searchQuery = '';
  final List<Product> cartProducts = [];
  final List<Product> wishlistProducts = [];
  late Future<List<Product>> productsFuture;

  static const categories = [
    _CategoryLink('Men', Icons.man),
    _CategoryLink('Women', Icons.woman),
    _CategoryLink('Children', Icons.child_care),
    _CategoryLink('Gadgets', Icons.devices),
  ];

  @override
  void initState() {
    super.initState();
    productsFuture = widget.repositories.productRepository.fetchProducts();
  }

  void _toggleWishlist(Product product) {
    setState(() {
      if (_isWishlisted(product)) {
        wishlistProducts.removeWhere((item) => item.id == product.id);
      } else {
        wishlistProducts.add(product);
      }
    });
  }

  void _addToCart(Product product) {
    setState(() {
      if (!_isInCart(product)) {
        cartProducts.add(product);
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      cartProducts.removeWhere((item) => item.id == product.id);
    });
  }

  bool _isWishlisted(Product product) {
    return wishlistProducts.any((item) => item.id == product.id);
  }

  bool _isInCart(Product product) {
    return cartProducts.any((item) => item.id == product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: ProductionSettings.brandName,
        cartCount: cartProducts.length,
        onCartTap: () => setState(() => currentIndex = 2),
      ),
      body: _buildPage(),
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        cartCount: cartProducts.length,
        wishlistCount: wishlistProducts.length,
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }

  Widget _buildPage() {
    switch (currentIndex) {
      case 1:
        return _buildWishlist();
      case 2:
        return _buildCart();
      case 3:
        return _buildProfile();
      default:
        return _buildHomeBody();
    }
  }

  Widget _buildHomeBody() {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingState();
        }

        final products = snapshot.data ?? [];
        final filteredProducts = _filterProducts(products);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              productsFuture = widget.repositories.productRepository
                  .fetchProducts();
            });
            await productsFuture;
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                sliver: SliverList.list(
                  children: [
                    const _HomeHeader(),
                    const SizedBox(height: 18),
                    _SearchField(
                      value: searchQuery,
                      onChanged: (value) => setState(() {
                        searchQuery = value;
                      }),
                    ),
                    const SizedBox(height: 20),
                    _PromoBanner(
                      productCount: products.length,
                      onTap: () => setState(() => searchQuery = ''),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Shop by category',
                      actionLabel: 'View all',
                      onAction: () => setState(() => searchQuery = ''),
                    ),
                    const SizedBox(height: 12),
                    _CategoryScroller(
                      categories: categories,
                      onTap: _openCategory,
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: searchQuery.isEmpty ? 'Featured products' : 'Results',
                      actionLabel: '${filteredProducts.length} items',
                    ),
                  ],
                ),
              ),
              if (filteredProducts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    message: 'Try another search or browse a category.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid.builder(
                    itemCount: filteredProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.48,
                        ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        isWishlisted: _isWishlisted(product),
                        isInCart: _isInCart(product),
                        onFavoriteTap: () => _toggleWishlist(product),
                        onAddToCartTap: () => _addToCart(product),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return products;
    }

    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
    }).toList();
  }

  void _openCategory(_CategoryLink category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          category: category.value,
          repositories: widget.repositories,
          onToggleWishlist: _toggleWishlist,
          onAddToCart: _addToCart,
          isWishlisted: _isWishlisted,
          isInCart: _isInCart,
        ),
      ),
    );
  }

  Widget _buildWishlist() {
    if (wishlistProducts.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_border,
        title: 'Your wishlist is empty',
        message: 'Save products you love and find them here later.',
      );
    }

    return _ProductListPage(
      title: 'Wishlist',
      products: wishlistProducts,
      trailingBuilder: (product) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.favorite, color: Color(0xFFE25563)),
            onPressed: () => _toggleWishlist(product),
          ),
          IconButton(
            tooltip: 'Add to cart',
            icon: Icon(
              _isInCart(product) ? Icons.shopping_cart : Icons.add_shopping_cart,
              color: Colors.white,
            ),
            onPressed: () => _addToCart(product),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    if (cartProducts.isEmpty) {
      return const _EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        message: 'Add products to your cart before checkout.',
      );
    }

    final subtotal = cartProducts.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );

    return Column(
      children: [
        Expanded(
          child: _ProductListPage(
            title: 'Cart',
            products: cartProducts,
            trailingBuilder: (product) => IconButton(
              tooltip: 'Remove from cart',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE25563)),
              onPressed: () => _removeFromCart(product),
            ),
          ),
        ),
        _CheckoutSummary(
          subtotal: subtotal,
          itemCount: cartProducts.length,
          onCheckout: () {},
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        _SectionHeader(title: 'Profile'),
        SizedBox(height: 12),
        _AccountBanner(),
        SizedBox(height: 16),
        _ProfileAction(
          icon: Icons.person_outline,
          title: 'Sign in',
          subtitle: 'Email/password and Google sign-in will be enabled.',
        ),
        _ProfileAction(
          icon: Icons.location_on_outlined,
          title: 'Saved addresses',
          subtitle: 'Available for logged-in users.',
        ),
        _ProfileAction(
          icon: Icons.receipt_long_outlined,
          title: 'Order history',
          subtitle: 'Synced after Shopify checkout integration.',
        ),
        _ProfileAction(
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle: 'Order updates and promotions via Firebase Messaging.',
        ),
      ],
    );
  }
}

class _CategoryLink {
  const _CategoryLink(this.value, this.icon);

  final String value;
  final IconData icon;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4AF37),
            Color(0xFF8B7500),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SUMMER 2026',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Premium\nCollection',
            style: TextStyle(
              color: Colors.black,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Luxury fashion curated for modern style.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1B1B1B),
        hintText: 'Search products, categories, styles',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        suffixIcon: value.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => onChanged(''),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.productCount,
    required this.onTap,
  });

  final int productCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF232526),
              Color(0xFF414345),
            ],
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 Trending Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Discover premium fashion pieces and latest arrivals.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$productCount Items',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({required this.categories, required this.onTap});

  final List<_CategoryLink> categories;
  final ValueChanged<_CategoryLink> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () => onTap(category),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category.icon, color: Colors.white, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    category.value == 'Children' ? 'Kids' : category.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _ProductListPage extends StatelessWidget {
  const _ProductListPage({
    required this.title,
    required this.products,
    required this.trailingBuilder,
  });

  final String title;
  final List<Product> products;
  final Widget Function(Product product) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: products.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _SectionHeader(title: title, actionLabel: '${products.length}');
        }

        final product = products[index - 1];
        return _ProductRow(
          product: product,
          trailing: trailingBuilder(product),
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.trailing});

  final Product product;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              product.image,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ImageFallback(size: 68),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.category} • ${product.variants.length} variant(s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(product),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.subtotal,
    required this.itemCount,
    required this.onCheckout,
  });

  final double subtotal;
  final int itemCount;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$itemCount item(s)',
                  style: const TextStyle(color: Colors.white60),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onCheckout,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Continue to secure checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBanner extends StatelessWidget {
  const _AccountBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF2E6F5E),
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest customer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Guest checkout stays available. Sign in unlocks saved data.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF242424),
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38),
    );
  }
}

String _formatPrice(Product product) {
  final symbol = product.currencyCode == 'USD' ? r'$' : '${product.currencyCode} ';
  return '$symbol${product.price.toStringAsFixed(2)}';
}
