import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataRepository {
  final FirebaseFirestore _firestore;

  UserDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Wishlist stored as subcollection: users/{uid}/wishlist/{productId}
  Future<List<String>> loadWishlist(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  Future<void> addWishlistItem(String uid, String productId) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(productId);
    await ref.set({'addedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeWishlistItem(String uid, String productId) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(productId);
    await ref.delete();
  }

  // Cart stored as subcollection: users/{uid}/cart/{productId} with quantity
  Future<Map<String, int>> loadCart(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();
    final map = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final qty = (data['quantity'] is int)
          ? data['quantity'] as int
          : (data['quantity'] is num ? (data['quantity'] as num).toInt() : 1);
      map[doc.id] = qty;
    }
    return map;
  }

  Future<void> addCartItem(
    String uid,
    String productId, {
    int quantity = 1,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(productId);
    await ref.set({
      'quantity': FieldValue.increment(quantity),
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeCartItem(String uid, String productId) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(productId);
    await ref.delete();
  }

  Future<void> updateCartItemQuantity(
    String uid,
    String productId,
    int quantity,
  ) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(productId);
    if (quantity <= 0) {
      await ref.delete();
    } else {
      await ref.set({'quantity': quantity}, SetOptions(merge: true));
    }
  }
}
