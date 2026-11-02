import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/settings/widgets/workspace_agent_lifecycle_hooks_section.dart';
import 'package:auravibes_app/providers/agent_lifecycle_hook_runtime_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets(
    'review cancellation preserves no trust; trust requires separate opt-in',
    (tester) async {
      final fixture = await _HookSettingsFixture.create(tester);
      try {
      await fixture.pump(tester);
      expect(
        tester.widget<AuraSwitch>(find.byType(AuraSwitch)).onChanged,
        isNull,
      );
      await tester.tap(find.text('Review and trust'));
      final _ = await tester.pumpAndSettle();
      expect(find.byType(AuraConfirmDialog), findsOneWidget);
      for (final value in [
        '/tmp/hooks.json',
        '/tmp/check-hook',
        '/tmp/policy.json',
        fixture.runtime.digest,
        jsonEncode(['--literal', r'$(not-a-shell)']),
      ]) {
        expect(
          find.descendant(
            of: find.byType(AuraConfirmDialog),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is AuraSelectableText && widget.data.contains(value),
            ),
          ),
          findsOneWidget,
          reason: value,
        );
      }
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();
      expect((await fixture.read(tester)).isTrusted, isFalse);
      await tester.tap(find.text('Review and trust'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Trust configuration'));
      final _ = await tester.pumpAndSettle();
      final trusted = await fixture.read(tester);
      expect(trusted.isTrusted, isTrue);
      expect(trusted.enabled, isFalse);
      await tester.tap(find.byType(AuraSwitch));
      final _ = await tester.pumpAndSettle();
      expect((await fixture.read(tester)).enabled, isTrue);
      await tester.tap(find.text('Revoke trust'));
      final _ = await tester.pumpAndSettle();
      final revoked = await fixture.read(tester);
      expect(revoked.enabled, isFalse);
      expect(revoked.isTrusted, isFalse);
      expect(fixture.runtime.invokeCount, 0);
      } finally {
        await fixture.close(tester);
      }
    },
  );

  for (final platformUnavailable in [false, true]) {
    testWidgets('unsupported platform=$platformUnavailable shows recovery', (tester) async {
      final fixture = await _HookSettingsFixture.create(
        tester,
        remote: !platformUnavailable,
        trusted: true,
        enabled: true,
      );
      try {
      fixture.runtime.supported = !platformUnavailable;
      await fixture.pump(tester);
      expect(
        find.text(
          platformUnavailable
              ? 'Hooks are unavailable on this platform.'
              : 'Hooks are available only for local workspaces.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('To use hooks, open a local workspace in the desktop app.'),
        findsOneWidget,
      );
      expect(tester.widget<AuraButton>(_button('Choose configuration')).disabled, isTrue);
      expect(tester.widget<AuraButton>(_button('Review and trust')).disabled, isTrue);
      expect(tester.widget<AuraButton>(_button('Revoke trust')).disabled, isFalse);
      await tester.tap(find.byType(AuraSwitch));
      final _ = await tester.pumpAndSettle();
      expect((await fixture.read(tester)).enabled, isFalse);
      expect(
        tester.widget<AuraSwitch>(find.byType(AuraSwitch)).onChanged,
        isNull,
      );
      await tester.tap(find.text('Revoke trust'));
      final _ = await tester.pumpAndSettle();
      expect((await fixture.read(tester)).isTrusted, isFalse);
      expect(fixture.runtime.invokeCount, 0);
      } finally {
        await fixture.close(tester);
      }
    },);
  }

  testWidgets('changed sources block enable until reviewed and trusted again', (
    tester,
  ) async {
    final fixture = await _HookSettingsFixture.create(tester, trusted: true);
      try {
    fixture.runtime.digest = 'b' * 64;
    await fixture.pump(tester);
    expect(
      find.text(
        'Configuration or command source changed. '
        'Hooks are blocked until you trust it again.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<AuraSwitch>(find.byType(AuraSwitch)).onChanged,
      isNull,
    );
    await tester.tap(find.text('Review and trust'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Trust configuration'));
    final _ = await tester.pumpAndSettle();
    expect((await fixture.read(tester)).trustedDigest, fixture.runtime.digest);
    expect(
      tester.widget<AuraSwitch>(find.byType(AuraSwitch)).onChanged,
      isNotNull,
    );
    } finally {
        await fixture.close(tester);
      }
  });

  testWidgets('compact actions wrap and a long trust review scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = await _HookSettingsFixture.create(tester, trusted: true);
      try {
    fixture.runtime.commandPath = '/tmp/${'long-path-' * 50}policy.py';
    await fixture.pump(tester);
    await tester.ensureVisible(find.text('Review and trust'));
    await tester.tap(find.text('Review and trust'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    expect(find.text('Trust configuration'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final _ = await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    } finally {
        await fixture.close(tester);
      }
  });
}

Finder _button(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(AuraButton))
    .first;

class _HookSettingsFixture {
  new(this.database, this.workspace, this.settings, this.runtime);

  final AppDatabase database;
  final WorkspaceEntity workspace;
  final WorkspaceAgentHookSettingsRepository settings;
  final _ReviewRuntime runtime;

  static Future<_HookSettingsFixture> create(
    WidgetTester tester, {
    bool remote = false,
    bool trusted = false,
    bool enabled = false,
  }) async {
    final fixture = await tester.runAsync(() async {
      final database = AppDatabase(
        connection: DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      final workspace = await WorkspaceRepository(database).createWorkspace(
        .new(
          name: 'Research workspace',
          type: remote ? .remote : .local,
          url: remote ? 'https://example.invalid' : null,
        ),
      );
      final settings = WorkspaceAgentHookSettingsRepository(
        database.workspaceAgentHookSettingsDao,
      );
      final runtime = _ReviewRuntime();
      final _ = await settings.selectConfig(
        workspace.id,
        canonicalPath: '/tmp/hooks.json',
      );
      if (trusted) {
        final _ = await settings.trustConfig(
          workspace.id,
          canonicalPath: '/tmp/hooks.json',
          digest: runtime.digest,
        );
      }
      if (enabled) {
        final _ = await settings.setEnabled(workspace.id, enabled: true);
      }

      return _HookSettingsFixture(database, workspace, settings, runtime);
    });
    if (fixture == null) throw StateError('Fixture creation failed.');

    return fixture;
  }

  Future<WorkspaceAgentHookSettings> read(WidgetTester tester) async {
    final value = await tester.runAsync(() => settings.get(workspace.id));
    if (value == null) throw StateError('Settings read failed.');

    return value;
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(database.close);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      TestableApp(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: WorkspaceAgentLifecycleHooksSection(workspaceId: workspace.id),
          ),
        ),
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          agentLifecycleHookRuntimeProvider.overrideWithValue(runtime),
        ],
        workspaceId: workspace.id,
      ),
    );
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(AuraSwitch).evaluate().isNotEmpty &&
          find.byType(AuraSpinner).evaluate().isEmpty &&
          !tester.binding.hasScheduledFrame) {
        break;
      }
    }
    expect(find.byType(AuraSwitch), findsOneWidget);
    expect(find.byType(AuraSpinner), findsNothing);
  }
}

class _ReviewRuntime implements AgentLifecycleHookRuntime {
  bool supported = true;
  String digest = 'a' * 64;
  String commandPath = '/tmp/check-hook';
  int invokeCount = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async =>
      AgentLifecycleHookSourceSnapshot(
        canonicalPath: sourcePath,
        digest: digest,
        config: .new(
          hooks: [
            AgentLifecycleHookDefinition(
              event: .beforeTool,
              command: commandPath,
              args: const ['--literal', r'$(not-a-shell)'],
            ),
          ],
        ),
        commandPaths: {.beforeTool: commandPath},
        sourceFilePaths: const ['/tmp/policy.json'],
      );

  @override
  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
    Future<bool> Function()? isStillTrusted,
  }) async {
    invokeCount++;
    throw StateError('Settings review must not execute hooks.');
  }
}
