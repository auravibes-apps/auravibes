import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ux_validation_fixture.dart';

void main() {
  tearDownAll(UxValidationFixture.closeDatabase);
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final scenario in [
    (size: const Size(400, 800), scale: 1.0),
    (size: const Size(400, 800), scale: 2.0),
    (size: const Size(400, 450), scale: 2.0),
    (size: const Size(1200, 800), scale: 2.0),
  ]) {
    testWidgets('approval actions at $scenario', (tester) async {
      final fixture = await UxValidationFixture.create();
      addTearDown(() => fixture.close(tester));
      const pending = [
        PendingToolCall(
          toolCall: .new(
            id: 'isolated-write',
            name: agent.executeConnectorToolName,
            argumentsRaw:
                '{"toolId":"connector/duckduckgo/search",'
                '"args":{"query":"isolated approval preview"}}',
          ),
          messageId: 'isolated-message',
        ),
      ];
      final _ = await fixture.pump(
        tester,
        ConversationRoute(
          workspaceId: fixture.workspaceId,
          chatId: fixture.chatId,
        ).location,
        size: scenario.size,
        scale: scenario.scale,
        overrides: [
          pendingToolCallsProvider(
            fixture.workspaceId,
            fixture.chatId,
          ).overrideWith((ref) => Future.value(pending)),
        ],
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('tool_approval_allow_once')),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('tool_approval_allow_once')).hitTestable(),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('tool_approval_skip')),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('tool_approval_skip')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
