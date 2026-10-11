import 'package:auravibes_app/features/chats/providers/background_work_providers.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_header_button.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_list_view.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('header shows count, orders FIFO, and reopens the scoped list', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 11, 12);
    final older = _work('older', .completed, now);
    final newer = _work('newer', .running, now.add(const Duration(seconds: 1)));
    final watchedConversationIds = <String>[];
    final _ = await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            appBar: AppBar(
              actions: const [
                BackgroundWorkHeaderButton(
                  workspaceId: 'workspace-1',
                  conversationId: 'conversation-1',
                ),
              ],
            ),
          ),
          overrides: [
            conversationBackgroundWorksProvider('conversation-1')
                .overrideWith((ref) {
                  watchedConversationIds.add('conversation-1');

                  return Stream.value([newer, older]);
                }),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('background_work_header_button'));
    expect(header, findsOneWidget);
    expect(find.bySemanticsLabel('Background work, 1 active'), findsOneWidget);
    expect(watchedConversationIds, isNotEmpty);

    await tester.tap(header);
    final _ = await tester.pumpAndSettle();
    final olderTitle = find.byKey(
      const ValueKey('background_work_title_older'),
    );
    final newerTitle = find.byKey(
      const ValueKey('background_work_title_newer'),
    );
    expect(olderTitle, findsOneWidget);
    expect(newerTitle, findsOneWidget);
    expect(
      tester.getTopLeft(olderTitle).dy,
      lessThan(tester.getTopLeft(newerTitle).dy),
    );

    await tester.tap(find.byKey(const ValueKey('background_work_close')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(header);
    final _ = await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('background_work_title_older')),
      findsOneWidget,
    );
    expect(watchedConversationIds, isNotEmpty);
  });

  testWidgets(
    'stop request and terminal updates converge while retained results reopen',
    (tester) async {
      final now = DateTime.utc(2026, 10, 11, 12);
      var stopCalls = 0;
      final openedResults = <String>[];
      var works = [_work('work-1', .running, now)];

      Widget buildList() => TestableApp(
        child: SizedBox(
          width: 420,
          height: 480,
          child: BackgroundWorkListView(
            works: works,
            onStop: (work) {
              stopCalls++;

              return Future<void>.value();
            },
            onOpenResult: (work) {
              openedResults.add(work.identity.id);

              return Future<void>.value();
            },
            now: now.add(const Duration(seconds: 12)),
          ),
        ),
      );

      final _ = await tester.runAsync(() => tester.pumpWidget(buildList()));
      final _ = await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('background_work_stop_work-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('background_work_open_result_work-1')),
        findsNothing,
      );

      final _ = await tester.tap(
        find.byKey(const ValueKey('background_work_stop_work-1')),
      );
      final _ = await tester.pump();
      expect(stopCalls, 1);

      works = [_work('work-1', .stopRequested, now)];
      await tester.pumpWidget(buildList());
      final _ = await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('background_work_stop_work-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('background_work_status_work-1')),
        findsOneWidget,
      );

      works = [_work('work-1', .cancelled, now)];
      await tester.pumpWidget(buildList());
      final _ = await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('background_work_stop_work-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('background_work_open_result_work-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('background_work_preview_work-1')),
        findsNothing,
      );

      works = [_work('work-2', .completed, now, resultContent: 'saved result')];
      await tester.pumpWidget(buildList());
      final _ = await tester.pumpAndSettle();
      final openResult = find.byKey(
        const ValueKey('background_work_open_result_work-2'),
      );
      expect(openResult, findsOneWidget);
      final _ = await tester.tap(openResult);
      final _ = await tester.pump();
      final _ = await tester.tap(openResult);
      final _ = await tester.pump();
      expect(openedResults, ['work-2', 'work-2']);
    },
  );

  testWidgets('failed work keeps a bounded preview without a result action', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 11, 12);
    final preview = List.filled(260, String.fromCharCode(233)).join();
    final _ = await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: SizedBox(
            width: 420,
            height: 480,
            child: BackgroundWorkListView(
              works: [_work('failed-1', .failed, now, statusPreview: preview)],
              onStop: (_) => Future<void>.value(),
              onOpenResult: (_) => Future<void>.value(),
              now: now,
            ),
          ),
          startLocale: const Locale('es'),
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    final previewFinder = find.byKey(
      const ValueKey('background_work_preview_failed-1'),
    );
    expect(previewFinder, findsOneWidget);
    final renderedPreview = tester.widget<Text>(previewFinder).data;
    if (renderedPreview == null) fail('The preview text has no data.');
    expect(renderedPreview.characters.length, lessThanOrEqualTo(181));
    expect(
      find.byKey(const ValueKey('background_work_open_result_failed-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('background_work_stop_failed-1')),
      findsNothing,
    );
    expect(find.text('Fallida'), findsOneWidget);
  });
}

AgentBackgroundWork _work(
  String id,
  AgentBackgroundWorkStatus status,
  DateTime createdAt, {
  String? resultContent,
  String? statusPreview,
}) => .new(
  identity: .new(
    id: id,
    workspaceId: 'workspace-1',
    conversationId: 'conversation-1',
    toolCallId: 'tool-1',
    toolKind: 'Search',
    originatingMessageId: 'message-1',
  ),
  state: .new(
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
    statusPreview: statusPreview,
    resultContent: resultContent,
    resultByteLength: resultContent?.length ?? 0,
  ),
);
