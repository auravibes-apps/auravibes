import 'package:auravibes_app/features/chats/providers/background_work_continuation_provider.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_continuation_status.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_detach_controls.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows and opens a result waiting for its follow-up turn', (
    tester,
  ) async {
    const key = (workspaceId: 'workspace-1', conversationId: 'conversation-1');
    const result = '{"answer":"ready"}';
    final work = BackgroundWorkView(
      id: 'work-1',
      workspaceId: 1,
      conversationId: key.conversationId,
      toolCallId: 'tool-call-1',
      toolKind: 'skillTemplate',
      status: 'completed',
      statusPreview: backgroundWorkQueuedForContinuation,
      resultContent: result,
      resultByteLength: result.length,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );

    await pumpLocalized(
      tester,
      ProviderScope(
        overrides: [
          backgroundWorkContinuationsProvider(key)
              .overrideWith((ref) async => [work]),
        ],
        child: _LocalizedApp(
          child: Scaffold(
            body: BackgroundWorkContinuationStatus(
              workspaceId: key.workspaceId,
              conversationId: key.conversationId,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    final settledDuration = await tester.pumpAndSettle();

    expect(
      find.text(result),
      findsOneWidget,
      reason: 'The result dialog did not settle after $settledDuration.',
    );
  });

  testWidgets('keeps results visible while continuation runs or fails', (
    tester,
  ) async {
    const key = (workspaceId: 'workspace-1', conversationId: 'conversation-1');
    final now = DateTime.utc(2026);
    BackgroundWorkView work(String id, String preview) {
      final content = 'Saved result for $id.';

      return BackgroundWorkView(
        id: id,
        workspaceId: 1,
        conversationId: key.conversationId,
        toolCallId: id,
        toolKind: 'skillTemplate',
        status: 'completed',
        statusPreview: preview,
        resultContent: content,
        resultByteLength: content.length,
        createdAt: now,
        updatedAt: now,
      );
    }

    final works = [
      work('work-in-progress', backgroundWorkContinuationInProgress),
      work('work-failed', backgroundWorkContinuationFailed),
    ];

    await pumpLocalized(
      tester,
      ProviderScope(
        overrides: [
          backgroundWorkContinuationsProvider(key)
              .overrideWith((ref) async => works),
        ],
        child: _LocalizedApp(
          child: Scaffold(
            body: BackgroundWorkContinuationStatus(
              workspaceId: key.workspaceId,
              conversationId: key.conversationId,
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'The follow-up turn is running. The result is still available.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'The follow-up turn could not finish. The result is still available.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TextButton), findsNWidgets(2));
  });

  testWidgets('offers an action to detach an eligible running call', (
    tester,
  ) async {
    const key = (workspaceId: 'workspace-1', conversationId: 'conversation-1');
    final now = DateTime.utc(2026);
    final call = ConversationToolCallView(
      id: 'tool-call-1',
      turnId: 'turn-1',
      messageId: 'message-1',
      name: 'research_search',
      argumentsJson: '{}',
      argumentsDigest: 'digest',
      userFacingDescription: 'Search the latest research.',
      backgroundEligible: true,
      status: 'running',
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );
    final work = BackgroundWorkView(
      id: 'work-1',
      workspaceId: 1,
      conversationId: key.conversationId,
      originatingMessageId: 'message-1',
      toolCallId: call.id,
      toolKind: 'skillTemplate',
      status: 'running',
      resultByteLength: 0,
      createdAt: now,
      updatedAt: now,
    );
    String? detachedToolCallId;
    String? detachRequestId;

    await pumpLocalized(
      tester,
      ProviderScope(
        overrides: [
          backgroundDetachableToolCallsProvider(key)
              .overrideWith((ref) => [call]),
          backgroundWorkDetachCommandProvider(key).overrideWith(
            (ref) => ({required requestId, required toolCallId}) async {
              detachRequestId = requestId;
              detachedToolCallId = toolCallId;

              return work;
            },
          ),
        ],
        child: _LocalizedApp(
          child: AuraThemeScope(
            theme: .light,
            child: AuraSnackBarHost(
              child: Scaffold(
                body: BackgroundWorkDetachControls(
                  workspaceId: key.workspaceId,
                  conversationId: key.conversationId,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Search the latest research.'), findsOneWidget);
    await tester.tap(find.text('Continue in background'));
    final settledDuration = await tester.pumpAndSettle();

    expect(detachedToolCallId, call.id);
    expect(detachRequestId, isNotEmpty);
    expect(
      find.text('The task is continuing in the background.'),
      findsOneWidget,
      reason: 'The detach confirmation did not settle after $settledDuration.',
    );
  });
}

Future<void> pumpLocalized(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
  });
  final settledDuration = await tester.pumpAndSettle();
  expect(
    tester.binding.hasScheduledFrame,
    isFalse,
    reason: 'The localized widget did not settle after $settledDuration.',
  );
}

class const _LocalizedApp({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EasyLocalization(
    child: Builder(
      builder: (context) => MaterialApp(
        home: child,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}
