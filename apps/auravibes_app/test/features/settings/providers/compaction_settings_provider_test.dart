// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.

// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/settings/usecases/reset_workspace_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/settings/usecases/save_workspace_compaction_settings_usecase.dart';
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

  group('Compaction entities JSON', () {
    test('ConversationPromptEstimate fromJson/toJson', () {
      final json = <String, dynamic>{
        'conversationId': 'c1',
        'selectedModelId': 'm1',
        'selectedProviderId': 'p1',
        'estimatedPromptTokens': 1000,
        'maxOutputTokens': 4096,
        'contextLimit': 128000,
        'remainingTokens': 127000,
        'usagePercentage': 0.78,
      };
      final e = ConversationPromptEstimate.fromJson(json);
      expect(e.conversationId, 'c1');
      expect(e.estimatedPromptTokens, 1000);
      expect(e.remainingTokens, 127000);
      expect(e.usagePercentage, 0.78);
      expect(e.toJson()['conversationId'], 'c1');
    });

    test('CompactionDecision fromJson/toJson', () {
      final json = <String, dynamic>{
        'shouldCompact': true,
        'reason': 'eligible',
        'trigger': 'auto',
      };
      final d = CompactionDecision.fromJson(json);
      expect(d.shouldCompact, isTrue);
      expect(d.reason, CompactionDecisionReason.eligible);
      expect(d.trigger, CompactionTrigger.auto);
      expect(d.toJson()['shouldCompact'], isTrue);
    });

    test('CompactionRange fromJson/toJson', () {
      final json = <String, dynamic>{
        'fromMessageId': 'a',
        'throughMessageId': 'b',
        'messageIds': ['a', 'b'],
        'keptTailMessageIds': ['c'],
      };
      final r = CompactionRange.fromJson(json);
      expect(r.fromMessageId, 'a');
      expect(r.throughMessageId, 'b');
      expect(r.messageIds, ['a', 'b']);
      expect(r.toJson()['fromMessageId'], 'a');
    });

    test('CompactionExecutionState fromJson/toJson', () {
      final json = <String, String>{
        'conversationId': 'c1',
        'trigger': 'manual',
        'startedAt': '2026-01-01T00:00:00.000',
        'status': 'running',
      };
      final s = CompactionExecutionState.fromJson(json);
      expect(s.conversationId, 'c1');
      expect(s.trigger, CompactionTrigger.manual);
      expect(s.status, CompactionExecutionStatus.running);
      expect(s.toJson()['conversationId'], 'c1');
    });

    test('ContextOverflowRetryState fromJson/toJson', () {
      final json = <String, dynamic>{
        'conversationId': 'c1',
        'assistantRequestId': 'r1',
        'hasRetriedAfterCompaction': true,
      };
      final s = ContextOverflowRetryState.fromJson(json);
      expect(s.conversationId, 'c1');
      expect(s.hasRetriedAfterCompaction, isTrue);
      expect(s.toJson()['conversationId'], 'c1');
    });

    test('ContextOverflowRetryState defaults hasRetriedAfterCompaction', () {
      const s = ContextOverflowRetryState(
        conversationId: 'c1',
        assistantRequestId: 'r1',
      );
      expect(s.hasRetriedAfterCompaction, isFalse);
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

      final _ =
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

      final _ =
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

      final _ =
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

      final _ =
          await container.read(resetWorkspaceCompactionSettingsUsecaseProvider)(
            workspaceId: testWorkspaceId,
          );

      verify(() => mockRepository.resetOverrides(testWorkspaceId)).called(1);
    });
  });
}
