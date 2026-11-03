// ignore_for_file: avoid-late-keyword - async setUp needs fixtures

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/domain/exceptions/scoped_verification_settings_exception.dart';
import 'package:auravibes_app/features/settings/usecases/save_scoped_verification_settings_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late WorkspaceVerificationRepository repository;
  late SaveScopedVerificationSettingsUsecase save;
  late List<String> calls;
  var allowed = true;
  var compliant = true;
  var revokeDuringProbe = false;
  Future<ScopedVerificationCapabilities> Function()? probeOverride;
  Future<bool> Function()? bindingsOverride;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    repository = WorkspaceVerificationRepository(database);
    calls = [];
    allowed = true;
    compliant = true;
    revokeDuringProbe = false;
    probeOverride = null;
    bindingsOverride = null;
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('local'),
            name: 'Local',
            type: .local,
          ),
        );
    save = SaveScopedVerificationSettingsUsecase(
      repository: repository,
      validateBindings: (workspaceId, settings) async {
        calls.add('bindings:$workspaceId');
        final override = bindingsOverride;
        if (override != null) return await override();

        return allowed;
      },
      probeCapabilities: (workspaceId, settings, deadline) async {
        calls.add('capabilities:$workspaceId');
        if (revokeDuringProbe) allowed = false;
        final override = probeOverride;
        if (override != null) return await override();

        return ScopedVerificationCapabilities(
          protocol: ScopedVerificationLimits.protocol,
          features: ScopedVerificationCapabilities.requiredFeatures
              .where((feature) => compliant || feature != 'nonInteractive')
              .toSet(),
        );
      },
      probeTimeout: const Duration(milliseconds: 50),
    );
  });
  tearDown(() => database.close());

  test(
    'enabling probes capabilities between two binding checks and saves',
    () async {
      await save(workspaceId: 'local', settings: _settings());
      expect(calls, ['bindings:local', 'capabilities:local', 'bindings:local']);
      final saved = await repository.getSettings('local');
      expect(saved.enabled, isTrue);
      expect(saved.revision, 1);
    },
  );

  test('disabling saves without a binding check or runner probe', () async {
    await repository.saveSettings('local', _settings());
    allowed = false;
    await save(
      workspaceId: 'local',
      settings: _settings(enabled: false, revision: 1),
    );
    expect(calls, isEmpty);
    expect((await repository.getSettings('local')).enabled, isFalse);
  });

  test('invalid or foreign bindings prevent even a capability probe', () async {
    allowed = false;
    await expectLater(
      save(workspaceId: 'local', settings: _settings()),
      throwsA(isA<ScopedVerificationSettingsException>()),
    );
    expect(calls, ['bindings:local']);
    expect((await repository.getSettings('local')).revision, 0);
  });

  test(
    'missing nonInteractive capability cannot enable verification',
    () async {
      compliant = false;
      await expectLater(
        save(workspaceId: 'local', settings: _settings()),
        throwsA(isA<ScopedVerificationSettingsException>()),
      );
      expect((await repository.getSettings('local')).enabled, isFalse);
    },
  );

  test('revocation while probing prevents persistence', () async {
    revokeDuringProbe = true;
    await expectLater(
      save(workspaceId: 'local', settings: _settings()),
      throwsA(isA<ScopedVerificationSettingsException>()),
    );
    expect(calls.last, 'bindings:local');
    expect((await repository.getSettings('local')).revision, 0);
  });

  test(
    'connection failure and a hanging capability probe stay bounded',
    () async {
      probeOverride = () async => throw StateError('Disconnected');
      await expectLater(
        save(workspaceId: 'local', settings: _settings()),
        throwsA(isA<ScopedVerificationSettingsException>()),
      );
      probeOverride = () => Completer<ScopedVerificationCapabilities>().future;
      await expectLater(
        save(
          workspaceId: 'local',
          settings: _settings(),
        ).timeout(const Duration(seconds: 2)),
        throwsA(isA<ScopedVerificationSettingsException>()),
      );
      expect((await repository.getSettings('local')).revision, 0);
    },
  );

  test(
    'a late binding check cannot start a probe after the save deadline',
    () async {
      final binding = Completer<bool>();
      bindingsOverride = () => binding.future;
      await expectLater(
        save(
          workspaceId: 'local',
          settings: _settings(),
        ).timeout(const Duration(seconds: 2)),
        throwsA(isA<ScopedVerificationSettingsException>()),
      );
      binding.complete(true);
      await Future<void>.delayed(.zero);
      expect(calls, ['bindings:local']);
      expect((await repository.getSettings('local')).revision, 0);
    },
  );

  test(
    'stale revision and cloud workspace saves fail without changing policy',
    () async {
      await save(workspaceId: 'local', settings: _settings());
      await expectLater(
        save(workspaceId: 'local', settings: _settings()),
        throwsA(isA<ScopedVerificationSettingsException>()),
      );
      final _ =
          await (database.update(database.workspaces)
                ..where((row) => row.id.equals('local')))
              .write(const WorkspacesCompanion(type: .new(.remote)));
      calls.clear();
      await expectLater(
        save(workspaceId: 'local', settings: _settings(revision: 1)),
        throwsA(isA<ScopedVerificationSettingsException>()),
      );
      await expectLater(
        save(
          workspaceId: 'local',
          settings: _settings(enabled: false, revision: 1),
        ),
        throwsA(isA<ScopedVerificationSettingsException>()),
      );
      expect(calls, isEmpty);
    },
  );
}

ScopedVerificationSettings _settings({bool enabled = true, int revision = 0}) =>
    ScopedVerificationSettings(
      enabled: enabled,
      revision: revision,
      runnerToolId: 'runner',
      mcpServerId: 'server',
      workspaceRoot: 'checkout',
      editToolIds: const {'edit'},
      checks: [
        ScopedVerificationCheck(
          id: 'analyze',
          executable: 'dart',
          arguments: const ['analyze'],
          pathSuffixes: const ['.dart'],
        ),
      ],
    );
