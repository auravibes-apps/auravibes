enum AttachmentModality { image, audio, file }

const _documentMimeTypes = {
  'application/json',
  'application/pdf',
  'text/csv',
  'text/markdown',
  'text/plain',
};

AttachmentModality attachmentModalityForMimeType(String mimeType) {
  final normalized = mimeType.toLowerCase();
  if (normalized.startsWith('image/')) return AttachmentModality.image;
  if (normalized.startsWith('audio/')) return AttachmentModality.audio;

  return AttachmentModality.file;
}

bool supportsAttachmentModality(
  AttachmentModality modality,
  Iterable<String> modelModalities, {
  String? mimeType,
}) {
  final supported = modelModalities.map((value) => value.toLowerCase()).toSet();
  final normalizedMimeType = mimeType?.toLowerCase();

  return switch (modality) {
    AttachmentModality.image => supported.contains('image'),
    AttachmentModality.audio => supported.contains('audio'),
    AttachmentModality.file =>
      supported.contains('file') ||
          _supportsSpecificFileType(supported, normalizedMimeType),
  };
}

bool supportsFileAttachments(Iterable<String> modelModalities) {
  final supported = modelModalities.map((value) => value.toLowerCase()).toSet();

  return const {'file', 'pdf', 'document', 'image', 'audio', 'video'}.any(
    supported.contains,
  );
}

bool _supportsSpecificFileType(Set<String> supported, String? mimeType) {
  if (mimeType == null) return false;
  if (mimeType == 'application/pdf') return supported.contains('pdf');
  if (mimeType.startsWith('video/')) return supported.contains('video');

  return supported.contains('document') &&
      _documentMimeTypes.contains(mimeType);
}
