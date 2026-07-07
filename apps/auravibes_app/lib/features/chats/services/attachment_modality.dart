import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

const int maxChatAttachmentBytes = 25 * 1024 * 1024;
const int maxChatPromptAttachmentBytes = 25 * 1024 * 1024;

const _documentExtensions = ['pdf', 'txt', 'md', 'csv', 'json'];

const _documentMimeTypes = {
  'application/json',
  'application/pdf',
  'text/csv',
  'text/markdown',
  'text/plain',
};

MessageAttachmentModality attachmentModalityForMimeType(String mimeType) {
  if (mimeType.startsWith('image/')) return MessageAttachmentModality.image;
  if (mimeType.startsWith('audio/')) return MessageAttachmentModality.audio;

  return MessageAttachmentModality.file;
}

bool supportsAttachmentModality(
  MessageAttachmentModality modality,
  List<String> modalities, {
  String? mimeType,
}) {
  final supported = modalities.map((value) => value.toLowerCase()).toSet();

  return switch (modality) {
    MessageAttachmentModality.image => supported.contains('image'),
    MessageAttachmentModality.audio => supported.contains('audio'),
    MessageAttachmentModality.file =>
      supported.contains('file') ||
          _supportsSpecificFileType(supported, mimeType),
  };
}

bool supportsFileAttachments(List<String> modalities) {
  final supported = modalities.map((value) => value.toLowerCase()).toSet();

  return supported.contains('file') ||
      supported.contains('pdf') ||
      supported.contains('document') ||
      supported.contains('image') ||
      supported.contains('audio') ||
      supported.contains('video');
}

List<String>? filePickerAllowedExtensions(List<String> modalities) {
  final supported = modalities.map((value) => value.toLowerCase()).toSet();
  if (supported.contains('file')) {
    return null;
  }

  final extensions = <String>{};
  if (supported.contains('document')) {
    extensions.addAll(_documentExtensions);
  }
  if (supported.contains('pdf')) {
    extensions.addAll(const ['pdf']);
  }
  if (supported.contains('image')) {
    extensions.addAll(const ['jpg', 'jpeg', 'png', 'webp', 'gif']);
  }
  if (supported.contains('audio')) {
    extensions.addAll(const ['mp3', 'wav']);
  }
  if (supported.contains('video')) {
    extensions.addAll(const ['mp4', 'mov', 'mkv', 'webm']);
  }

  if (extensions.isNotEmpty) return extensions.toList(growable: false);

  return const [];
}

bool _supportsSpecificFileType(Set<String> supported, String? mimeType) {
  if (mimeType == null) return false;
  if (mimeType == 'application/pdf') return supported.contains('pdf');
  if (mimeType.startsWith('video/')) {
    return supported.contains('video');
  }

  return supported.contains('document') &&
      _documentMimeTypes.contains(mimeType);
}
