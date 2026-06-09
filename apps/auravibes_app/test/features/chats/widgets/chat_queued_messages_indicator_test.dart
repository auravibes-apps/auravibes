// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: prefer-moving-to-variable
// Required: Tests repeat finders and fixture lookups for clarity.
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/widgets/chat_queued_messages_indicator.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _EasyLocalizationTestWrapper extends StatelessWidget {
  const _EasyLocalizationTestWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: child,
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
  Widget buildSubject({
    required List<ConversationQueuedDraft> queuedDrafts,
  }) {
    return _EasyLocalizationTestWrapper(
      child: ProviderScope(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conv-1'),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: Theme(
                data: ThemeData(extensions: [AuraTheme.light]),
                child: Material(
                  child: ChatQueuedMessagesIndicator(
                    queuedDrafts: queuedDrafts,
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
    );
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders nothing when queuedDrafts is empty', (tester) async {
    await pumpAndInit(tester, buildSubject(queuedDrafts: const []));

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(AuraBadge), findsNothing);
  });

  testWidgets('renders queued draft content', (tester) async {
    final drafts = [
      const ConversationQueuedDraft(id: 'q-1', content: 'Hello'),
      const ConversationQueuedDraft(id: 'q-2', content: 'World'),
    ];

    await pumpAndInit(tester, buildSubject(queuedDrafts: drafts));

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
  });

  testWidgets('renders count badge with draft count', (tester) async {
    final drafts = [
      const ConversationQueuedDraft(id: 'q-1', content: 'Hello'),
      const ConversationQueuedDraft(id: 'q-2', content: 'World'),
    ];

    await pumpAndInit(tester, buildSubject(queuedDrafts: drafts));

    expect(find.byType(AuraBadge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('renders close icon buttons for each draft', (tester) async {
    final drafts = [
      const ConversationQueuedDraft(id: 'q-1', content: 'Hello'),
      const ConversationQueuedDraft(id: 'q-2', content: 'World'),
    ];

    await pumpAndInit(tester, buildSubject(queuedDrafts: drafts));

    expect(find.byIcon(Icons.close), findsNWidgets(2));
  });
}
