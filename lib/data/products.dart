import '../models/product_model.dart';

List<Product> products = [
  Product(
    id: "demo-men-hoodie",
    name: "Men Hoodie",
    image: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab",
    price: 59.99,
    category: "Men",
    rating: 4.8,
    description: "Premium oversized hoodie for men.",
    variants: [
      ProductVariant(
        id: "demo-men-hoodie-black-m",
        title: "Black / M",
        price: 59.99,
        quantityAvailable: 12,
        selectedOptions: {"Color": "Black", "Size": "M"},
      ),
      ProductVariant(
        id: "demo-men-hoodie-black-l",
        title: "Black / L",
        price: 59.99,
        quantityAvailable: 8,
        selectedOptions: {"Color": "Black", "Size": "L"},
      ),
    ],
  ),
  Product(
    id: "demo-women-jacket",
    name: "Women Jacket",
    image: "https://images.unsplash.com/photo-1529139574466-a303027c1d8b",
    price: 89.99,
    category: "Women",
    rating: 4.9,
    description: "Luxury winter jacket.",
    variants: [
      ProductVariant(
        id: "demo-women-jacket-cream-s",
        title: "Cream / S",
        price: 89.99,
        quantityAvailable: 6,
        selectedOptions: {"Color": "Cream", "Size": "S"},
      ),
      ProductVariant(
        id: "demo-women-jacket-cream-m",
        title: "Cream / M",
        price: 89.99,
        quantityAvailable: 10,
        selectedOptions: {"Color": "Cream", "Size": "M"},
      ),
    ],
  ),
  Product(
    id: "demo-kids-wear",
    name: "Kids Wear",
    image: "https://images.unsplash.com/photo-1512436991641-6745cdb1723f",
    price: 29.99,
    category: "Children",
    rating: 4.5,
    description: "Comfortable children clothing.",
    variants: [
      ProductVariant(
        id: "demo-kids-wear-blue-4y",
        title: "Blue / 4Y",
        price: 29.99,
        quantityAvailable: 14,
        selectedOptions: {"Color": "Blue", "Size": "4Y"},
      ),
      ProductVariant(
        id: "demo-kids-wear-blue-6y",
        title: "Blue / 6Y",
        price: 29.99,
        quantityAvailable: 9,
        selectedOptions: {"Color": "Blue", "Size": "6Y"},
      ),
    ],
  ),
  Product(
    id: "demo-wireless-headphones",
    name: "Wireless Headphones",
    image: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e",
    price: 149.99,
    category: "Gadgets",
    rating: 5.0,
    description: "Noise cancelling headphones.",
    variants: [
      ProductVariant(
        id: "demo-wireless-headphones-black",
        title: "Black",
        price: 149.99,
        quantityAvailable: 5,
        selectedOptions: {"Color": "Black"},
      ),
    ],
  ),
];
