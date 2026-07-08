import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/attachment_modality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports image and pdf capabilities from models.dev', () {
    const modalities = ['text', 'image', 'pdf'];

    expect(
      supportsAttachmentModality(
        MessageAttachmentModality.image,
        modalities,
        mimeType: 'image/png',
      ),
      isTrue,
    );
    expect(
      supportsAttachmentModality(
        MessageAttachmentModality.file,
        modalities,
        mimeType: 'application/pdf',
      ),
      isTrue,
    );
    expect(supportsFileAttachments(modalities), isTrue);
    expect(
      filePickerAllowedExtensions(modalities),
      ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif'],
    );
  });

  test('does not treat pdf support as generic file support', () {
    const modalities = ['text', 'pdf'];

    expect(
      supportsAttachmentModality(
        MessageAttachmentModality.file,
        modalities,
        mimeType: 'text/csv',
      ),
      isFalse,
    );
  });

  test('allows any picker extension for generic file support', () {
    expect(filePickerAllowedExtensions(['text', 'file']), isNull);
    expect(
      filePickerAllowedExtensions(['text', 'document']),
      ['pdf', 'txt', 'md', 'csv', 'json'],
    );
  });

  test('allows enabled audio files in file picker', () {
    expect(supportsFileAttachments(['text', 'audio']), isTrue);
    expect(
      filePickerAllowedExtensions(['text', 'audio']),
      ['mp3', 'wav'],
    );
  });

  test('allows enabled image files in file picker', () {
    expect(supportsFileAttachments(['text', 'image']), isTrue);
    expect(
      filePickerAllowedExtensions(['text', 'image']),
      ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    );
  });

  test('allows enabled video files in file picker', () {
    expect(supportsFileAttachments(['text', 'video']), isTrue);
    expect(
      filePickerAllowedExtensions(['text', 'video']),
      ['mp4', 'mov', 'mkv', 'webm'],
    );
    expect(
      supportsAttachmentModality(
        MessageAttachmentModality.file,
        ['text', 'video'],
        mimeType: 'video/mp4',
      ),
      isTrue,
    );
  });

  test('combines picker extensions for specific file capabilities', () {
    expect(
      filePickerAllowedExtensions(['text', 'image', 'audio', 'video']),
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
