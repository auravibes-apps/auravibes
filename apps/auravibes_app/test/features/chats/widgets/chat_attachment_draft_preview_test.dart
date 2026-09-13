import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_draft_preview.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const attachment = MessageAttachmentToCreate(
    localPath: '/tmp/report.pdf',
    fileName: 'report.pdf',
    displayName: 'Report',
    mimeType: 'application/pdf',
    modality: .file,
    sizeBytes: 2048,
  );

  Widget buildSubject({
    required MessageAttachmentToCreate attachment,
    required ValueChanged<MessageAttachmentToCreate> onRemove,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Material(
        child: ChatAttachmentDraftPreview(
          attachment: attachment,
          onRemove: onRemove,
          enabled: enabled,
        ),
      ),
      theme: .new(extensions: [AuraTheme.light]),
    );
  }

  testWidgets('renders filename, MIME type, and size', (tester) async {
    await tester.pumpWidget(
      buildSubject(attachment: attachment, onRemove: _ignoreAttachment),
    );

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('application/pdf - 2.0 KB'), findsOneWidget);
  });

  testWidgets('renders an image thumbnail when the platform supports files', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        attachment: attachment.copyWith(
          fileName: 'photo.png',
          mimeType: 'image/png',
          modality: .image,
        ),
        onRemove: _ignoreAttachment,
      ),
    );

    expect(find.byType(Image), kIsWeb ? findsNothing : findsOneWidget);
  });

  testWidgets('provides a fallback when an image cannot load', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        attachment: attachment.copyWith(
          fileName: 'missing.png',
          mimeType: 'image/png',
          modality: .image,
        ),
        onRemove: _ignoreAttachment,
      ),
    );

    final errorBuilder = tester.widget<Image>(find.byType(Image)).errorBuilder;
    expect(errorBuilder, isNotNull);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => errorBuilder!(
            context,
            StateError('Image decode failed'),
            StackTrace.empty,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('forwards the remove action', (tester) async {
    MessageAttachmentToCreate? removed;
    await tester.pumpWidget(
      buildSubject(
        attachment: attachment,
        onRemove: (value) => removed = value,
      ),
    );

    final onDeleted = tester
        .widget<InputChip>(find.byType(InputChip))
        .onDeleted;
    expect(onDeleted, isNotNull);
    onDeleted?.call();

    expect(removed, same(attachment));
  });

  testWidgets('disables the remove action when requested', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        attachment: attachment,
        onRemove: _ignoreAttachment,
        enabled: false,
      ),
    );

    expect(tester.widget<InputChip>(find.byType(InputChip)).onDeleted, isNull);
  });
}

void _ignoreAttachment(MessageAttachmentToCreate _) {
  final _ = Object();
}
