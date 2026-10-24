// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: Widget tests override scoped providers directly.

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_item_row.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_access_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'ws-1';

WorkspaceToolEntity _tool({String id = 't1', bool isEnabled = true}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: _workspaceId,
    toolId: 'custom_tool',
    isEnabled: isEnabled,
    permissionMode: .alwaysAsk,
    createdAt: .new(2026),
    updatedAt: .new(2026),
  );
}

class _MockWorkspaceToolsNotifier(final List<WorkspaceToolEntity> tools)
    extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => tools;
}

class _MockGroupedNotifier(final List<ToolsGroupWithTools> groups)
    extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => groups;
}

class const _Subject({
  required final Widget child,
  final bool isCloud = false,
  final bool isMember = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TestableApp(
      child: AuraThemeScope(
        theme: .light,
        child: Theme(
          data: .new(),
          child: Material(child: child),
        ),
      ),
      overrides: [
        workspaceAccessProvider(_workspaceId)
            .overrideWith((_) async => (role: isMember ? 'member' : 'owner')),
        workspaceToolsProvider(_workspaceId)
            .overrideWith(() => _MockWorkspaceToolsNotifier([_tool()])),
        groupedToolsProvider(_workspaceId)
            .overrideWith(() => _MockGroupedNotifier([])),
      ],
      workspaceSession: isCloud
          ? const WorkspaceSession(
              CloudWorkspaceRef(
                localWorkspaceId: _workspaceId,
                serverUrl: 'https://example.com',
                accountId: 'account',
                cloudWorkspaceId: 1,
              ),
            )
          : null,
    );
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpSubject(WidgetTester tester, Widget child) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(_Subject(child: child));
    });
    final _ = await tester.pumpAndSettle();
  }

  testWidgets('cloud Connector grants stay separate from command approval', (
    tester,
  ) async {
    final tool = _tool().copyWith(
      toolId: 'connector/brave/web_search',
      permissionMode: .alwaysAllow,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _Subject(
          child: ToolItemRow(tool: tool, workspaceId: _workspaceId),
          isCloud: true,
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(AuraIconButton).last);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Member tool access'), findsOneWidget);
    expect(find.text('Owners and admins only'), findsOneWidget);
    expect(find.byType(AuraButtonGroup<ToolPermissionMode>), findsNothing);
  });

  testWidgets('members cannot enable or edit workspace tools', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _Subject(
          child: ToolItemRow(tool: _tool(), workspaceId: _workspaceId),
          isMember: true,
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    expect(tester.widget<AuraSwitch>(find.byType(AuraSwitch)).disabled, true);
    await tester.tap(find.byType(AuraIconButton).last);
    final _ = await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byType(AuraButtonGroup<ToolPermissionMode>), findsNothing);
  });

  testWidgets('renders enabled tool row controls', (tester) async {
    final tool = _tool();

    await pumpSubject(
      tester,
      ToolItemRow(tool: tool, workspaceId: _workspaceId),
    );

    expect(find.text('custom_tool'), findsOneWidget);
    expect(find.byType(AuraSwitch), findsOneWidget);
    expect(find.byType(AuraIconButton), findsWidgets);
    expect(find.byType(AuraButtonGroup<ToolPermissionMode>), findsNothing);
    final container = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(Icons.extension),
        matching: find.byType(Container),
      ),
    );
    expect((container.constraints?.maxWidth ?? 0) > 0, isTrue);
  });

  testWidgets('disabled tool expands without permission selector', (
    tester,
  ) async {
    final tool = _tool(isEnabled: false);

    await pumpSubject(
      tester,
      ToolItemRow(tool: tool, workspaceId: _workspaceId),
    );

    expect(find.text('custom_tool'), findsOneWidget);
    expect(find.byType(AuraSwitch), findsOneWidget);
    expect(find.byType(AuraButtonGroup<ToolPermissionMode>), findsNothing);
    await tester.tap(find.byType(AuraIconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byType(AuraButtonGroup<ToolPermissionMode>), findsNothing);
  });

  testWidgets('hides delete button when showDeleteButton is false', (
    tester,
  ) async {
    await pumpSubject(
      tester,
      ToolItemRow(
        tool: _tool(isEnabled: false),
        workspaceId: _workspaceId,
        showDeleteButton: false,
      ),
    );

    await tester.tap(find.byType(AuraIconButton).last);
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });
}
