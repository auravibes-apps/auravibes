import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/settings/usecases/workspace_agent_hook_settings_usecase.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late WorkspaceRepository workspaceRepository;
  late WorkspaceAgentHookSettingsRepository settingsRepository;

  setUp(() {
    database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    workspaceRepository = WorkspaceRepository(database);
    settingsRepository = WorkspaceAgentHookSettingsRepository(
      database.workspaceAgentHookSettingsDao,
    );
  });

  tearDown(() async => database.close());

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
        type: WorkspaceType.remote,
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
      const WorkspaceToCreate(name: 'Local', type: WorkspaceType.local),
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
      config: AgentLifecycleHookConfig(
        hooks: [
          const AgentLifecycleHookDefinition(
            event: AgentLifecycleHookEvent.beforeTool,
            command: './hooks/check-tool',
            args: ['--safe'],
          ),
        ],
        sourceFiles: const ['policy.json'],
      ),
      commandPaths: const {AgentLifecycleHookEvent.beforeTool: '/tmp/check'},
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
  }) async => const AgentLifecycleHookInvocationResult(
    outcome: AgentToolHookOutcome.unavailable,
  );
}
