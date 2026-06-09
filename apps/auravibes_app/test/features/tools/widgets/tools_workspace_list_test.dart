// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/models/mcp_connection_view_status.dart';
import 'package:auravibes_app/features/tools/models/tools_group_with_tools.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tools_group_card.dart';
import 'package:auravibes_app/features/tools/widgets/tools_workspace_list_widget.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
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

ToolsGroupWithTools _defaultGroup(List<WorkspaceToolEntity> tools) {
  return ToolsGroupWithTools(
    group: null,
    tools: tools,
    defaultGroupType: DefaultToolGroupType.builtIn,
  );
}

class _LoadingNotifier extends GroupedToolsNotifier {
  final _completer = Completer<List<ToolsGroupWithTools>>();

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) =>
      _completer.future;
}

class _DataNotifier extends GroupedToolsNotifier {
  _DataNotifier(this.groups);

  final List<ToolsGroupWithTools> groups;

  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async => groups;
}

class _ErrorNotifier extends GroupedToolsNotifier {
  @override
  Future<List<ToolsGroupWithTools>> build(String workspaceId) async {
    throw Exception('test error');
  }
}

void main() {
  testWidgets('shows loading spinner while loading', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        child: TestProviderScope(
          overrides: [
            groupedToolsProvider(
              _workspaceId,
            ).overrideWith(_LoadingNotifier.new),
          ],
          child: MaterialApp(
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const Scaffold(
                body: ToolsWorkspaceListWidget(workspaceId: _workspaceId),
              ),
            ),
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
  });

  testWidgets('shows group cards when data loaded', (tester) async {
    final groups = [
      _defaultGroup([_tool(), _tool(id: 't2')]),
      _defaultGroup([_tool(id: 't3')]),
    ];

    await tester.pumpWidget(
      EasyLocalization(
        child: TestProviderScope(
          overrides: [
            groupedToolsProvider(
              _workspaceId,
            ).overrideWith(() => _DataNotifier(groups)),
          ],
          child: MaterialApp(
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const Scaffold(
                body: ToolsWorkspaceListWidget(workspaceId: _workspaceId),
              ),
            ),
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(ToolsGroupCard), findsNWidgets(2));
  });

  testWidgets('shows error widget on error', (tester) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          groupedToolsProvider(_workspaceId).overrideWith(_ErrorNotifier.new),
        ],
        child: MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
            child: const Scaffold(
              body: ToolsWorkspaceListWidget(workspaceId: _workspaceId),
            ),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });
}
