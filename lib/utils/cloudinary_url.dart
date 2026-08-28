/// Rewrites Cloudinary delivery URLs so the app downloads an image at the size
/// it actually draws, instead of the full-size original.
///
/// The admin console uploads photos capped at 1400px (see
/// `admin_app/lib/config/cloudinary_config.dart`). Without this, a 96px grid
/// thumbnail still pulls all ~200 KB of that original down the wire — the
/// catalog grid alone would move roughly ten times more data than it needs.
///
/// That matters because Cloudinary's free plan is **25 credits a month shared
/// between storage and bandwidth** (1 credit = 1 GB of either). Storage for a
/// shop this size is a rounding error; delivery is what actually spends the
/// allowance, so serving right-sized bytes is most of the bill.
///
/// Transformations cost credits too — 1 per 1,000 — but only the *first*
/// request for a given size pays. Cloudinary caches the derived image on its
/// CDN afterwards, which is why [_widthLadder] exists: snapping to a handful of
/// widths means an image is only ever derived a few times, instead of once per
/// odd screen width in the wild.
library;

/// The only widths ever requested. Deliberately short — see above.
const List<int> _widthLadder = [240, 480, 720, 1080, 1400];

/// Marks the point in a delivery URL where transformations belong:
/// `https://res.cloudinary.com/<cloud>/image/upload/<here>/v123/folder/id.jpg`
const String _uploadSegment = '/image/upload/';

/// Smallest ladder width that covers [target] physical pixels, or the largest
/// available when the screen asks for more than was ever uploaded.
int _ladderWidthFor(double target) {
  for (final width in _widthLadder) {
    if (width >= target) return width;
  }
  return _widthLadder.last;
}

/// Returns [url] asking for a variant [displayWidth] logical pixels wide on a
/// screen of [devicePixelRatio], or [url] untouched when it is not a Cloudinary
/// image URL — bundled assets, seeded catalog photos and any other host all
/// pass through unchanged.
///
/// [displayWidth] may be zero or infinite: an unbounded or not-yet-laid-out box
/// tells us nothing about the size needed, so those ask for the full width
/// rather than guessing small and rendering a blurry image.
String cloudinaryUrlFor(
  String url, {
  required double displayWidth,
  required double devicePixelRatio,
}) {
  final uploadIndex = url.indexOf(_uploadSegment);
  if (uploadIndex == -1 || !url.startsWith('https://res.cloudinary.com/')) {
    return url;
  }

  final isMeasured = displayWidth > 0 && displayWidth.isFinite;
  final width = isMeasured
      ? _ladderWidthFor(displayWidth * devicePixelRatio)
      : _widthLadder.last;

  // `c_limit` never upscales, so a photo smaller than the requested width is
  // served as-is instead of being blown up. `f_auto` serves WebP/AVIF to
  // browsers and devices that take it, `q_auto` picks a quality that holds up
  // at the delivered size.
  final insertAt = uploadIndex + _uploadSegment.length;
  return '${url.substring(0, insertAt)}'
      'f_auto,q_auto,c_limit,w_$width/'
      '${url.substring(insertAt)}';
}
