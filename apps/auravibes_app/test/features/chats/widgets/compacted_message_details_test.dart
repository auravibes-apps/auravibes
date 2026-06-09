// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
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
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    metadata: metadata,
  );
}

class _Subject extends StatelessWidget {
  const _Subject({required this.message});

  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: CompactedMessageDetails(message: message),
                ),
              ),
            ),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }
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

    await tester.pumpWidget(_Subject(message: message));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Compaction summary content'), findsOneWidget);
    expect(find.text('from-1 -> to-1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
