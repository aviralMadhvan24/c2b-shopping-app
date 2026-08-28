import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/theme/app_theme.dart';
import 'package:fashion_store/widgets/product_image.dart';

/// Renders every bundled catalog image through [ProductImage], so the asset
/// pipeline — pubspec registration, the `assets/products/<slug>.jpg` path the
/// seeder writes, and asset-vs-network dispatch — is verified by actually
/// decoding the files rather than only string-matching the paths.
void main() {
  const slugs = <String>[
    'clothes-mens-tshirt',
    'clothes-mens-jeans',
    'clothes-mens-formal-shirt',
    'clothes-womens-kurti',
    'clothes-womens-dress',
    'clothes-hoodie',
    'clothes-jacket',
    'laptop-dell-latitude',
    'laptop-hp-elitebook',
    'laptop-lenovo-thinkpad',
    'laptop-macbook-air',
    'laptop-acer-aspire',
    'printer-hp-laserjet',
    'printer-canon-pixma',
    'printer-epson-ecotank',
    'printer-brother-mono',
    'printer-hp-deskjet',
  ];

  testWidgets('every bundled catalog image decodes', (tester) async {
    tester.view.physicalSize = const Size(1200, 1560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Deliberately no AppTheme here: it pulls Poppins via google_fonts,
    // which tries a real network fetch under runAsync and fails in tests.
    final widget = MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: GridView.count(
          crossAxisCount: 6,
          padding: const EdgeInsets.all(8),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            for (final slug in slugs)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductImage(source: 'assets/products/$slug.jpg'),
              ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(widget);

    // Asset images decode asynchronously; without a real async pump the
    // golden captures empty frames instead of the photographs.
    await tester.runAsync(() async {
      final context = tester.element(find.byType(GridView));
      for (final slug in slugs) {
        await precacheImage(
          AssetImage('assets/products/$slug.jpg'),
          context,
        );
      }
    });

    await tester.pumpAndSettle();

    // No placeholder icons means every asset resolved and decoded.
    expect(find.byIcon(Icons.image_outlined), findsNothing);

    await expectLater(
      find.byType(GridView),
      matchesGoldenFile('catalog_images.png'),
    );
  });
}
