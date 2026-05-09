import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MessageEntity _makeMessage({
  required String content,
  required MessageMetadataEntity metadata,
  String id = 'msg-1',
}) {
  return MessageEntity(
    id: id,
    conversationId: 'conv-1',
    content: content,
    messageType: MessageType.system,
    isUser: false,
    status: MessageStatus.sent,
    metadata: metadata,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

Widget buildSubject(MessageEntity message) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useFallbackTranslations: true,
    useOnlyLangCode: true,
    child: Builder(
      builder: (context) {
        return MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
            child: Scaffold(
              body: SingleChildScrollView(
                child: CompactedMessageDetails(message: message),
              ),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('renders compaction details with content, range, and count', (
    tester,
  ) async {
    const metadata = MessageMetadataEntity(
      metadataVersion: 2,
      isCompactionSummary: true,
      compactionKind: CompactionKind.auto,
      compactedFromMessageId: 'from-1',
      compactedThroughMessageId: 'to-1',
      compactedMessageIds: ['msg-a', 'msg-b'],
    );
    final message = _makeMessage(
      content: 'Compaction summary content',
      metadata: metadata,
    );

    await tester.pumpWidget(buildSubject(message));
    await tester.pumpAndSettle();

    expect(find.text('Compaction summary content'), findsOneWidget);
    expect(find.text('from-1 → to-1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
