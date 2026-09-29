import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/compaction_checkpoint_history_provider.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

MessageEntity _makeMessage({
  required String content,
  required MessageMetadataEntity metadata,
  String id = 'msg-1',
  DateTime? createdAt,
}) {
  return MessageEntity(
    id: id,
    conversationId: 'conv-1',
    content: content,
    messageType: .system,
    isUser: false,
    status: .sent,
    createdAt: createdAt ?? .new(2026),
    updatedAt: .new(2026),
    metadata: metadata,
  );
}

MessageEntity _makeCountMessage() => _makeMessage(
  content: 'Compaction summary content',
  metadata: .new(
    metadataVersion: 2,
    isCompactionSummary: true,
    compactedMessageIds: List<String>.generate(1234, (index) => 'msg-$index'),
  ),
);

class const _Subject({
  required final MessageEntity message,
  final Locale locale = const Locale('en'),
  final CompactionCheckpointHistory? checkpointHistory,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = checkpointHistory;

    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: ProviderScope(
              overrides: [
                if (history != null)
                  compactionCheckpointHistoryProvider((
                    workspaceId: 'ws-1',
                    conversationId: 'conv-1',
                  )).overrideWith((ref) async => history),
              ],
              child: AuraThemeScope(
                theme: .light,
                child: Theme(
                  data: .new(),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: CompactedMessageDetails(
                        message: message,
                        workspaceId: 'ws-1',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            locale: context.locale,
            localizationsDelegates: [
              ...context.localizationDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: context.supportedLocales,
          );
        },
      ),
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: locale,
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }
}

Future<void> _pumpAndInit(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
  });
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders compaction details with content, range, and count', (
    tester,
  ) async {
    const metadata = MessageMetadataEntity(
      metadataVersion: 2,
      isCompactionSummary: true,
      compactionKind: .auto,
      compactedFromMessageId: 'from-1',
      compactedThroughMessageId: 'to-1',
      compactedMessageIds: ['msg-a', 'msg-b'],
    );
    final message = _makeMessage(
      content: 'Compaction summary content',
      metadata: metadata,
    );

    await _pumpAndInit(tester, _Subject(message: message));

    expect(find.text('Compaction summary content'), findsOneWidget);
    expect(find.text('from-1 -> to-1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('formats message count in English', (tester) async {
    await _pumpAndInit(tester, _Subject(message: _makeCountMessage()));
    expect(find.text('1,234'), findsOneWidget);
  });

  testWidgets('formats message count in Spanish', (tester) async {
    await _pumpAndInit(
      tester,
      _Subject(message: _makeCountMessage(), locale: const Locale('es')),
    );
    expect(find.text('1.234'), findsOneWidget);
  });

  testWidgets('formats checkpoint relative time using the active locale', (
    tester,
  ) async {
    final createdAt = DateTime.now().subtract(const Duration(days: 1234));
    final message = _makeMessage(
      content: 'Compaction summary content',
      metadata: const MessageMetadataEntity(),
    );
    final checkpoint = _makeMessage(
      content: 'Checkpoint summary',
      metadata: const MessageMetadataEntity(),
      id: 'summary-1',
      createdAt: createdAt,
    );

    await _pumpAndInit(
      tester,
      _Subject(
        message: message,
        locale: const Locale('es'),
        checkpointHistory: (
          activeCheckpointId: 'summary-1',
          summaries: [checkpoint],
        ),
      ),
    );
    await tester.tap(find.text('Historial de puntos de control'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('hace 1.234d'), findsOneWidget);
  });
}
