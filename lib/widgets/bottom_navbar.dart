import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int cartCount;
  final int wishlistCount;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
    this.wishlistCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: _iconWithBadge(const Icon(Icons.favorite), wishlistCount),
          label: "Wishlist",
        ),
        BottomNavigationBarItem(
          icon: _iconWithBadge(const Icon(Icons.shopping_cart), cartCount),
          label: "Cart",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}

Widget _iconWithBadge(Widget icon, int count) {
  if (count <= 0) return icon;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      icon,
      Positioned(
        right: -6,
        top: -6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}
