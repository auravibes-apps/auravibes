const maxObjectSizeBytes = 25 * 1024 * 1024;

void validateObjectInput({
  required String requestId,
  required String purpose,
  required String displayName,
  required String mimeType,
  required int sizeBytes,
  required String checksumSha256,
}) {
  if (requestId.trim().isEmpty ||
      purpose.trim().isEmpty ||
      displayName.trim().isEmpty ||
      sizeBytes <= 0 ||
      !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(checksumSha256)) {
    throw ArgumentError('Invalid object upload request.');
  }
  if (sizeBytes > maxObjectSizeBytes) {
    throw RangeError('Object exceeds size limit.');
  }
  if (!mimeType.startsWith('image/') &&
      !mimeType.startsWith('audio/') &&
      !mimeType.startsWith('video/') &&
      mimeType != 'application/pdf' &&
      mimeType != 'text/plain' &&
      mimeType != 'application/json') {
    throw UnsupportedError('Unsupported media type.');
  }
  if (mimeType == 'image/svg+xml' || mimeType == 'text/html') {
    throw UnsupportedError('Active content is not uploadable.');
  }
}

String safeContentDisposition(String displayName) {
  final safe = displayName.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
  return 'attachment; filename="${safe.isEmpty ? 'download' : safe}"';
}
