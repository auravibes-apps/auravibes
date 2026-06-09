import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

class _MockConversationToolsNotifier extends ConversationToolsNotifier {
  @override
  Future<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  }) async => [];
}

class _MockGroupedConversationToolsNotifier
    extends GroupedConversationToolsNotifier {
  @override
  Future<List<ConversationToolsGroupWithTools>> build({
    required String workspaceId,
    String? conversationId,
  }) async => [];
}

void main() {
  test('constructor sets workspaceId and conversationId', () {
    const modal = ToolsManagementModal(
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
    );
    expect(modal.workspaceId, 'ws-1');
    expect(modal.conversationId, 'conv-1');
  });

  test('constructor allows null conversationId', () {
    const modal = ToolsManagementModal(workspaceId: 'ws-1');
    expect(modal.workspaceId, 'ws-1');
    expect(modal.conversationId, isNull);
  });

  test('constructor accepts different workspaceIds', () {
    const modal = ToolsManagementModal(workspaceId: 'other-ws');
    expect(modal.workspaceId, 'other-ws');
  });

  group('render', () {
    testWidgets('renders ToolsManagementModal', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const ToolsManagementModal(workspaceId: 'ws-1'),
            ),
            overrides: [
              conversationToolsProvider(
                workspaceId: 'ws-1',
              ).overrideWith(_MockConversationToolsNotifier.new),
              groupedConversationToolsProvider(
                workspaceId: 'ws-1',
              ).overrideWith(_MockGroupedConversationToolsNotifier.new),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(find.byType(ToolsManagementModal), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
