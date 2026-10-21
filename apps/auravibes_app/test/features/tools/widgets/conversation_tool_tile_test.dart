import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tool_tile.dart';
import 'package:auravibes_app/features/tools/widgets/tool_permission_selector.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({String id = 't1'}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: 'custom_tool',
    isEnabled: true,
    permissionMode: .alwaysAsk,
    createdAt: .new(2026),
    updatedAt: .new(2026),
  );
}

class _MockConversationToolsNotifier(final List<ConversationToolState> states)
    extends ConversationToolsNotifier {
  @override
  Future<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  }) async => states;
}

class const _Subject({
  required final ConversationToolState toolState,
  final String? conversationId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TestableApp(
      child: AuraThemeScope(
        theme: .light,
        child: Theme(
          data: .new(),
          child: Material(
            child: SingleChildScrollView(
              child: ConversationToolTile(
                toolState: toolState,
                workspaceId: _workspaceId,
                conversationId: conversationId,
              ),
            ),
          ),
        ),
      ),
      overrides: [
        conversationToolsProvider(
          workspaceId: _workspaceId,
          conversationId: conversationId,
        ).overrideWith(() => _MockConversationToolsNotifier([toolState])),
      ],
    );
  }
}

Future<void> _pumpSubject(
  WidgetTester tester, {
  required ConversationToolState toolState,
  String? conversationId,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      _Subject(toolState: toolState, conversationId: conversationId),
    );
  });
  final _ = await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders a workspace-disabled tool without permissions', (
    tester,
  ) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: .alwaysAsk,
      isWorkspaceEnabled: false,
    );

    await _pumpSubject(tester, toolState: toolState);

    expect(find.byType(ToolPermissionSelector), findsNothing);
    expect(find.byType(AuraCard), findsOneWidget);
    expect(find.text('custom_tool'), findsOneWidget);
    expect(find.byIcon(Icons.block), findsOneWidget);
    final auraCard = tester.widget<AuraCard>(find.byType(AuraCard));
    expect(auraCard.onTap, isNull);
    expect(find.text('Disabled in workspace'), findsOneWidget);
  });

  testWidgets('hides permission selector for a disabled tool', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: false,
      permissionMode: .alwaysAsk,
      isWorkspaceEnabled: true,
    );

    await _pumpSubject(tester, toolState: toolState);

    expect(find.byType(ToolPermissionSelector), findsNothing);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  testWidgets('renders tool description for workspace-enabled tool', (
    tester,
  ) async {
    final tool = _tool();
    final toolState = ConversationToolState(
      tool: .new(
        id: tool.id,
        workspaceId: tool.workspaceId,
        toolId: tool.toolId,
        isEnabled: false,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: tool.createdAt,
        updatedAt: tool.updatedAt,
        description: 'A test tool description',
      ),
      isEnabled: false,
      permissionMode: .alwaysAsk,
      isWorkspaceEnabled: true,
    );

    await _pumpSubject(tester, toolState: toolState);

    expect(find.text('A test tool description'), findsOneWidget);
  });

  testWidgets('renders enabled workspace tool permissions', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: .alwaysAsk,
      isWorkspaceEnabled: true,
    );

    FlutterError.onError = (_) {
      final _ = Object();
    };
    await _pumpSubject(tester, toolState: toolState);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(ToolPermissionSelector), findsOneWidget);
    final auraCard = tester.widget<AuraCard>(find.byType(AuraCard));
    expect(auraCard.onTap, isNotNull);
    FlutterError.onError = null;
  });

  testWidgets('renders with conversationId', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: false,
      permissionMode: .alwaysAsk,
      isWorkspaceEnabled: true,
    );

    await _pumpSubject(tester, toolState: toolState, conversationId: 'conv-1');

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('ToolPermissionSelector has correct value', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: .alwaysAllow,
      isWorkspaceEnabled: true,
    );

    FlutterError.onError = (_) {
      final _ = Object();
    };
    await _pumpSubject(tester, toolState: toolState);

    expect(find.byType(ToolPermissionSelector), findsOneWidget);
    final selector = tester.widget<ToolPermissionSelector>(
      find.byType(ToolPermissionSelector),
    );
    expect(selector.value, ToolPermissionMode.alwaysAllow);
    FlutterError.onError = null;
  });
}
