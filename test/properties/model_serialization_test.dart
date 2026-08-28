// Feature: app-completion, Property 1: Model Serialization Round-Trip
// **Validates: Requirements 14.1, 14.7, 14.8**
//
// For any valid instance of Product, Address, UserProfile, WishlistItem,
// AppSettings, or CartItem, serializing to a map via toMap() and then
// deserializing from that map via fromMap() produces an object with field
// values identical to the original.

import 'package:glados/glados.dart';
import 'package:fashion_store/models/product_model.dart';
import 'package:fashion_store/models/address_model.dart';
import 'package:fashion_store/models/user_profile_model.dart';
import 'package:fashion_store/models/wishlist_item_model.dart';
import 'package:fashion_store/models/app_settings_model.dart';
import 'package:fashion_store/models/cart_item_model.dart';

// --- Custom Generators ---

extension ModelGenerators on Any {
  Generator<String> get nonEmptyString => nonEmptyLetterOrDigits;

  Generator<double> get positivePrice =>
      doubleInRange(0.01, 9999.99).map((d) => (d * 100).round() / 100.0);

  Generator<int> get positiveQuantity => intInRange(1, 100);

  Generator<DateTime> get safeDateTime =>
      intInRange(0, 2000000000000).map(
        (ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      );

  Generator<Map<String, String>> get selectedOptionsMap =>
      listWithLengthInRange(0, 4, combine2(
        nonEmptyLetterOrDigits,
        nonEmptyLetterOrDigits,
        (String key, String value) => MapEntry(key, value),
      )).map((entries) => Map.fromEntries(entries));

  Generator<ProductVariant> get productVariant => combine7(
        nonEmptyString, // id
        nonEmptyString, // title
        positivePrice, // price
        nonEmptyString, // currencyCode
        choose([false, true]), // availableForSale
        positiveIntOrZero.nullable, // quantityAvailable
        selectedOptionsMap, // selectedOptions
        (String id, String title, double price, String currencyCode,
                bool availableForSale, int? quantityAvailable,
                Map<String, String> selectedOptions) =>
            ProductVariant(
          id: id,
          title: title,
          price: price,
          currencyCode: currencyCode,
          availableForSale: availableForSale,
          quantityAvailable: quantityAvailable,
          selectedOptions: selectedOptions,
        ),
      );

  Generator<Product> get product => combine9(
        nonEmptyString, // id
        nonEmptyString, // name
        nonEmptyString, // image
        positivePrice, // price
        nonEmptyString, // currencyCode
        nonEmptyString, // category
        doubleInRange(0.0, 5.0), // rating
        nonEmptyString, // description
        listWithLengthInRange(0, 3, productVariant), // variants
        (String id, String name, String image, double price,
                String currencyCode, String category, double rating,
                String description, List<ProductVariant> variants) =>
            Product(
          id: id,
          name: name,
          image: image,
          price: price,
          currencyCode: currencyCode,
          category: category,
          rating: rating,
          description: description,
          variants: variants,
        ),
      );

  Generator<Address> get address => combine10(
        nonEmptyString, // id
        nonEmptyString, // name
        nonEmptyString, // phone
        nonEmptyString, // line1
        nonEmptyString.nullable, // line2
        nonEmptyString, // city
        nonEmptyString, // state
        nonEmptyString, // postalCode
        nonEmptyString, // country
        choose([false, true]), // isDefault
        (String id, String name, String phone, String line1, String? line2,
                String city, String state, String postalCode, String country,
                bool isDefault) =>
            Address(
          id: id,
          name: name,
          phone: phone,
          line1: line1,
          line2: line2,
          city: city,
          state: state,
          postalCode: postalCode,
          country: country,
          isDefault: isDefault,
        ),
      );

  Generator<UserProfile> get userProfile => combine6(
        nonEmptyString, // id
        nonEmptyString.nullable, // name
        nonEmptyString.nullable, // email
        nonEmptyString.nullable, // phone
        safeDateTime, // createdAt
        nonEmptyString.nullable, // defaultAddressId
        (String id, String? name, String? email, String? phone,
                DateTime createdAt, String? defaultAddressId) =>
            UserProfile(
          id: id,
          name: name,
          email: email,
          phone: phone,
          createdAt: createdAt,
          defaultAddressId: defaultAddressId,
        ),
      );

  Generator<WishlistItem> get wishlistItem => combine3(
        nonEmptyString, // productId
        nonEmptyString.nullable, // variantId
        safeDateTime, // addedAt
        (String productId, String? variantId, DateTime addedAt) => WishlistItem(
          productId: productId,
          variantId: variantId,
          addedAt: addedAt,
        ),
      );

  Generator<AppSettings> get appSettings => combine3(
        choose([false, true]), // maintenanceMode
        nonEmptyString.nullable, // featuredCollectionId
        nonEmptyString, // supportEmail
        (bool maintenanceMode, String? featuredCollectionId,
                String supportEmail) =>
            AppSettings(
          maintenanceMode: maintenanceMode,
          featuredCollectionId: featuredCollectionId,
          supportEmail: supportEmail,
        ),
      );

  Generator<CartItem> get cartItem => combine7(
        nonEmptyString, // productId
        nonEmptyString, // variantId
        nonEmptyString, // productName
        nonEmptyString, // productImage
        positivePrice, // price
        nonEmptyString, // currencyCode
        positiveQuantity, // quantity
        (String productId, String variantId, String productName,
                String productImage, double price, String currencyCode,
                int quantity) =>
            CartItem(
          productId: productId,
          variantId: variantId,
          productName: productName,
          productImage: productImage,
          price: price,
          currencyCode: currencyCode,
          quantity: quantity,
        ),
      );
}

void main() {
  group('Property 1: Model Serialization Round-Trip', () {
    Glados(any.product, ExploreConfig(numRuns: 100)).test(
      'Product round-trip: fromMap(toMap()) produces identical instance',
      (Product product) {
        final map = product.toMap();
        final restored = Product.fromMap(map);

        expect(restored.id, equals(product.id));
        expect(restored.name, equals(product.name));
        expect(restored.image, equals(product.image));
        expect(restored.price, equals(product.price));
        expect(restored.currencyCode, equals(product.currencyCode));
        expect(restored.category, equals(product.category));
        expect(restored.rating, equals(product.rating));
        expect(restored.description, equals(product.description));
        expect(restored.variants.length, equals(product.variants.length));
        for (var i = 0; i < product.variants.length; i++) {
          expect(restored.variants[i], equals(product.variants[i]));
        }
        expect(restored, equals(product));
      },
    );

    Glados(any.address, ExploreConfig(numRuns: 100)).test(
      'Address round-trip: fromMap(id, toMap()) produces identical instance',
      (Address address) {
        final map = address.toMap();
        final restored = Address.fromMap(address.id, map);

        expect(restored.id, equals(address.id));
        expect(restored.name, equals(address.name));
        expect(restored.phone, equals(address.phone));
        expect(restored.line1, equals(address.line1));
        expect(restored.line2, equals(address.line2));
        expect(restored.city, equals(address.city));
        expect(restored.state, equals(address.state));
        expect(restored.postalCode, equals(address.postalCode));
        expect(restored.country, equals(address.country));
        expect(restored.isDefault, equals(address.isDefault));
        expect(restored, equals(address));
      },
    );

    Glados(any.userProfile, ExploreConfig(numRuns: 100)).test(
      'UserProfile round-trip: fromMap(id, toMap()) produces identical instance',
      (UserProfile profile) {
        final map = profile.toMap();
        final restored = UserProfile.fromMap(profile.id, map);

        expect(restored.id, equals(profile.id));
        expect(restored.name, equals(profile.name));
        expect(restored.email, equals(profile.email));
        expect(restored.phone, equals(profile.phone));
        expect(restored.createdAt, equals(profile.createdAt));
        expect(restored.defaultAddressId, equals(profile.defaultAddressId));
        expect(restored, equals(profile));
      },
    );

    Glados(any.wishlistItem, ExploreConfig(numRuns: 100)).test(
      'WishlistItem round-trip: fromMap(toMap()) produces identical instance',
      (WishlistItem item) {
        final map = item.toMap();
        final restored = WishlistItem.fromMap(map);

        expect(restored.productId, equals(item.productId));
        expect(restored.variantId, equals(item.variantId));
        expect(restored.addedAt, equals(item.addedAt));
        expect(restored, equals(item));
      },
    );

    Glados(any.appSettings, ExploreConfig(numRuns: 100)).test(
      'AppSettings round-trip: fromMap(toMap()) produces identical instance',
      (AppSettings settings) {
        final map = settings.toMap();
        final restored = AppSettings.fromMap(map);

        expect(restored.maintenanceMode, equals(settings.maintenanceMode));
        expect(restored.featuredCollectionId,
            equals(settings.featuredCollectionId));
        expect(restored.supportEmail, equals(settings.supportEmail));
        expect(restored, equals(settings));
      },
    );

    Glados(any.cartItem, ExploreConfig(numRuns: 100)).test(
      'CartItem round-trip: fromMap(toMap()) produces identical instance',
      (CartItem item) {
        final map = item.toMap();
        final restored = CartItem.fromMap(map);

        expect(restored.productId, equals(item.productId));
        expect(restored.variantId, equals(item.variantId));
        expect(restored.productName, equals(item.productName));
        expect(restored.productImage, equals(item.productImage));
        expect(restored.price, equals(item.price));
        expect(restored.currencyCode, equals(item.currencyCode));
        expect(restored.quantity, equals(item.quantity));
        expect(restored, equals(item));
      },
    );
  });
}
