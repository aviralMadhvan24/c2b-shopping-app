import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/utils/cloudinary_url.dart';

/// A representative URL as the admin console stores it after an upload.
const _uploaded =
    'https://res.cloudinary.com/demo/image/upload/v1712345678/niyati/products/kurta.jpg';

String _sized(String url, double displayWidth, {double dpr = 1}) =>
    cloudinaryUrlFor(url, displayWidth: displayWidth, devicePixelRatio: dpr);

void main() {
  group('cloudinaryUrlFor - what gets rewritten', () {
    test('asks for a sized variant of a Cloudinary upload', () {
      expect(
        _sized(_uploaded, 240),
        'https://res.cloudinary.com/demo/image/upload/'
        'f_auto,q_auto,c_limit,w_240/v1712345678/niyati/products/kurta.jpg',
      );
    });

    test('leaves bundled asset paths alone', () {
      expect(_sized('assets/products/kurta.jpg', 240),
          'assets/products/kurta.jpg');
    });

    test('leaves images hosted anywhere else alone', () {
      const other = 'https://example.com/image/upload/shirt.jpg';
      expect(_sized(other, 240), other);
    });

    test('keeps transformations the URL already carries', () {
      const withCrop =
          'https://res.cloudinary.com/demo/image/upload/ar_1:1,c_fill/v1/a.jpg';
      // Ours is prepended as its own component, so Cloudinary chains the two
      // rather than either one being dropped.
      expect(
        _sized(withCrop, 240),
        'https://res.cloudinary.com/demo/image/upload/'
        'f_auto,q_auto,c_limit,w_240/ar_1:1,c_fill/v1/a.jpg',
      );
    });
  });

  group('cloudinaryUrlFor - picking a width', () {
    test('scales the request by the screen density', () {
      // The same 120px box needs three times the pixels on a 3x phone.
      expect(_sized(_uploaded, 120, dpr: 1), contains('w_240'));
      expect(_sized(_uploaded, 120, dpr: 3), contains('w_480'));
    });

    test('rounds up to the next ladder width, never down', () {
      // 241 physical pixels must not be served a 240px image.
      expect(_sized(_uploaded, 241), contains('w_480'));
    });

    test('never asks for more than was uploaded', () {
      expect(_sized(_uploaded, 4000, dpr: 3), contains('w_1400'));
    });

    test('a 72px cart thumbnail stays on the smallest variant', () {
      expect(_sized(_uploaded, 72, dpr: 3), contains('w_240'));
    });

    test('snaps many nearby widths onto few variants', () {
      // The point of the ladder: odd screen widths must not each mint their
      // own derived image, or every one costs a fresh transformation.
      final widths = {
        for (var w = 100; w <= 400; w += 7) _sized(_uploaded, w.toDouble()),
      };
      expect(widths.length, lessThanOrEqualTo(3));
    });

    test('an unmeasured box asks for full width rather than guessing small',
        () {
      // Better a heavy image than a visibly blurry one.
      expect(_sized(_uploaded, 0), contains('w_1400'));
      expect(_sized(_uploaded, double.infinity), contains('w_1400'));
    });
  });
}
