import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/settings/usecases/workspace_agent_hook_settings_usecase.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../data/database/drift/database_test_utils.dart';

void main() {
  test('typed settings failure diagnostics contain only the localization key', () {
    const error = WorkspaceAgentHookSettingsException('agent_lifecycle_hooks.trust_required');
    expect(error.toString(), error.localizationKey);
  });
  final database = AppDatabase(connection: NativeDatabase.memory());
  final workspaceRepository = WorkspaceRepository(database);
  final settingsRepository = WorkspaceAgentHookSettingsRepository(
    database.workspaceAgentHookSettingsDao,
  );
  setUp(() => clearAppDatabase(database));
  tearDownAll(database.close);

  test('trust is separate from opt-in and revocation clears both', () async {
    final workspace = await _createLocalWorkspace(workspaceRepository);
    final usecase = _usecase(
      settingsRepository,
      workspaceRepository,
      _FakeHookRuntime(),
    );
    await usecase.selectConfig(workspace.id, '/tmp/hooks.json');
    final review = await usecase.reviewConfig(workspace.id, '/tmp/hooks.json');
    await usecase.trustReviewedConfig(workspace.id, review);
    final trusted = await settingsRepository.get(workspace.id);
    expect(trusted.isTrusted, isTrue);
    expect(trusted.enabled, isFalse);
    await usecase.setEnabled(workspace.id, enabled: true);
    expect((await settingsRepository.get(workspace.id)).enabled, isTrue);
    await usecase.revokeTrust(workspace.id);
    final revoked = await settingsRepository.get(workspace.id);
    expect(revoked.enabled, isFalse);
    expect(revoked.isTrusted, isFalse);
    expect(revoked.trustedDigest, isNull);
    expect(revoked.trustedSourcePath, isNull);
  });

  test(
    'selecting another configuration clears prior trust and enablement',
    () async {
      final workspace = await _createLocalWorkspace(workspaceRepository);
      final usecase = _usecase(
        settingsRepository,
        workspaceRepository,
        _FakeHookRuntime(),
      );
      await usecase.selectConfig(workspace.id, '/tmp/hooks.json');
      await usecase.trustReviewedConfig(
        workspace.id,
        await usecase.reviewConfig(workspace.id, '/tmp/hooks.json'),
      );
      await usecase.setEnabled(workspace.id, enabled: true);
      await usecase.selectConfig(workspace.id, '/tmp/replacement.json');
      final replacement = await settingsRepository.get(workspace.id);
      expect(replacement.enabled, isFalse);
      expect(replacement.isTrusted, isFalse);
      expect(replacement.configPath, '/tmp/replacement.json');
      expect(replacement.trustedDigest, isNull);
    },
  );

  test('selecting a config stores it disabled and untrusted', () async {
    final workspace = await _createLocalWorkspace(workspaceRepository);
    final runtime = _FakeHookRuntime();
    final usecase = _usecase(settingsRepository, workspaceRepository, runtime);

    await usecase.selectConfig(workspace.id, '/tmp/hooks.json');

    final settings = await settingsRepository.get(workspace.id);
    expect(settings.enabled, isFalse);
    expect(settings.configPath, '/tmp/hooks.json');
    expect(settings.isTrusted, isFalse);
  });

  test('review exposes canonical executable and source paths', () async {
    final workspace = await _createLocalWorkspace(workspaceRepository);
    final runtime = _FakeHookRuntime();
    final usecase = _usecase(settingsRepository, workspaceRepository, runtime);
    await usecase.selectConfig(workspace.id, '/tmp/hooks.json');

    final review = await usecase.reviewConfig(workspace.id, '/tmp/hooks.json');

    expect(review.commands.single.canonicalCommandPath, '/tmp/check');
    expect(review.commands.single.arguments, ['--safe']);
    expect(review.sourceFiles, ['/tmp/policy.json']);
    expect(review.digest, 'trusted');
  });

  test(
    'trust fails if the source changes after the user reviewed it',
    () async {
      final workspace = await _createLocalWorkspace(workspaceRepository);
      final runtime = _FakeHookRuntime();
      final usecase = _usecase(
        settingsRepository,
        workspaceRepository,
        runtime,
      );
      await usecase.selectConfig(workspace.id, '/tmp/hooks.json');
      final review = await usecase.reviewConfig(
        workspace.id,
        '/tmp/hooks.json',
      );
      runtime.digest = 'changed';

      await expectLater(
        usecase.trustReviewedConfig(workspace.id, review),
        throwsA(isA<WorkspaceAgentHookSettingsException>()),
      );
      expect((await settingsRepository.get(workspace.id)).isTrusted, isFalse);
    },
  );

  test(
    'enabling hooks verifies the trusted source fingerprint again',
    () async {
      final workspace = await _createLocalWorkspace(workspaceRepository);
      final runtime = _FakeHookRuntime();
      final usecase = _usecase(
        settingsRepository,
        workspaceRepository,
        runtime,
      );
      await usecase.selectConfig(workspace.id, '/tmp/hooks.json');
      final review = await usecase.reviewConfig(
        workspace.id,
        '/tmp/hooks.json',
      );
      await usecase.trustReviewedConfig(workspace.id, review);
      await usecase.setEnabled(workspace.id, enabled: true);
      expect((await settingsRepository.get(workspace.id)).enabled, isTrue);

      runtime.digest = 'changed';
      await expectLater(
        usecase.setEnabled(workspace.id, enabled: true),
        throwsA(isA<WorkspaceAgentHookSettingsException>()),
      );
    },
  );

  test('remote workspaces cannot select a configuration', () async {
    final workspace = await workspaceRepository.createWorkspace(
      const WorkspaceToCreate(
        name: 'Remote',
        type: .remote,
        url: 'https://example.invalid',
      ),
    );
    final runtime = _FakeHookRuntime();
    final usecase = _usecase(settingsRepository, workspaceRepository, runtime);

    await expectLater(
      usecase.selectConfig(workspace.id, '/tmp/hooks.json'),
      throwsA(isA<WorkspaceAgentHookSettingsException>()),
    );
    expect(runtime.inspectCount, 0);
  });

  test('unsupported platforms cannot select or enable hooks', () async {
    final workspace = await _createLocalWorkspace(workspaceRepository);
    final runtime = _FakeHookRuntime()..supported = false;
    final usecase = _usecase(settingsRepository, workspaceRepository, runtime);

    await expectLater(
      usecase.selectConfig(workspace.id, '/tmp/hooks.json'),
      throwsA(isA<WorkspaceAgentHookSettingsException>()),
    );
    await expectLater(
      usecase.setEnabled(workspace.id, enabled: true),
      throwsA(isA<WorkspaceAgentHookSettingsException>()),
    );
    expect(runtime.inspectCount, 0);
  });
}

Future<WorkspaceEntity> _createLocalWorkspace(WorkspaceRepository repository) =>
    repository.createWorkspace(
      const WorkspaceToCreate(name: 'Local', type: .local),
    );

WorkspaceAgentHookSettingsUsecase _usecase(
  WorkspaceAgentHookSettingsRepository settingsRepository,
  WorkspaceRepository workspaceRepository,
  AgentLifecycleHookRuntime runtime,
) => WorkspaceAgentHookSettingsUsecase(
  settingsRepository: settingsRepository,
  workspaceRepository: workspaceRepository,
  runtime: runtime,
);

class _FakeHookRuntime implements AgentLifecycleHookRuntime {
  String digest = 'trusted';
  int inspectCount = 0;
  bool supported = true;

  @override
  bool get isSupported => supported;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    inspectCount++;

    return AgentLifecycleHookSourceSnapshot(
      canonicalPath: sourcePath,
      digest: digest,
      config: const AgentLifecycleHookConfig(
        hooks: [
          AgentLifecycleHookDefinition(
            event: .beforeTool,
            command: './hooks/check-tool',
            args: ['--safe'],
          ),
        ],
        sourceFiles: ['policy.json'],
      ),
      commandPaths: {
        for (final event in [AgentLifecycleHookEvent.beforeTool])
          event: '/tmp/check',
      },
      sourceFilePaths: const ['/tmp/policy.json'],
    );
  }

  @override
  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
    required Future<bool> Function() isStillTrusted,
  }) async => const AgentLifecycleHookInvocationResult(outcome: .unavailable);
}
