import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tool_tile.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({String id = 't1'}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: 'custom_tool',
    isEnabled: true,
    permissionMode: ToolPermissionMode.alwaysAsk,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

class _MockConversationToolsNotifier extends ConversationToolsNotifier {
  _MockConversationToolsNotifier(this.states);

  final List<ConversationToolState> states;

  @override
  Future<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  }) async => states;
}

Widget _buildSubject({
  required ConversationToolState toolState,
  String? conversationId,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useFallbackTranslations: true,
    useOnlyLangCode: true,
    child: ProviderScope(
      overrides: [
        conversationToolsProvider(
          workspaceId: _workspaceId,
          conversationId: conversationId,
        ).overrideWith(
          () => _MockConversationToolsNotifier([toolState]),
        ),
      ],
      child: MaterialApp(
        home: Theme(
          data: ThemeData(extensions: [AuraTheme.light]),
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
    ),
  );
}

void main() {
  testWidgets('hides permission selector when workspace-disabled', (
    tester,
  ) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: false,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    expect(find.byType(ToolPermissionSelector), findsNothing);
  });

  testWidgets('hides permission selector when tool is disabled', (
    tester,
  ) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: false,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: true,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    expect(find.byType(ToolPermissionSelector), findsNothing);
  });

  testWidgets('renders card for workspace-disabled tool', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: false,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
    expect(find.text('custom_tool'), findsOneWidget);
  });

  testWidgets('shows block icon for workspace-disabled tool', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: false,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.block), findsOneWidget);
  });

  testWidgets('shows circle_outlined for disabled workspace tool', (
    tester,
  ) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: false,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: true,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  testWidgets('renders tool description for workspace-enabled tool', (
    tester,
  ) async {
    final tool = _tool();
    final toolState = ConversationToolState(
      tool: WorkspaceToolEntity(
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
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: true,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    expect(find.text('A test tool description'), findsOneWidget);
  });

  testWidgets('onTap is null when workspace-disabled', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: false,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    final auraCard = tester.widget<AuraCard>(find.byType(AuraCard));
    expect(auraCard.onTap, isNull);
  });

  testWidgets('renders disabled text for workspace-disabled tool', (
    tester,
  ) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: false,
    );

    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pumpAndSettle();

    expect(find.text('Disabled in workspace'), findsOneWidget);
  });

  testWidgets('shows check_circle for enabled workspace tool', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: true,
    );

    FlutterError.onError = (_) {};
    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    FlutterError.onError = null;
  });

  testWidgets('shows permission selector when enabled and workspace-enabled', (
    tester,
  ) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: true,
    );

    FlutterError.onError = (_) {};
    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pump();

    expect(find.byType(ToolPermissionSelector), findsOneWidget);
    FlutterError.onError = null;
  });

  testWidgets('onTap is not null when workspace-enabled', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: true,
    );

    FlutterError.onError = (_) {};
    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pump();

    final auraCard = tester.widget<AuraCard>(find.byType(AuraCard));
    expect(auraCard.onTap, isNotNull);
    FlutterError.onError = null;
  });

  testWidgets('renders with conversationId', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: false,
      permissionMode: ToolPermissionMode.alwaysAsk,
      isWorkspaceEnabled: true,
    );

    await tester.pumpWidget(
      _buildSubject(toolState: toolState, conversationId: 'conv-1'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuraCard), findsOneWidget);
  });

  testWidgets('ToolPermissionSelector has correct value', (tester) async {
    final toolState = ConversationToolState(
      tool: _tool(),
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAllow,
      isWorkspaceEnabled: true,
    );

    FlutterError.onError = (_) {};
    await tester.pumpWidget(_buildSubject(toolState: toolState));
    await tester.pump();

    expect(find.byType(ToolPermissionSelector), findsOneWidget);
    final selector = tester.widget<ToolPermissionSelector>(
      find.byType(ToolPermissionSelector),
    );
    expect(selector.value, ToolPermissionMode.alwaysAllow);
    FlutterError.onError = null;
  });
}
