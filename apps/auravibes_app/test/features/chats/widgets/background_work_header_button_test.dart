import 'dart:async';

import 'package:auravibes_app/features/chats/providers/background_work_providers.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_header_button.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_list_view.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('active elapsed time refreshes and terminal duration freezes', (
    tester,
  ) async {
    final createdAt = DateTime.utc(2026, 10, 11, 12);
    var clockNow = createdAt.add(const Duration(seconds: 5));
    var works = [_work('elapsed-work', .running, createdAt)];

    Widget buildList() => TestableApp(
      child: SizedBox(
        width: 420,
        height: 480,
        child: BackgroundWorkListView(
          works: works,
          onStop: (_) => Future<void>.value(),
          onOpenResult: (_) => Future<void>.value(),
          clock: () => clockNow,
        ),
      ),
    );

    final _ = await tester.runAsync(() => tester.pumpWidget(buildList()));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Elapsed: 5s'), findsOneWidget);

    clockNow = createdAt.add(const Duration(seconds: 9));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Elapsed: 9s'), findsOneWidget);

    works = [
      _work(
        'elapsed-work',
        .completed,
        createdAt,
        updatedAt: createdAt.add(const Duration(seconds: 12)),
        resultContent: 'ready',
      ),
    ];
    await tester.pumpWidget(buildList());
    final _ = await tester.pumpAndSettle();
    expect(find.text('Elapsed: 12s'), findsOneWidget);

    clockNow = createdAt.add(const Duration(seconds: 80));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Elapsed: 12s'), findsOneWidget);
  });

  testWidgets('header shows count, orders FIFO, and reopens the scoped list', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 11, 12);
    final older = _work('work-1', .completed, now);
    final sameTime = _work('work-2', .completed, now);
    final newer = _work(
      'work-3',
      .running,
      now.add(const Duration(seconds: 1)),
    );
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

                  return Stream.value([newer, sameTime, older]);
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
      const ValueKey('background_work_title_work-1'),
    );
    final sameTimeTitle = find.byKey(
      const ValueKey('background_work_title_work-2'),
    );
    final newerTitle = find.byKey(
      const ValueKey('background_work_title_work-3'),
    );
    expect(olderTitle, findsOneWidget);
    expect(sameTimeTitle, findsOneWidget);
    expect(newerTitle, findsOneWidget);
    expect(
      tester.getTopLeft(olderTitle).dy,
      lessThan(tester.getTopLeft(sameTimeTitle).dy),
    );
    expect(
      tester.getTopLeft(sameTimeTitle).dy,
      lessThan(tester.getTopLeft(newerTitle).dy),
    );

    await tester.tap(find.byKey(const ValueKey('background_work_close')));
    final _ = await tester.pumpAndSettle();
    await tester.tap(header);
    final _ = await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('background_work_title_work-1')),
      findsOneWidget,
    );
    expect(watchedConversationIds, isNotEmpty);
  });

  testWidgets('header distinguishes loading, empty, and stale failure states', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    final now = DateTime.utc(2026, 10, 11, 12);
    final stream = StreamController<List<AgentBackgroundWork>>();
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
                .overrideWith((ref) => stream.stream),
          ],
        ),
      );
    });
    final header = find.byKey(const ValueKey('background_work_header_button'));
    await _pumpUntilFound(
      tester,
      find.bySemanticsLabel('Checking background work.'),
    );
    expect(
      tester.getSemantics(header).getSemanticsData().label,
      'Checking background work.',
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    stream.add(const []);
    final _ = await tester.pumpAndSettle();
    expect(
      tester.getSemantics(header).getSemanticsData().label,
      'Background work, 0 active',
    );
    expect(find.byIcon(Icons.error_outline), findsNothing);

    stream.add([_work('work-1', .running, now)]);
    final _ = await tester.pumpAndSettle();
    expect(
      tester.getSemantics(header).getSemanticsData().label,
      'Background work, 1 active',
    );

    stream.addError(StateError('private failure detail'));
    final _ = await tester.pumpAndSettle();
    final errorSemantics = tester.getSemantics(header).getSemanticsData();
    expect(
      errorSemantics.label,
      'Background work could not refresh. Last known count: 1 active. '
      'Open the list to retry.',
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('private failure detail'), findsNothing);
    final closeResult = await stream.close();
    expect(closeResult, isNull);
    expect(stream.isClosed, isTrue);
  });

  testWidgets('local background work load offers explicit retry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    final now = DateTime.utc(2026, 10, 11, 12);
    final work = _work('work-1', .completed, now);
    final failedLoad = StreamController<List<AgentBackgroundWork>>();
    var attempts = 0;
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
                  attempts++;
                  if (attempts == 1) {
                    return failedLoad.stream;
                  }

                  return Stream.value([work]);
                }),
          ],
        ),
      );
    });
    final header = find.byKey(const ValueKey('background_work_header_button'));
    await _pumpUntilFound(
      tester,
      find.bySemanticsLabel('Checking background work.'),
    );
    await tester.tap(header);
    await tester.pump();
    failedLoad
      ..addError(StateError('temporary failure'))
      ..close();
    final _ = await tester.pumpAndSettle();
    expect(
      tester.getSemantics(header).getSemanticsData().label,
      'Background work could not load. Open the list to retry.',
    );
    expect(find.text('Could not load background work.'), findsOneWidget);
    final retry = find.byKey(const ValueKey('background_work_retry'));
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    final _ = await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('background_work_title_work-1')),
      findsOneWidget,
    );
    expect(attempts, 2);
  });

  testWidgets('cloud background work load can be retried without dispatching', (
    tester,
  ) async {
    const workspace = CloudWorkspaceRef(
      localWorkspaceId: 'workspace-1',
      serverUrl: 'https://example.com',
      accountId: 'account-1',
      cloudWorkspaceId: 1,
    );
    const request = (
      workspaceId: 'workspace-1',
      conversationId: 'conversation-1',
    );
    final work = _work('cloud-work-1', .completed, .utc(2026, 10, 11, 12));
    var attempts = 0;
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
            cloudConversationBackgroundWorksProvider.overrideWith((
              ref,
              arg,
            ) async {
              attempts++;
              if (attempts == 1) throw StateError('temporary cloud failure');

              expect(arg, request);

              return [work];
            }),
          ],
          workspaceSession: const .new(workspace),
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('background_work_header_button'));
    expect(
      tester.getSemantics(header).getSemanticsData().label,
      'Background work could not load. Open the list to retry.',
    );
    await tester.tap(header);
    final _ = await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('background_work_retry')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('background_work_retry')));
    final _ = await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('background_work_title_cloud-work-1')),
      findsOneWidget,
    );
    expect(attempts, 2);
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

  testWidgets('opens a linked child conversation from background work', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 10, 11, 12);
    final openedChildIds = <String>[];
    final _ = await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: SizedBox(
            width: 420,
            height: 480,
            child: BackgroundWorkListView(
              works: [
                _work(
                  'work-child',
                  .running,
                  now,
                  childConversationId: 'child-conversation-1',
                ),
              ],
              onStop: (_) => Future<void>.value(),
              onOpenResult: (_) => Future<void>.value(),
              onOpenChild: (work) {
                final childConversationId = work.identity.childConversationId;
                if (childConversationId != null) {
                  openedChildIds.add(childConversationId);
                }

                return Future<void>.value();
              },
              now: now,
            ),
          ),
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('background_work_open_child_work-child')),
    );
    final _ = await tester.pump();

    expect(openedChildIds, ['child-conversation-1']);
  });

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

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(finder, findsOneWidget);
}

AgentBackgroundWork _work(
  String id,
  AgentBackgroundWorkStatus status,
  DateTime createdAt, {
  DateTime? updatedAt,
  String? resultContent,
  String? statusPreview,
  String? childConversationId,
}) => .new(
  identity: .new(
    id: id,
    workspaceId: 'workspace-1',
    conversationId: 'conversation-1',
    toolCallId: 'tool-1',
    toolKind: 'Search',
    originatingMessageId: 'message-1',
    childConversationId: childConversationId,
  ),
  state: .new(
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
    statusPreview: statusPreview,
    resultContent: resultContent,
    resultByteLength: resultContent?.length ?? 0,
  ),
);
