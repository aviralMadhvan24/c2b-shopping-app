import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/paginated_result.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirebaseProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Drops the products the admin console has unpublished.
  ///
  /// Filtered here rather than with `where('active', isEqualTo: true)` on the
  /// query: Firestore does not match documents that lack the field at all, so
  /// a server-side filter would hide every product created before the console
  /// existed. `Product.fromMap` defaults a missing `active` to true, and this
  /// keeps that decision in one place.
  List<Product> _published(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((product) => product.active)
        .toList();
  }

  @override
  Future<PaginatedResult<Product>> fetchProducts({String? cursor, int first = 20}) async {
    try {
      final snapshot = await _firestore.collection('products').limit(first).get();
      return PaginatedResult(
        items: _published(snapshot.docs),
        nextCursor: null,
        hasNextPage: false,
      );
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  @override
  Future<List<Product>> fetchProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();
      return _published(snapshot.docs);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Product> fetchProductById(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (!doc.exists) {
        throw Exception('Product not found: $id');
      }
      // Deliberately not filtered on `active`: a cart, a wishlist entry or a
      // past order still has to resolve a product the shop has since hidden.
      // Hiding removes it from browsing, not from the customer's own history.
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      if (e.toString().contains('not found')) rethrow;
      throw Exception('Failed to fetch product: $e');
    }
  }
}
