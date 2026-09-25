// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/settings/usecases/save_workspace_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/test_app.dart';

class MockSaveUsecase extends Mock
    implements SaveWorkspaceCompactionSettingsUsecase;

class MockCompactionSettingsRepository extends Mock
    implements WorkspaceCompactionSettingsRepository;

void main() {
  const testWorkspaceId = 'test-ws';

  MockSaveUsecase? mockSave;
  MockCompactionSettingsRepository? mockRepository;
  StreamController<CompactionSettings>? settingsController;
  MockSaveUsecase readMockSave() =>
      mockSave ?? fail('MockSaveUsecase not initialized');
  MockCompactionSettingsRepository readMockRepository() =>
      mockRepository ??
      fail('MockCompactionSettingsRepository not initialized');
  StreamController<CompactionSettings> readSettingsController() =>
      settingsController ?? fail('Settings stream not initialized');

  setUpAll(() {
    registerFallbackValue(CompactionSettings.defaults);
  });

  setUp(() {
    mockSave = MockSaveUsecase();
    mockRepository = MockCompactionSettingsRepository();
    settingsController = StreamController<CompactionSettings>.broadcast();
  });

  tearDown(() async {
    final controller = settingsController;
    if (controller != null) {
      final _ = await controller.close();
    }
  });

  Widget buildSubject({
    List<WorkspaceModelSelectionWithConnectionEntity> models = const [],
  }) {
    return TestableApp(
      child: Theme(
        data: .new(extensions: [AuraTheme.light]),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Material(
              child: CompactionSettingsSection(workspaceId: testWorkspaceId),
            ),
          ),
        ),
      ),
      overrides: [
        listWorkspaceModelSelectionsProvider(workspaceId: testWorkspaceId)
            .overrideWith((ref) => Stream.value(models)),
        compactionSettingsProvider(testWorkspaceId)
            .overrideWith((ref) => readSettingsController().stream),
        saveWorkspaceCompactionSettingsUsecaseProvider(testWorkspaceId)
            .overrideWith((ref) => readMockSave()),
        workspaceCompactionSettingsRepositoryProvider.overrideWith(
          (ref) => readMockRepository(),
        ),
        workspaceSessionForRouteProvider(testWorkspaceId).overrideWithValue(
          const AsyncData(
            WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: testWorkspaceId),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> pumpSubject(
    WidgetTester tester, {
    List<WorkspaceModelSelectionWithConnectionEntity> models = const [],
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildSubject(models: models));
    });
    await tester.pump();
    await tester.pump();
  }

  group('render', () {
    testWidgets('renders title, subtitle and switch', (tester) async {
      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);
      expect(find.byType(CompactionSettingsSection), findsOneWidget);
      expect(find.byType(AuraSwitch), findsOneWidget);
      final slider = tester.widget<AuraSlider>(find.byType(AuraSlider));
      expect(slider.value, 80);
      expect(slider.min, 5);
      expect(slider.max, 100);
      expect(find.byType(AuraButton), findsNWidgets(2));
    });
  });

  group('stream listener', () {
    testWidgets('updates form fields when stream emits new settings', (
      tester,
    ) async {
      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);

      readSettingsController().add(
        const CompactionSettings(
          autoCompactionEnabled: false,
          usagePercentageThreshold: 45,
          remainingTokenThreshold: 999,
        ),
      );
      await tester.pump();
      await tester.pump();

      final toggle = tester.widget<AuraSwitch>(find.byType(AuraSwitch));
      expect(toggle.value, isFalse);

      final slider = tester.widget<AuraSlider>(find.byType(AuraSlider));
      final remainingField = tester.widget<TextField>(find.byType(TextField));
      expect(slider.value, 45);
      expect(remainingField.controller?.text, '999');
    });
  });

  group('model budgets', () {
    testWidgets('edits and saves exact provider/model override', (
      tester,
    ) async {
      final now = DateTime(2026);
      final model = WorkspaceModelSelectionWithConnectionEntity(
        workspaceModelSelection: WorkspaceModelSelectionEntity(
          id: 'selection',
          modelId: 'model-a',
          createdAt: now,
          updatedAt: now,
          modelConnectionId: 'connection',
          modelName: 'Model A',
        ),
        modelConnection: ModelConnectionEntity(
          id: 'connection',
          name: 'Provider connection',
          modelId: 'provider',
          createdAt: now,
          updatedAt: now,
          workspaceId: testWorkspaceId,
          hasKey: true,
        ),
        modelsProvider: const ApiModelProviderEntity(
          id: 'provider',
          name: 'Provider',
          type: ModelProvidersType.openai,
        ),
      );
      when(
        () => readMockSave()(
          workspaceId: testWorkspaceId,
          settings: any(named: 'settings'),
        ),
      ).thenAnswer((_) async => CompactionSettings.defaults);
      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester, models: [model]);

      await tester.pump();
      await tester.pump();
      expect(find.text('Provider / Model A'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), '256');
      await tester.enterText(fields.at(2), '1024');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(
        find
            .descendant(
              of: find.byType(AuraButton),
              matching: find.byType(Text),
            )
            .last,
      );
      await tester.pump();

      verify(
        () => readMockSave()(
          workspaceId: testWorkspaceId,
          settings: const CompactionSettings(
            modelOverrides: {
              'provider/model-a': CompactionModelOverride(
                reserveTokens: 256,
                keepRecentTokens: 1024,
              ),
            },
          ),
        ),
      ).called(1);
    });
  });

  group('_save', () {
    testWidgets('calls save usecase with parsed thresholds', (tester) async {
      when(
        () => readMockSave()(
          workspaceId: testWorkspaceId,
          settings: any(named: 'settings'),
        ),
      ).thenAnswer((_) async => CompactionSettings.defaults);

      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);

      tester.widget<AuraSlider>(find.byType(AuraSlider)).onChanged?.call(50);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '3000');

      await tester.tap(
        find
            .descendant(
              of: find.byType(AuraButton),
              matching: find.byType(Text),
            )
            .last,
      );
      await tester.pump();

      expect(
        () => verify(
          () => readMockSave()(
            workspaceId: testWorkspaceId,
            settings: const CompactionSettings(
              usagePercentageThreshold: 50,
              remainingTokenThreshold: 3000,
            ),
          ),
        ).called(1),
        returnsNormally,
      );
    });

    testWidgets('shows validation error on usecase exception', (tester) async {
      when(
        () => readMockSave()(
          workspaceId: testWorkspaceId,
          settings: any(named: 'settings'),
        ),
      ).thenThrow(
        const CompactionSettingsValidationException(
          LocaleKeys.compaction_settings_validation_usage_range,
        ),
      );

      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);

      tester.widget<AuraSlider>(find.byType(AuraSlider)).onChanged?.call(50);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '2000');

      await tester.tap(
        find
            .descendant(
              of: find.byType(AuraButton),
              matching: find.byType(Text),
            )
            .last,
      );
      await tester.pump();

      expect(
        () => verify(
          () => readMockSave()(
            workspaceId: testWorkspaceId,
            settings: const CompactionSettings(usagePercentageThreshold: 50),
          ),
        ).called(1),
        returnsNormally,
      );
    });
  });

  group('_resetDefaults', () {
    testWidgets('calls reset usecase even when it fails', (tester) async {
      when(() => readMockRepository().resetOverrides(testWorkspaceId))
          .thenThrow(Exception('DB error'));

      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);

      await tester.tap(
        find
            .descendant(
              of: find.byType(AuraButton),
              matching: find.byType(TextLocale),
            )
            .first,
      );
      await tester.pump();

      expect(
        () =>
            verify(() => readMockRepository().resetOverrides(testWorkspaceId))
                .called(1),
        returnsNormally,
      );
    });

    testWidgets('resets form fields on success', (tester) async {
      when(() => readMockRepository().resetOverrides(testWorkspaceId))
          .thenAnswer((_) async => CompactionSettings.defaults);

      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);

      await tester.tap(
        find
            .descendant(
              of: find.byType(AuraButton),
              matching: find.byType(TextLocale),
            )
            .first,
      );
      await tester.pump();

      verify(() => readMockRepository().resetOverrides(testWorkspaceId))
          .called(1);

      final slider = tester.widget<AuraSlider>(find.byType(AuraSlider));
      final remainingField = tester.widget<TextField>(find.byType(TextField));
      expect(
        slider.value,
        CompactionSettings.defaults.usagePercentageThreshold,
      );
      expect(
        remainingField.controller?.text,
        '${CompactionSettings.defaults.remainingTokenThreshold}',
      );
    });
  });
}
