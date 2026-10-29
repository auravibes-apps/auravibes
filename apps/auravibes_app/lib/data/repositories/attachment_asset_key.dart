/// Asset identities never become paths supplied by callers.
abstract final class AttachmentAssetKey {
  static final _key = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static void validate(String value) {
    if (!_key.hasMatch(value)) throw ArgumentError.value(value, 'assetId');
  }
}
