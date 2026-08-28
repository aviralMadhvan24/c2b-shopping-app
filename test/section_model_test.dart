import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/models/section_model.dart';
import 'package:fashion_store/models/product_model.dart';

void main() {
  group('StoreSection.fromMap', () {
    test('reads the document the admin console writes', () {
      final section = StoreSection.fromMap('s1', {
        'name': 'Second-hand Laptops',
        'iconKey': 'laptop',
        'imageUrl': 'https://example.com/banner.jpg',
        'sortOrder': 2,
        'active': true,
      });

      expect(section.id, 's1');
      expect(section.name, 'Second-hand Laptops');
      expect(section.icon, Icons.laptop_mac);
      expect(section.sortOrder, 2);
      expect(section.active, isTrue);
    });

    test('defaults a partial document rather than dropping the section', () {
      final section = StoreSection.fromMap('s1', {'name': 'Clothes'});

      expect(section.iconKey, 'category');
      expect(section.sortOrder, 0);
      // Absent `active` means visible — a section is not hidden by omission.
      expect(section.active, isTrue);
      expect(section.imageUrl, isNull);
    });

    test('falls back to a generic icon for a key this build does not know, so '
        'a newer console cannot break an older app', () {
      final section = StoreSection.fromMap('s1', {
        'name': 'Drones',
        'iconKey': 'some-future-icon',
      });

      expect(section.icon, Icons.category_outlined);
    });
  });

  group('SectionIcons', () {
    test('covers the keys the console seeds by default', () {
      for (final key in ['checkroom', 'laptop', 'print', 'category']) {
        expect(SectionIcons.all.containsKey(key), isTrue, reason: key);
      }
    });
  });

  group('Product.active', () {
    test('treats a product with no active field as published', () {
      final product = Product.fromMap({
        'name': 'Legacy product',
        'price': 100,
        'category': 'Clothes',
      }, 'p1');

      expect(product.active, isTrue);
    });

    test('reads an explicit false so the console can hide a product', () {
      final product = Product.fromMap({
        'name': 'Hidden product',
        'price': 100,
        'category': 'Clothes',
        'active': false,
      }, 'p1');

      expect(product.active, isFalse);
    });

    test('survives a round trip through the map', () {
      const product = Product(
        id: 'p1',
        name: 'Kurta',
        image: '',
        price: 799,
        category: 'Clothes',
        rating: 4,
        description: '',
        active: false,
      );

      expect(Product.fromMap(product.toMap()), product);
    });

    test('distinguishes two products that differ only by publish state', () {
      const shown = Product(
        id: 'p1',
        name: 'Kurta',
        image: '',
        price: 799,
        category: 'Clothes',
        rating: 4,
        description: '',
      );
      final hidden = Product.fromMap({...shown.toMap(), 'active': false});

      expect(hidden == shown, isFalse);
    });
  });
}
