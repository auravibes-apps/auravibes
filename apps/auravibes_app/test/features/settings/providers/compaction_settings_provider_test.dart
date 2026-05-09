import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/settings/usecases/reset_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/settings/usecases/save_compaction_settings_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockWorkspaceCompactionSettingsRepository extends Mock
    implements WorkspaceCompactionSettingsRepository {}

void main() {
  const testWorkspaceId = 'workspace-1';

  group('CompactionSettings', () {
    test('defaults have expected values', () {
      const settings = CompactionSettings.defaults;
      expect(settings.autoCompactionEnabled, true);
      expect(settings.usagePercentageThreshold, 80);
      expect(settings.remainingTokenThreshold, 2000);
      expect(settings.updatedAt, isNull);
    });

    test('defaults constant matches default constructor', () {
      expect(CompactionSettings.defaults, CompactionSettings.defaults);
    });

    test(
      'defaultRemainingTokenThreshold returns 2000 for null contextLimit',
      () {
        expect(
          CompactionSettings.defaultRemainingTokenThreshold(
            maxOutputTokens: 4096,
            contextLimit: null,
          ),
          2000,
        );
      },
    );

    test('defaultRemainingTokenThreshold uses maxOutputTokens when larger', () {
      expect(
        CompactionSettings.defaultRemainingTokenThreshold(
          maxOutputTokens: 4096,
          contextLimit: 10000,
        ),
        4096,
      );
    });

    test('defaultRemainingTokenThreshold uses 20% when larger', () {
      expect(
        CompactionSettings.defaultRemainingTokenThreshold(
          maxOutputTokens: 1000,
          contextLimit: 100000,
        ),
        15000,
      );
    });

    test('defaultRemainingTokenThreshold caps at 15000', () {
      expect(
        CompactionSettings.defaultRemainingTokenThreshold(
          maxOutputTokens: 1000,
          contextLimit: 200000,
        ),
        15000,
      );
    });

    test('fromJson/toJson round-trip', () {
      const settings = CompactionSettings(
        autoCompactionEnabled: false,
        usagePercentageThreshold: 50,
        remainingTokenThreshold: 5000,
      );
      final json = settings.toJson();
      final restored = CompactionSettings.fromJson(json);
      expect(restored, settings);
    });
  });

  group('compactionSettingsProvider', () {
    test('reads overridden value', () async {
      final container = ProviderContainer(
        overrides: [
          compactionSettingsProvider(testWorkspaceId).overrideWithValue(
            const AsyncData(CompactionSettings.defaults),
          ),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = container.read(
        compactionSettingsProvider(testWorkspaceId),
      );
      expect(asyncValue.value, CompactionSettings.defaults);
    });

    test('reads custom overridden value', () async {
      const custom = CompactionSettings(
        autoCompactionEnabled: false,
        usagePercentageThreshold: 60,
        remainingTokenThreshold: 3000,
      );

      final container = ProviderContainer(
        overrides: [
          compactionSettingsProvider(testWorkspaceId).overrideWithValue(
            const AsyncData(custom),
          ),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = container.read(
        compactionSettingsProvider(testWorkspaceId),
      );
      expect(asyncValue.asData?.value.autoCompactionEnabled, false);
      expect(asyncValue.asData?.value.usagePercentageThreshold, 60);
      expect(asyncValue.asData?.value.remainingTokenThreshold, 3000);
    });
  });

  group('SaveWorkspaceCompactionSettingsUsecase', () {
    late MockWorkspaceCompactionSettingsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockWorkspaceCompactionSettingsRepository();
      container = ProviderContainer(
        overrides: [
          workspaceCompactionSettingsRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('persists via repository', () async {
      const newSettings = CompactionSettings(
        autoCompactionEnabled: false,
        usagePercentageThreshold: 70,
        remainingTokenThreshold: 4000,
      );
      when(
        () => mockRepository.saveOverrides(testWorkspaceId, newSettings),
      ).thenAnswer(
        (_) async => newSettings.copyWith(updatedAt: DateTime(2026)),
      );

      await container.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: testWorkspaceId,
        settings: newSettings,
      );

      verify(
        () => mockRepository.saveOverrides(testWorkspaceId, newSettings),
      ).called(1);
    });

    test('rejects usage percentage below 5', () async {
      const invalid = CompactionSettings(
        usagePercentageThreshold: 4,
        remainingTokenThreshold: 1000,
      );

      expect(
        () => container.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
          workspaceId: testWorkspaceId,
          settings: invalid,
        ),
        throwsA(isA<CompactionSettingsValidationException>()),
      );
    });

    test('rejects usage percentage above 100', () async {
      const invalid = CompactionSettings(
        usagePercentageThreshold: 101,
        remainingTokenThreshold: 1000,
      );

      expect(
        () => container.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
          workspaceId: testWorkspaceId,
          settings: invalid,
        ),
        throwsA(isA<CompactionSettingsValidationException>()),
      );
    });

    test('rejects remaining token threshold <= 0', () async {
      const invalid = CompactionSettings(
        usagePercentageThreshold: 50,
        remainingTokenThreshold: 0,
      );

      expect(
        () => container.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
          workspaceId: testWorkspaceId,
          settings: invalid,
        ),
        throwsA(isA<CompactionSettingsValidationException>()),
      );
    });

    test('accepts valid settings at boundary 5', () async {
      const valid = CompactionSettings(
        usagePercentageThreshold: 5,
        remainingTokenThreshold: 1,
      );
      when(
        () => mockRepository.saveOverrides(testWorkspaceId, valid),
      ).thenAnswer((_) async => valid.copyWith(updatedAt: DateTime(2026)));

      await container.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: testWorkspaceId,
        settings: valid,
      );
    });

    test('accepts valid settings at boundary 100', () async {
      const valid = CompactionSettings(
        usagePercentageThreshold: 100,
        remainingTokenThreshold: 10000,
      );
      when(
        () => mockRepository.saveOverrides(testWorkspaceId, valid),
      ).thenAnswer((_) async => valid.copyWith(updatedAt: DateTime(2026)));

      await container.read(saveWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: testWorkspaceId,
        settings: valid,
      );
    });
  });

  group('ResetWorkspaceCompactionSettingsUsecase', () {
    late MockWorkspaceCompactionSettingsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockWorkspaceCompactionSettingsRepository();
      container = ProviderContainer(
        overrides: [
          workspaceCompactionSettingsRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('calls repository reset', () async {
      when(
        () => mockRepository.resetOverrides(testWorkspaceId),
      ).thenAnswer((_) async => CompactionSettings.defaults);

      await container.read(resetWorkspaceCompactionSettingsUsecaseProvider)(
        workspaceId: testWorkspaceId,
      );

      verify(() => mockRepository.resetOverrides(testWorkspaceId)).called(1);
    });
  });
}
