import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/cloudinary_url.dart';

/// Renders a product image from either a bundled asset path
/// (`assets/products/...`) or a remote URL, with a consistent
/// placeholder for missing/broken images.
///
/// Seeded catalog products ship as bundled assets so the catalog
/// renders offline; remote URLs stay supported for products added
/// later from an admin/backend that stores hosted image URLs.
///
/// Remote photos go through two bandwidth savings, because delivery is what
/// spends the Cloudinary free allowance (see [cloudinaryUrlFor]):
/// the URL is rewritten to the size this box actually draws, and the bytes are
/// cached to disk so a second look at the same product costs nothing.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIconSize = 40,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double placeholderIconSize;

  bool get _isRemote =>
      source.startsWith('http://') || source.startsWith('https://');

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.surface,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: AppColors.textLight,
            size: placeholderIconSize,
          ),
        ),
      );

  /// The width this image will be drawn at, in logical pixels.
  ///
  /// Callers pass anything from a hard 72 to `double.infinity` to nothing at
  /// all, so the widget's own [width] is only trusted when it is a real
  /// measurement; otherwise the surrounding box is measured instead.
  double _displayWidth(BoxConstraints constraints) {
    final given = width;
    if (given != null && given > 0 && given.isFinite) return given;
    return constraints.maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return _placeholder();

    if (_isRemote) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final url = cloudinaryUrlFor(
            source,
            displayWidth: _displayWidth(constraints),
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          );

          return CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            errorWidget: (_, _, _) => _placeholder(),
            // A static placeholder rather than a spinner: an indeterminate
            // progress indicator animates forever while an image is pending,
            // which never lets `pumpAndSettle` settle in widget tests.
            placeholder: (_, _) => _placeholder(),
          );
        },
      );
    }

    return Image.asset(
      source,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }
}
