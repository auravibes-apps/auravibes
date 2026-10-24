/// Asset identities never become paths supplied by callers.
void validateAttachmentAssetKey(String value) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'assetId');
  }
}
