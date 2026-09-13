import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as engine;

abstract final class ChatAttachmentModality {
  static const int maxChatAttachmentBytes = 25 * 1024 * 1024;
  static const int maxChatPromptAttachmentBytes = maxChatAttachmentBytes;
  static const _documentExtensions = ['pdf', 'txt', 'md', 'csv', 'json'];
  static const _extensionsByModality = <String, List<String>>{
    'document': _documentExtensions,
    'pdf': ['pdf'],
    'image': ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    'audio': ['mp3', 'wav'],
    'video': ['mp4', 'mov', 'mkv', 'webm'],
  };

  static MessageAttachmentModality forMimeType(String mimeType) {
    return MessageAttachmentModality.values.byName(
      engine.attachmentModalityForMimeType(mimeType).name,
    );
  }

  static bool supports(
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

  static bool supportsFiles(List<String> modalities) {
    return engine.supportsFileAttachments(modalities);
  }

  static List<String>? pickerAllowedExtensions(List<String> modalities) {
    final supported = modalities.map((value) => value.toLowerCase()).toSet();
    if (supported.contains('file')) return null;

    final extensions = <String>{
      for (final entry in _extensionsByModality.entries)
        if (supported.contains(entry.key)) ...entry.value,
    };

    if (extensions.isNotEmpty) return extensions.toList(growable: false);

    return const [];
  }
}

final class const ChatAttachmentTooLargeException() implements Exception {
  String get localizationKey =>
      LocaleKeys.chats_screens_chat_conversation_attachment_too_large;

  @override
  String toString() => localizationKey;
}
