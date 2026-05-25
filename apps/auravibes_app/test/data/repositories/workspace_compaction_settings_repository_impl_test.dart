import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_compaction_settings_dao.dart';
import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository_impl.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDao extends Mock implements WorkspaceCompactionSettingsDao {}

class FakeCompanion extends Fake
    implements WorkspaceCompactionSettingsCompanion {}

void main() {
  late MockDao mockDao;
  late WorkspaceCompactionSettingsRepository repo;

  setUpAll(() {
    registerFallbackValue(FakeCompanion());
  });

  setUp(() {
    mockDao = MockDao();
    repo = WorkspaceCompactionSettingsRepositoryImpl(mockDao);
  });

  group('getEffectiveSettings', () {
    test('returns defaults when no row exists', () async {
      when(() => mockDao.getByWorkspaceId('ws-1')).thenAnswer(
        (_) async => null,
      );

      final settings = await repo.getEffectiveSettings('ws-1');

      expect(settings.autoCompactionEnabled, isTrue);
      expect(settings.usagePercentageThreshold, 80);
      expect(settings.remainingTokenThreshold, 2000);
      expect(settings.updatedAt, isNull);
    });
    test('returns stored overrides with fallbacks for null columns', () async {
      final row = WorkspaceCompactionSettingsTable(
        id: 'row-1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 2),
        workspaceId: 'ws-1',
        autoCompactEnabled: false,
        usagePercentageThreshold: 50,
      );
      when(() => mockDao.getByWorkspaceId('ws-1')).thenAnswer(
        (_) async => row,
      );

      final settings = await repo.getEffectiveSettings('ws-1');

      expect(settings.autoCompactionEnabled, isFalse);
      expect(settings.usagePercentageThreshold, 50);
      expect(settings.remainingTokenThreshold, 2000); // falls back
      expect(settings.updatedAt, DateTime(2026, 1, 2));
    });
  });

  group('watchEffectiveSettings', () {
    test('maps null row to defaults', () {
      when(() => mockDao.watchByWorkspaceId('ws-1')).thenAnswer(
        (_) => Stream.value(null),
      );

      expect(
        repo.watchEffectiveSettings('ws-1'),
        emits(
          predicate<CompactionSettings>(
            (s) => s.autoCompactionEnabled && s.remainingTokenThreshold == 2000,
          ),
        ),
      );
    });
  });

  group('saveOverrides', () {
    test('upserts and returns resolved settings', () async {
      final row = WorkspaceCompactionSettingsTable(
        id: 'row-2',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 1, 2),
        workspaceId: 'ws-1',
        autoCompactEnabled: false,
        usagePercentageThreshold: 90,
        remainingTokenThreshold: 5000,
      );
      when(
        () => mockDao.upsert('ws-1', any()),
      ).thenAnswer((_) async => row);

      final settings = await repo.saveOverrides(
        'ws-1',
        const CompactionSettings(
          autoCompactionEnabled: false,
          usagePercentageThreshold: 90,
          remainingTokenThreshold: 5000,
        ),
      );

      final captured =
          verify(
                () => mockDao.upsert('ws-1', captureAny()),
              ).captured.single
              as WorkspaceCompactionSettingsCompanion;
      expect(captured.autoCompactEnabled.value, isFalse);
      expect(captured.usagePercentageThreshold.value, 90);
      expect(captured.remainingTokenThreshold.value, 5000);

      expect(settings.autoCompactionEnabled, isFalse);
      expect(settings.usagePercentageThreshold, 90);
      expect(settings.remainingTokenThreshold, 5000);
    });
  });

  group('resetOverrides', () {
    test('deletes row and returns defaults', () async {
      when(() => mockDao.deleteByWorkspaceId('ws-1')).thenAnswer(
        (_) async => 1,
      );

      final settings = await repo.resetOverrides('ws-1');

      expect(settings.autoCompactionEnabled, isTrue);
      expect(settings.remainingTokenThreshold, 2000);
      expect(settings.updatedAt, isNull);
    });
  });
}
