import 'dart:async';

import 'package:auravibes_app/features/chats/providers/background_work_providers.dart';
import 'package:auravibes_app/features/chats/widgets/background_work_header_button.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  testWidgets(
    'captures the header and list after a refresh error',
    (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(480, 800);
      addTearDown(tester.view.resetPhysicalSize);

      final stream = StreamController<List<AgentBackgroundWork>>();
      final _ = await tester.runAsync(() async {
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('background_work_header_capture'),
            child: TestableApp(
              child: SizedBox.expand(
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
              ),
              overrides: [
                conversationBackgroundWorksProvider(
                  'conversation-1',
                ).overrideWith((ref) => stream.stream),
              ],
            ),
          ),
        );
      });
      await tester.pump();

      stream.add([
        _work('visible-work', .running, DateTime.utc(2026, 10, 11, 12)),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('background_work_header_button')),
      );
      await tester.pumpAndSettle();

      stream.addError(StateError('private fixture error'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey('background_work_header_capture')),
        matchesGoldenFile('goldens/background_work_header_refresh_error.png'),
      );
      await stream.close();
    },
    tags: ['golden'],
  );
}

AgentBackgroundWork _work(
  String id,
  AgentBackgroundWorkStatus status,
  DateTime createdAt,
) => .new(
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
  ),
);
