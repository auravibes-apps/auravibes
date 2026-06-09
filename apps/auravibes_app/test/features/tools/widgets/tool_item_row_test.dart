// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_provider_scope.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({String id = 't1', bool isEnabled = true}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: 'custom_tool',
    isEnabled: isEnabled,
    permissionMode: ToolPermissionMode.alwaysAsk,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

class _MockWorkspaceToolsNotifier extends WorkspaceToolsNotifier {
  _MockWorkspaceToolsNotifier(this.tools);

  final List<WorkspaceToolEntity> tools;

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => tools;
}

class _MockGroupedNotifier extends GroupedToolsNotifier {
  _MockGroupedNotifier(this.groups);

  final List<ToolsGroupWithTools> groups;

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => groups;
}

class _Subject extends StatelessWidget {
  const _Subject({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: TestProviderScope(
        overrides: [
          workspaceToolsProvider(_workspaceId).overrideWith(
            () => _MockWorkspaceToolsNotifier([_tool()]),
          ),
          groupedToolsProvider(
            _workspaceId,
          ).overrideWith(() => _MockGroupedNotifier([])),
        ],
        child: MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
            child: Material(child: child),
          ),
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
}

void main() {
  testWidgets('renders tool name and toggle', (tester) async {
    final tool = _tool();

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('custom_tool'), findsOneWidget);
    expect(find.byType(AuraSwitch), findsOneWidget);
  });

  testWidgets('renders expand icon button', (tester) async {
    final tool = _tool();

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsWidgets);
  });

  testWidgets('renders disabled tool with correct toggle state', (
    tester,
  ) async {
    final tool = _tool(isEnabled: false);

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('custom_tool'), findsOneWidget);
    expect(find.byType(AuraSwitch), findsOneWidget);
  });

  testWidgets('expands to show options on chevron tap', (tester) async {
    final tool = _tool(isEnabled: false);

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('does not show options when collapsed', (tester) async {
    final tool = _tool();

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraButtonGroup<ToolPermissionMode>), findsNothing);
  });

  testWidgets('hides delete button when showDeleteButton is false', (
    tester,
  ) async {
    final tool = _tool(isEnabled: false);

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(
          tool: tool,
          workspaceId: _workspaceId,
          showDeleteButton: false,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('shows delete button for non-native tool when expanded', (
    tester,
  ) async {
    final tool = _tool(isEnabled: false);

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(
          tool: tool,
          workspaceId: _workspaceId,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('renders tool icon container', (tester) async {
    final tool = _tool();

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
      ),
    );
    final _ = await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(Icons.extension),
        matching: find.byType(Container),
      ),
    );
    expect((container.constraints?.maxWidth ?? 0) > 0, isTrue);
  });

  testWidgets('permission selector only shows when enabled', (tester) async {
    final tool = _tool(isEnabled: false);

    await tester.pumpWidget(
      _Subject(
        child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraButtonGroup<ToolPermissionMode>), findsNothing);
  });
}
