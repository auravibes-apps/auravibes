import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_configuration_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final state = _RepositoryFixture();

  setUp(() async {
    state.database = .new(connection: NativeDatabase.memory());
    state.repository = .new(state.database);
    final _ = await state.database
        .into(state.database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('workspace'),
            name: 'Local',
            type: .local,
          ),
        );
    final _ = await state.database
        .into(state.database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('other'),
            name: 'Other',
            type: .local,
          ),
        );
    final _ = await state.database
        .into(state.database.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: const Value('chat'),
            workspaceId: 'workspace',
            title: 'Work',
          ),
        );
    final _ = await state.database
        .into(state.database.messages)
        .insert(
          MessagesCompanion.insert(
            id: const Value('turn'),
            conversationId: 'chat',
            content: 'Edit',
            messageType: .text,
            isUser: true,
            status: .sent,
          ),
        );
  });
  tearDown(() => state.database.close());

  Future<ScopedVerificationReservation> reserve(
    String toolCallId, {
    int revision = 1,
    int maxRepairAttempts = 1,
    String workspaceId = 'workspace',
    String turnId = 'turn',
  }) => state.repository.reserve(
    (
      workspaceId: workspaceId,
      turnId: turnId,
      toolCallId: toolCallId,
      configRevision: revision,
      maxRepairAttempts: maxRepairAttempts,
    ),
  );

  test(
    'absent and malformed settings are disabled within their workspace',
    () async {
      expect(
        (await state.repository.getSettings('workspace')).enabled,
        isFalse,
      );
      await state.repository.saveSettings('workspace', _settings());
      expect((await state.repository.getSettings('workspace')).enabled, isTrue);
      expect(
        (await state.repository.watchSettings('other').first).enabled,
        isFalse,
      );
      await state.database.customStatement(
        'UPDATE workspace_verification_settings SET settings_json = ? '
        'WHERE workspace_id = ?',
        ['malformed', 'workspace'],
      );
      expect(
        (await state.repository.getSettings('workspace')).enabled,
        isFalse,
      );
      expect((await reserve('edit')).shouldRun, isFalse);
    },
  );

  test(
    'explicit save increments revision and rejects a stale writer',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      expect((await state.repository.getSettings('workspace')).revision, 1);
      await expectLater(
        state.repository.saveSettings('workspace', _settings()),
        throwsA(isA<WorkspaceTableException>()),
      );
      await state.repository.saveSettings(
        'workspace',
        _settings(enabled: false, revision: 1),
      );
      expect((await reserve('edit', revision: 2)).result?.reason, 'disabled');
    },
  );

  test('cloud workspaces cannot save authority or reserve commands', () async {
    final _ =
        await (state.database.update(
          state.database.workspaces,
        )..where((row) => row.id.equals('workspace'))).write(
          const WorkspacesCompanion(
            type: .new(.remote),
            url: .new('https://cloud.example'),
          ),
        );
    await expectLater(
      state.repository.saveSettings('workspace', _settings()),
      throwsA(isA<WorkspaceTableException>()),
    );
    expect((await reserve('edit')).result?.reason, 'unsupported_workspace');
  });

  test(
    'wrong workspace and non-user turn cannot obtain a reservation',
    () async {
      await state.repository.saveSettings('other', _settings());
      expect(
        (await reserve('edit', workspaceId: 'other')).result?.reason,
        'invalid_turn',
      );
      await state.repository.saveSettings('workspace', _settings());
      final _ =
          await (state.database.update(state.database.messages)
                ..where((row) => row.id.equals('turn')))
              .write(const MessagesCompanion(isUser: .new(false)));
      expect((await reserve('edit')).result?.reason, 'invalid_turn');
    },
  );

  test(
    'duplicate concurrent reservation creates only one remote operation',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final reservations = await Future.wait([
        reserve('edit'),
        reserve('edit'),
      ]);
      expect(
        reservations.where((reservation) => reservation.shouldRun),
        hasLength(1),
      );
      expect(
        reservations
            .where((reservation) => !reservation.shouldRun)
            .single
            .result
            ?.reason,
        'verification_in_progress',
      );
      expect(
        await state.database
            .select(state.database.workspaceVerificationRuns)
            .get(),
        hasLength(1),
      );
    },
  );

  test('healthy edits do not consume repair budget', () async {
    await state.repository.saveSettings('workspace', _settings());
    for (final id in ['edit-1', 'edit-2', 'edit-3']) {
      final reservation = await reserve(id);
      expect(reservation.shouldRun, isTrue);
      final saved = await state.repository.complete(
        _operationId(reservation),
        _result(.pass),
      );
      expect(saved.outcome, ScopedVerificationOutcome.pass);
      expect(saved.repairAttemptsRemaining, 1);
    }
  });

  test(
    'failed checks arm one repair across tool IDs and configuration revisions',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final first = await reserve('first');
      final failed = await state.repository.complete(
        _operationId(first),
        _result(.fail),
      );
      expect(failed.repairAllowed, isTrue);
      final repair = await reserve('different-tool-id');
      expect(repair.shouldRun, isTrue);
      expect(repair.repairAttemptsRemaining, 0);
      final _ = await state.repository.complete(
        _operationId(repair),
        _result(.fail),
      );
      await state.repository.saveSettings(
        'workspace',
        _settings(revision: 1, maxRepairAttempts: 2),
      );
      final exhausted = await reserve(
        'another-tool-id',
        revision: 2,
        maxRepairAttempts: 2,
      );
      expect(exhausted.shouldRun, isFalse);
      expect(exhausted.result?.reason, 'repair_limit_reached');
      expect(exhausted.result?.outcome, ScopedVerificationOutcome.incomplete);
    },
  );

  test('successful repair does not restore previously spent tokens', () async {
    await state.repository.saveSettings('workspace', _settings());
    final first = await reserve('first');
    final _ = await state.repository.complete(
      _operationId(first),
      _result(.fail),
    );
    final repair = await reserve('repair');
    final _ = await state.repository.complete(
      _operationId(repair),
      _result(.pass),
    );
    final healthy = await reserve('healthy');
    expect(healthy.shouldRun, isTrue);
    final failed = await state.repository.complete(
      _operationId(healthy),
      _result(.fail),
    );
    expect(failed.repairAllowed, isFalse);
    expect((await reserve('exhausted')).result?.reason, 'repair_limit_reached');
  });

  test(
    'completed replay is terminal and does not run after a revision change',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final first = await reserve('edit');
      final _ = await state.repository.complete(
        _operationId(first),
        _result(.fail),
      );
      final late = await state.repository.complete(
        _operationId(first),
        _result(.pass),
      );
      expect(late.outcome, ScopedVerificationOutcome.fail);
      await state.repository.saveSettings('workspace', _settings(revision: 1));
      final replay = await reserve('edit', revision: 2);
      expect(replay.shouldRun, isFalse);
      expect(replay.result?.outcome, ScopedVerificationOutcome.fail);
      expect(
        await state.database
            .select(state.database.workspaceVerificationRuns)
            .get(),
        hasLength(1),
      );
    },
  );

  test(
    'restart preserves unknown work as incomplete without command replay',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final initial = await reserve('edit');
      final restarted = WorkspaceVerificationRepository(state.database);
      final replay = await restarted.reserve(
        (
          workspaceId: 'workspace',
          turnId: 'turn',
          toolCallId: 'edit',
          configRevision: 1,
          maxRepairAttempts: 1,
        ),
      );
      expect(replay.result?.outcome, ScopedVerificationOutcome.incomplete);
      expect(replay.result?.reason, 'interrupted');
      final late = await state.repository.complete(
        _operationId(initial),
        _result(.pass),
      );
      expect(late.outcome, ScopedVerificationOutcome.incomplete);
      expect((await reserve('new-edit')).shouldRun, isFalse);
    },
  );

  test(
    'disabling configuration before completion prevents a pass claim',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final initial = await reserve('edit');
      await state.repository.saveSettings(
        'workspace',
        _settings(enabled: false, revision: 1),
      );
      final finalResult = await state.repository.complete(
        _operationId(initial),
        _result(.pass),
      );
      expect(finalResult.outcome, ScopedVerificationOutcome.incomplete);
      expect(finalResult.reason, 'configuration_changed');
    },
  );

  test(
    'workspace deletion cascades saved authority and reservations',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final _ = await reserve('edit');
      final _ = await (state.database.delete(
        state.database.workspaces,
      )..where((row) => row.id.equals('workspace'))).go();
      expect(
        await state.database
            .select(state.database.workspaceVerificationSettings)
            .get(),
        isEmpty,
      );
      expect(
        await state.database
            .select(state.database.workspaceVerificationRuns)
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'duplicated and exported workspaces do not copy enabled authority',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final copy = await WorkspaceRepository(state.database)
          .duplicateWorkspace('workspace', name: 'Copy');
      expect((await state.repository.getSettings(copy.id)).enabled, isFalse);
      final archive = await LocalWorkspaceConfigurationRepository(
        state.database,
      ).export('workspace');
      expect(
        archive.entries.where(
          (entry) => entry.data.keys.any(
            (key) => key == 'runnerToolId' || key == 'workspaceRoot',
          ),
        ),
        isEmpty,
      );
    },
  );

  test(
    'deleting the originating conversation removes its reservations',
    () async {
      await state.repository.saveSettings('workspace', _settings());
      final _ = await reserve('edit');
      final _ = await (state.database.delete(
        state.database.conversations,
      )..where((row) => row.id.equals('chat'))).go();
      expect(
        await state.database
            .select(state.database.workspaceVerificationRuns)
            .get(),
        isEmpty,
      );
      expect((await state.repository.getSettings('workspace')).enabled, isTrue);
    },
  );
}

ScopedVerificationSettings _settings({
  bool enabled = true,
  int revision = 0,
  int maxRepairAttempts = 1,
}) => ScopedVerificationSettings(
  enabled: enabled,
  revision: revision,
  runnerToolId: 'runner',
  mcpServerId: 'server',
  workspaceRoot: 'root',
  editToolIds: const {'edit'},
  checks: [ScopedVerificationCheck(id: 'check', executable: 'check')],
  maxRepairAttempts: maxRepairAttempts,
);

ScopedVerificationResult _result(ScopedVerificationOutcome outcome) =>
    ScopedVerificationResult(outcome: outcome, reason: 'fixture');

final class _RepositoryFixture {
  AppDatabase? _database;
  WorkspaceVerificationRepository? _repository;

  AppDatabase get database =>
      _database ?? (throw StateError('Test database is not initialized.'));
  WorkspaceVerificationRepository get repository =>
      _repository ?? (throw StateError('Test repository is not initialized.'));
  set database(AppDatabase value) {
    _database = value;
  }

  set repository(WorkspaceVerificationRepository value) {
    _repository = value;
  }
}

String _operationId(ScopedVerificationReservation reservation) =>
    reservation.operationId ??
    (throw StateError('Expected a reserved verification operation.'));
