/// Where product and section photos are uploaded.
///
/// Cloudinary rather than Firebase Storage, because Firebase now requires the
/// Blaze billing plan just to provision a Storage bucket. Cloudinary's free
/// tier asks for no card and is far more than this shop needs.
///
/// That tier is **25 credits a month, shared** — not 25 GB of each thing. One
/// credit buys 1 GB of stored images, *or* 1 GB delivered to shoppers, *or*
/// 1,000 transformations, all drawn from the same pot and reset monthly. The
/// practical read for this shop: storing the catalog costs well under a single
/// credit, so essentially the whole allowance is delivery. The customer app
/// spends it carefully — see `lib/utils/cloudinary_url.dart`.
///
/// Uploads are *unsigned*: the browser posts straight to Cloudinary using an
/// upload preset, with no server and no API secret in the app. The trade-off is
/// that the preset name is visible in the shipped JavaScript, so someone who
/// found the console URL could push files into your account. Lock the preset
/// down in the Cloudinary dashboard — folder, max file size, image formats
/// only — and the worst case is wasted quota rather than anything dangerous.
///
/// ## Setting this up (one time, ~3 minutes)
///
/// 1. Sign up free at https://cloudinary.com — no card required.
/// 2. Your **Cloud name** is on the dashboard home. Put it in [cloudName].
/// 3. Go to **Settings → Upload → Upload presets → Add upload preset**:
///    - Signing mode: **Unsigned**
///    - Preset name: `niyati_products` (or anything; put it in [uploadPreset])
///    - Folder: `niyati` — keeps uploads out of your account root
///    - Under the preset's restrictions, set **Max file size** to about
///      10 MB and allowed formats to `jpg,png,webp`
///    - Set **Incoming transformation** to `c_limit,w_1400,q_auto` — the
///      console asks the picker to downscale before uploading, but the *web*
///      picker ignores that request, so on the console this is the only thing
///      standing between a 12 MP phone photo and your storage quota. It also
///      means a photo can never exceed the preset's size cap for being large.
/// 4. Save, then either edit the two constants below or pass them at build
///    time, which keeps them out of the repo:
///
/// ```bash
/// flutter run -d chrome \
///   --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
///   --dart-define=CLOUDINARY_UPLOAD_PRESET=niyati_products
/// ```
class CloudinaryConfig {
  /// Your Cloudinary cloud name.
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  /// The name of the **unsigned** upload preset created above.
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: '',
  );

  /// Folder uploads land in, so the account root stays tidy and the preset can
  /// be restricted to this path.
  static const String folder = 'niyati';

  /// False until both values are filled in. The photo picker checks this and
  /// explains what to do rather than failing with a cryptic 401 mid-upload.
  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  static Uri get uploadEndpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
}
