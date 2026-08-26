import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/attachment_modality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports image and pdf capabilities from models.dev', () {
    const modalities = ['text', 'image', 'pdf'];

    expect(
      ChatAttachmentModality.supports(
        MessageAttachmentModality.image,
        modalities,
        mimeType: 'image/png',
      ),
      isTrue,
    );
    expect(
      ChatAttachmentModality.supports(
        MessageAttachmentModality.file,
        modalities,
        mimeType: 'application/pdf',
      ),
      isTrue,
    );
    expect(ChatAttachmentModality.supportsFiles(modalities), isTrue);
    expect(ChatAttachmentModality.pickerAllowedExtensions(modalities), [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    ]);
  });

  test('does not treat pdf support as generic file support', () {
    const modalities = ['text', 'pdf'];

    expect(
      ChatAttachmentModality.supports(
        MessageAttachmentModality.file,
        modalities,
        mimeType: 'text/csv',
      ),
      isFalse,
    );
  });

  test('allows any picker extension for generic file support', () {
    expect(
      ChatAttachmentModality.pickerAllowedExtensions(['text', 'file']),
      isNull,
    );
    expect(
      ChatAttachmentModality.pickerAllowedExtensions(['text', 'document']),
      ['pdf', 'txt', 'md', 'csv', 'json'],
    );
  });

  test('allows enabled audio files in file picker', () {
    expect(ChatAttachmentModality.supportsFiles(['text', 'audio']), isTrue);
    expect(ChatAttachmentModality.pickerAllowedExtensions(['text', 'audio']), [
      'mp3',
      'wav',
    ]);
  });

  test('allows enabled image files in file picker', () {
    expect(ChatAttachmentModality.supportsFiles(['text', 'image']), isTrue);
    expect(ChatAttachmentModality.pickerAllowedExtensions(['text', 'image']), [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    ]);
  });

  test('allows enabled video files in file picker', () {
    expect(ChatAttachmentModality.supportsFiles(['text', 'video']), isTrue);
    expect(ChatAttachmentModality.pickerAllowedExtensions(['text', 'video']), [
      'mp4',
      'mov',
      'mkv',
      'webm',
    ]);
    expect(
      ChatAttachmentModality.supports(MessageAttachmentModality.file, [
        'text',
        'video',
      ], mimeType: 'video/mp4'),
      isTrue,
    );
  });

  test('combines picker extensions for specific file capabilities', () {
    expect(
      ChatAttachmentModality.pickerAllowedExtensions([
        'text',
        'image',
        'audio',
        'video',
      ]),
      [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'mp3',
        'wav',
        'mp4',
        'mov',
        'mkv',
        'webm',
      ],
    );
  });
}
