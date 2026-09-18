import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/conversation_tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_conversation_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tool_tile.dart';
import 'package:auravibes_app/features/tools/widgets/conversation_tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_management_modal.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({
  String id = 't1',
  String toolId = 'custom_tool',
  String? description,
  bool isEnabled = true,
}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: toolId,
    isEnabled: isEnabled,
    permissionMode: .alwaysAsk,
    createdAt: .new(2026),
    updatedAt: .new(2026),
    description: description,
  );
}

ConversationToolState _toolState({
  String id = 't1',
  String toolId = 'custom_tool',
  String? description,
  bool isEnabled = true,
}) {
  final tool = _tool(
    id: id,
    toolId: toolId,
    description: description,
    isEnabled: isEnabled,
  );

  return ConversationToolState(
    tool: tool,
    isEnabled: isEnabled,
    permissionMode: .alwaysAsk,
    isWorkspaceEnabled: true,
  );
}

ConversationToolsGroupWithTools _defaultGroup(
  List<ConversationToolState> tools,
) => ConversationToolsGroupWithTools(
  group: null,
  tools: tools,
  defaultGroupType: .builtIn,
);

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

class _DataGroupedConversationToolsNotifier(
  final List<ConversationToolsGroupWithTools> groups,
) extends GroupedConversationToolsNotifier {
  @override
  Future<List<ConversationToolsGroupWithTools>> build({
    required String workspaceId,
    String? conversationId,
  }) async => groups;
}

Future<void> _pumpModal(
  WidgetTester tester,
  List<ConversationToolsGroupWithTools> groups,
) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: Theme(
          data: .new(extensions: [AuraTheme.light]),
          child: const ToolsManagementModal(workspaceId: _workspaceId),
        ),
        overrides: [
          conversationToolsProvider(workspaceId: _workspaceId)
              .overrideWith(_MockConversationToolsNotifier.new),
          groupedConversationToolsProvider(
            workspaceId: _workspaceId,
          ).overrideWith(() => _DataGroupedConversationToolsNotifier(groups)),
          workspaceSessionForRouteProvider(_workspaceId).overrideWithValue(
            const AsyncData(
              WorkspaceSession(
                LocalWorkspaceRef(localWorkspaceId: _workspaceId),
              ),
            ),
          ),
        ],
        workspaceId: _workspaceId,
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
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
              data: .new(extensions: [AuraTheme.light]),
              child: const ToolsManagementModal(workspaceId: 'ws-1'),
            ),
            overrides: [
              conversationToolsProvider(workspaceId: 'ws-1')
                  .overrideWith(_MockConversationToolsNotifier.new),
              groupedConversationToolsProvider(workspaceId: 'ws-1')
                  .overrideWith(_MockGroupedConversationToolsNotifier.new),
              workspaceSessionForRouteProvider('ws-1').overrideWithValue(
                const AsyncData(
                  WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'ws-1')),
                ),
              ),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(find.byType(ToolsManagementModal), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('filters conversation tools by name or description', (
      tester,
    ) async {
      await _pumpModal(tester, [
        _defaultGroup([
          _toolState(toolId: 'search_files', description: 'Reads local files'),
          _toolState(id: 't2', toolId: 'calendar', description: 'Plans events'),
        ]),
      ]);

      expect(find.byType(AuraInput), findsOneWidget);
      await tester.enterText(find.byType(AuraInput), 'local files');
      await tester.pump();
      final _ = await tester.tap(find.byType(IconButton).last);
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ConversationToolTile), findsOneWidget);
      expect(find.text('calendar'), findsNothing);
    });

    testWidgets('search preserves conversation tool enablement', (
      tester,
    ) async {
      await _pumpModal(tester, [
        _defaultGroup([
          _toolState(id: 'enabled', toolId: 'alpha'),
          _toolState(id: 'disabled', toolId: 'beta', isEnabled: false),
        ]),
      ]);

      await tester.enterText(find.byType(AuraInput), 'built-in');
      await tester.pump();
      final _ = await tester.tap(find.byType(IconButton).last);
      final _ = await tester.pumpAndSettle();

      final tiles = tester
          .widgetList<ConversationToolTile>(find.byType(ConversationToolTile))
          .toList();
      expect(tiles, hasLength(2));
      expect(tiles.map((tile) => tile.toolState.isEnabled), [true, false]);
    });

    testWidgets('shows no-results state when no conversation tool matches', (
      tester,
    ) async {
      await _pumpModal(tester, [
        _defaultGroup([_toolState()]),
      ]);

      await tester.enterText(find.byType(AuraInput), 'not-found');
      await tester.pump();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.byType(ConversationToolTile), findsNothing);
    });

    testWidgets('expands and collapses all conversation tool groups', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpModal(tester, [
        _defaultGroup([_toolState(id: 'first', toolId: 'first_tool')]),
        ConversationToolsGroupWithTools(
          group: .new(
            id: 'group-2',
            workspaceId: _workspaceId,
            name: 'Second Group',
            isEnabled: true,
            permissions: .ask,
            createdAt: .new(2026),
            updatedAt: .new(2026),
          ),
          tools: [_toolState(id: 'second', toolId: 'second_tool')],
        ),
      ]);

      expect(find.byType(ConversationToolTile), findsNothing);

      final _ = await tester.tap(
        find.byKey(const ValueKey('tools_expand_all_groups')),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('first_tool'), findsOneWidget);

      final _ = await tester.drag(
        find.byType(ListView),
        const Offset(0, -1000),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('second_tool'), findsOneWidget);

      final _ = await tester.tap(
        find.byKey(const ValueKey('tools_collapse_all_groups')),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.byType(ConversationToolTile), findsNothing);
    });

    testWidgets('individual group toggle works after bulk expansion', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpModal(tester, [
        _defaultGroup([_toolState(id: 'first')]),
        ConversationToolsGroupWithTools(
          group: .new(
            id: 'group-2',
            workspaceId: _workspaceId,
            name: 'Second Group',
            isEnabled: true,
            permissions: .ask,
            createdAt: .new(2026),
            updatedAt: .new(2026),
          ),
          tools: [_toolState(id: 'second')],
        ),
      ]);

      final _ = await tester.tap(
        find.byKey(const ValueKey('tools_expand_all_groups')),
      );
      final _ = await tester.pumpAndSettle();

      final firstGroup = find.byType(ConversationToolsGroupCard).first;
      final _ = await tester.tap(
        find.descendant(of: firstGroup, matching: find.byType(IconButton)),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ConversationToolTile), findsOneWidget);
    });
  });
}
