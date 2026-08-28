import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/data/products.dart';
import 'package:fashion_store/models/address_model.dart';
import 'package:fashion_store/models/app_settings_model.dart';
import 'package:fashion_store/models/user_profile_model.dart';
import 'package:fashion_store/models/wishlist_item_model.dart';

void main() {
  test('demo products include production identifiers and variants', () {
    expect(products, isNotEmpty);

    for (final product in products) {
      expect(product.id, isNotEmpty);
      expect(product.defaultVariant, isNotNull);
      expect(product.defaultVariant!.id, isNotEmpty);
      expect(product.defaultVariant!.selectedOptions, isNotEmpty);
    }
  });

  test('user profile serializes to Firestore-style map', () {
    final profile = UserProfile(
      id: 'user-1',
      name: 'Avi',
      email: 'avi@example.com',
      phone: '+911234567890',
      createdAt: DateTime.utc(2026, 1, 1),
      defaultAddressId: 'address-1',
    );

    final copy = UserProfile.fromMap(profile.id, profile.toMap());

    expect(copy.id, profile.id);
    expect(copy.name, profile.name);
    expect(copy.email, profile.email);
    expect(copy.phone, profile.phone);
    expect(copy.createdAt, profile.createdAt);
    expect(copy.defaultAddressId, profile.defaultAddressId);
  });

  test('address serializes to Firestore-style map', () {
    const address = Address(
      id: 'address-1',
      name: 'Avi',
      phone: '+911234567890',
      line1: '221 Market Street',
      city: 'Mumbai',
      state: 'Maharashtra',
      postalCode: '400001',
      country: 'India',
      isDefault: true,
    );

    final copy = Address.fromMap(address.id, address.toMap());

    expect(copy.id, address.id);
    expect(copy.name, address.name);
    expect(copy.isDefault, isTrue);
  });

  test('wishlist item stores only product and variant references', () {
    final item = WishlistItem(
      productId: 'product-1',
      variantId: 'variant-1',
      addedAt: DateTime.utc(2026, 1, 1),
    );

    final map = item.toMap();
    final copy = WishlistItem.fromMap(map);

    expect(map.keys, containsAll(['productId', 'variantId', 'addedAt']));
    expect(map.containsKey('name'), isFalse);
    expect(map.containsKey('price'), isFalse);
    expect(copy.productId, item.productId);
    expect(copy.variantId, item.variantId);
    expect(copy.addedAt, item.addedAt);
  });

  test('app settings provide safe defaults', () {
    final settings = AppSettings.fromMap({});

    expect(settings.maintenanceMode, isFalse);
    expect(settings.featuredCollectionId, isNull);
    expect(settings.supportEmail, 'support@example.com');
  });
}
