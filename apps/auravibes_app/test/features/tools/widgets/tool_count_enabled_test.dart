import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/tool_count_enabled_widget.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useFallbackTranslations: true,
        useOnlyLangCode: true,
        child: ProviderScope(
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
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useFallbackTranslations: true,
        useOnlyLangCode: true,
        child: Builder(
          builder: (context) {
            return ProviderScope(
              overrides: [
                workspaceToolsProvider(workspaceId).overrideWith(
                  () => _DataToolsNotifier(tools),
                ),
              ],
              child: MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Theme(
                  data: ThemeData(extensions: [AuraTheme.light]),
                  child: const Scaffold(
                    body: ToolCountEnabledWidget(workspaceId: workspaceId),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AuraSpinner), findsNothing);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('shows error widget on error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorWidget), findsOneWidget);
  });
}
