import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/cloudinary_config.dart';

/// Uploads product and section photos to Cloudinary and hands back the public
/// URL that gets stored on the document.
///
/// See [CloudinaryConfig] for why this is not Firebase Storage and how to set
/// the account up. Uploads are unsigned, so this needs no server and no secret.
///
/// Bytes are read through [XFile.readAsBytes] rather than a `File` path so the
/// same code works on web (where there is no filesystem path) and on mobile if
/// this console is later built for Android.
class StorageService {
  final http.Client _client;
  final ImagePicker _picker;

  StorageService({http.Client? client, ImagePicker? picker})
      : _client = client ?? http.Client(),
        _picker = picker ?? ImagePicker();

  /// Photos are re-encoded down to this before upload. A shop owner's phone
  /// camera produces 4-8 MB files; a storefront thumbnail needs nothing like
  /// that, and the smaller upload is the difference between an instant save
  /// and a minute of spinner on a slow connection.
  ///
  /// **On web these are ignored** — `image_picker_for_web` does not resize, and
  /// the console is a web app. The preset's incoming transformation is what
  /// actually caps the stored size there; see [CloudinaryConfig] step 3.
  static const double _maxDimension = 1400;
  static const int _quality = 82;

  bool get isConfigured => CloudinaryConfig.isConfigured;

  /// Opens the gallery / file picker. Returns null if the user backed out.
  Future<XFile?> pickImage() => _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );

  Future<List<XFile>> pickImages() => _picker.pickMultiImage(
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );

  Future<String> uploadProductImage(XFile file) =>
      _upload(file, folder: '${CloudinaryConfig.folder}/products');

  Future<String> uploadSectionImage(XFile file) =>
      _upload(file, folder: '${CloudinaryConfig.folder}/sections');

  Future<String> _upload(XFile file, {required String folder}) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const StorageNotConfiguredException();
    }

    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadEndpoint)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: _safeName(file.name)),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw StorageUploadException(_describeError(response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map || body['secure_url'] is! String) {
      throw const StorageUploadException(
        'Cloudinary accepted the file but returned no URL.',
      );
    }
    return body['secure_url'] as String;
  }

  /// Detaching a photo from a product only drops the reference.
  ///
  /// Deleting the file itself needs a signed Cloudinary call, which needs an
  /// API secret, which cannot live in a browser app. So removed photos stay in
  /// the Cloudinary account as orphans. Orphans cost storage, and storage is
  /// the cheap half of the free plan's shared 25 credits — a few hundred
  /// abandoned photos is a fraction of one credit. Clear them out from the
  /// Cloudinary Media Library if it ever matters.
  ///
  /// Kept as a named method rather than deleting the call sites so the
  /// behaviour is explicit at the point of use instead of a silent omission.
  void forgetImage(String url) {
    // Intentionally nothing. See doc comment.
  }

  /// Pulls a readable message out of a Cloudinary error response.
  static String _describeError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      // Split in two rather than chaining `body['error']?['message']`: inside a
      // conditional expression the parser reads that `?` as another ternary.
      final error = body is Map ? body['error'] : null;
      final message = error is Map ? error['message'] : null;
      if (message is String && message.isNotEmpty) {
        // The two mistakes that are actually likely during setup, named.
        if (message.contains('preset not found')) {
          return 'Upload preset "${CloudinaryConfig.uploadPreset}" was not '
              'found. Check the name, and that it is set to Unsigned.';
        }
        if (message.contains('File size too large')) {
          return 'That photo is larger than the preset allows. Raise the max '
              'file size on the preset, or pick a smaller image.';
        }
        return message;
      }
    } on FormatException {
      // Fall through to the status code.
    }
    return 'Upload failed (HTTP ${response.statusCode}).';
  }

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.length <= 60 ? cleaned : cleaned.substring(cleaned.length - 60);
  }
}

/// Thrown when the Cloudinary account details have not been filled in.
class StorageNotConfiguredException implements Exception {
  const StorageNotConfiguredException();

  @override
  String toString() =>
      'Photo uploads are not set up yet. Add your Cloudinary cloud name and '
      'unsigned upload preset — see admin_app/lib/config/cloudinary_config.dart.';
}

class StorageUploadException implements Exception {
  const StorageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
