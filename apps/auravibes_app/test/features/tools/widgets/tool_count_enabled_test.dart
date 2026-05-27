// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_count_enabled_widget.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_provider_scope.dart';

WorkspaceToolEntity _tool({
  String id = 'tool-1',
  String toolId = 'calculator',
  bool isEnabled = true,
}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: 'ws1',
    toolId: toolId,
    isEnabled: isEnabled,
    permissionMode: ToolPermissionMode.alwaysAsk,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

class _LoadingToolsNotifier extends WorkspaceToolsNotifier {
  final _completer = Completer<List<WorkspaceToolEntity>>();

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) =>
      _completer.future;
}

class _DataToolsNotifier extends WorkspaceToolsNotifier {
  _DataToolsNotifier(this.tools);

  final List<WorkspaceToolEntity> tools;

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => tools;
}

class _ErrorToolsNotifier extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async {
    throw Exception('fail');
  }
}

void main() {
  const workspaceId = 'ws1';

  testWidgets('shows loading spinner while loading', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        child: TestProviderScope(
          overrides: [
            workspaceToolsProvider(
              workspaceId,
            ).overrideWith(_LoadingToolsNotifier.new),
          ],
          child: MaterialApp(
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const Scaffold(
                body: ToolCountEnabledWidget(workspaceId: workspaceId),
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

  testWidgets('shows count of available tools when data loaded', (
    tester,
  ) async {
    final tools = [
      _tool(id: 't1'),
      _tool(id: 't2'),
      _tool(id: 't3', isEnabled: false),
    ];

    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) {
            return TestProviderScope(
              overrides: [
                workspaceToolsProvider(workspaceId).overrideWith(
                  () => _DataToolsNotifier(tools),
                ),
              ],
              child: MaterialApp(
                home: Theme(
                  data: ThemeData(extensions: [AuraTheme.light]),
                  child: const Scaffold(
                    body: ToolCountEnabledWidget(workspaceId: workspaceId),
                  ),
                ),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            );
          },
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
    await tester.pump();

    expect(find.byType(AuraSpinner), findsNothing);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('shows error widget on error', (tester) async {
    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          workspaceToolsProvider(workspaceId).overrideWith(
            _ErrorToolsNotifier.new,
          ),
        ],
        child: MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
            child: const Scaffold(
              body: ToolCountEnabledWidget(workspaceId: workspaceId),
            ),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });
}
