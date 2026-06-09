// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

void main() {
  group('WorkspaceCompactionSettingsDao', () {
    final fixture = _DatabaseFixture(createTestConnection);
    var workspaceId = '';

    setUp(() async {
      fixture.reset();
      final ws = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(name: 'Test WS', type: WorkspaceType.local),
      );
      workspaceId = ws.id;
    });

    tearDown(() async {
      await fixture.close();
    });

    test('getByWorkspaceId returns null for nonexistent settings', () async {
      final result = await fixture.database.workspaceCompactionSettingsDao
          .getByWorkspaceId(workspaceId);
      expect(result, isNull);
    });

    test('upsert inserts new settings row', () async {
      const companion = WorkspaceCompactionSettingsCompanion(
        autoCompactEnabled: Value(false),
        usagePercentageThreshold: Value(50),
      );
      final row = await fixture.database.workspaceCompactionSettingsDao.upsert(
        workspaceId,
        companion,
      );

      expect(row.autoCompactEnabled, false);
      expect(row.usagePercentageThreshold, 50);
      expect(row.remainingTokenThreshold, isNull);
    });

    test('upsert updates existing settings row', () async {
      final first = await fixture.database.workspaceCompactionSettingsDao
          .upsert(
            workspaceId,
            const WorkspaceCompactionSettingsCompanion(
              autoCompactEnabled: Value(false),
              usagePercentageThreshold: Value(50),
            ),
          );

      final second = await fixture.database.workspaceCompactionSettingsDao
          .upsert(
            workspaceId,
            const WorkspaceCompactionSettingsCompanion(
              autoCompactEnabled: Value(true),
              usagePercentageThreshold: Value(75),
              remainingTokenThreshold: Value(5000),
            ),
          );

      expect(second.autoCompactEnabled, true);
      expect(second.usagePercentageThreshold, 75);
      expect(second.remainingTokenThreshold, 5000);
      expect(second.id, first.id); // Same row, same PK.
    });

    test('getByWorkspaceId returns settings after upsert', () async {
      final _ = await fixture.database.workspaceCompactionSettingsDao.upsert(
        workspaceId,
        const WorkspaceCompactionSettingsCompanion(
          usagePercentageThreshold: Value(60),
        ),
      );

      final result = await fixture.database.workspaceCompactionSettingsDao
          .getByWorkspaceId(workspaceId);
      expect(result, isNotNull);
      expect(
        (result ?? fail('Expected result to be non-null'))
            .usagePercentageThreshold,
        60,
      );
    });

    test('watchByWorkspaceId emits null initially then updates', () async {
      final stream = fixture.database.workspaceCompactionSettingsDao
          .watchByWorkspaceId(
            workspaceId,
          );

      final completer = Completer<bool>();
      var callCount = 0;

      final sub = stream.listen((row) {
        callCount++;
        if (callCount == 1) {
          expect(row, isNull);
        } else if (callCount == 2 && row != null) {
          expect(row.usagePercentageThreshold, 40);
          completer.complete(true);
        }
      });

      final _ = await fixture.database.workspaceCompactionSettingsDao.upsert(
        workspaceId,
        const WorkspaceCompactionSettingsCompanion(
          usagePercentageThreshold: Value(40),
        ),
      );

      final _ = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('Stream did not emit updated value'),
      );

      await sub.cancel();
    });

    test('watchByWorkspaceId emits row when settings exist', () async {
      final _ = await fixture.database.workspaceCompactionSettingsDao.upsert(
        workspaceId,
        const WorkspaceCompactionSettingsCompanion(
          usagePercentageThreshold: Value(70),
        ),
      );

      final completer = Completer<WorkspaceCompactionSettingsTable?>();
      final sub = fixture.database.workspaceCompactionSettingsDao
          .watchByWorkspaceId(workspaceId)
          .listen((row) {
            if (!completer.isCompleted) {
              completer.complete(row);
            }
          });

      final row = await completer.future.timeout(const Duration(seconds: 5));

      expect(row, isNotNull);
      expect(
        (row ?? fail('Expected row to be non-null')).usagePercentageThreshold,
        70,
      );

      await sub.cancel();
    });

    test('deleteByWorkspaceId removes settings', () async {
      final _ = await fixture.database.workspaceCompactionSettingsDao.upsert(
        workspaceId,
        const WorkspaceCompactionSettingsCompanion(
          usagePercentageThreshold: Value(80),
        ),
      );

      await fixture.database.workspaceCompactionSettingsDao.deleteByWorkspaceId(
        workspaceId,
      );

      final result = await fixture.database.workspaceCompactionSettingsDao
          .getByWorkspaceId(workspaceId);
      expect(result, isNull);
    });
  });
}
