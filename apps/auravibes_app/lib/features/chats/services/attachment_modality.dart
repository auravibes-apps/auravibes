import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as engine;

const int maxChatAttachmentBytes = 25 * 1024 * 1024;
const int maxChatPromptAttachmentBytes = 25 * 1024 * 1024;

const _documentExtensions = ['pdf', 'txt', 'md', 'csv', 'json'];

MessageAttachmentModality attachmentModalityForMimeType(String mimeType) {
  return MessageAttachmentModality.values.byName(
    engine.attachmentModalityForMimeType(mimeType).name,
  );
}

bool supportsAttachmentModality(
  MessageAttachmentModality modality,
  List<String> modalities, {
  String? mimeType,
}) {
  return engine.supportsAttachmentModality(
    engine.AttachmentModality.values.byName(modality.name),
    modalities,
    mimeType: mimeType,
  );
}

bool supportsFileAttachments(List<String> modalities) {
  return engine.supportsFileAttachments(modalities);
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
