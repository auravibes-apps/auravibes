// Required: Tests repeat finders and fixture lookups for clarity.

import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/settings/usecases/save_workspace_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
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
    DraftExitGuard? guard,
  }) {
    return TestableApp(
      child: AuraThemeScope(
        theme: .light,
        child: Theme(
          data: .new(),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Material(
                child: CompactionSettingsSection(
                  workspaceId: testWorkspaceId,
                  guard: guard,
                ),
              ),
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
    DraftExitGuard? guard,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildSubject(models: models, guard: guard));
    });
    await tester.pump();
    await tester.pump();
  }

  group('draft ownership', () {
    testWidgets('invalid raw text survives refresh, cancel, and clean revert', (
      tester,
    ) async {
      final guard = DraftExitGuard();
      await pumpSubject(tester, guard: guard);
      final field = find.byType(EditableText).first;
      await tester.enterText(field, 'invalid');
      readSettingsController().add(
        const CompactionSettings(remainingTokenThreshold: 300),
      );
      await tester.pump();
      expect(tester.widget<EditableText>(field).controller.text, 'invalid');
      final exit = guard.canExit(
        tester.element(find.byType(CompactionSettingsSection)),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(await exit, isFalse);
      expect(tester.widget<EditableText>(field).controller.text, 'invalid');
      await tester.enterText(
        field,
        '${CompactionSettings.defaults.remainingTokenThreshold}',
      );
      expect(
        await guard.canExit(
          tester.element(find.byType(CompactionSettingsSection)),
        ),
        isTrue,
      );
    });

    testWidgets(
      'pending save blocks duplicate writes and exit; failure retains draft',
      (tester) async {
        final guard = DraftExitGuard();
        final pending = Completer<CompactionSettings>();
        when(
          () => readMockSave()(
            workspaceId: testWorkspaceId,
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) => pending.future);
        await pumpSubject(tester, guard: guard);
        await tester.enterText(find.byType(EditableText).first, '321');
        final save = tester.widget<AuraButton>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('settings_compaction_save')),
            matching: find.byType(AuraButton),
          ),
        );
        save.onPressed.call();
        await tester.pump();
        save.onPressed.call();
        expect(
          await guard.canExit(
            tester.element(find.byType(CompactionSettingsSection)),
          ),
          isFalse,
        );
        verify(
          () => readMockSave()(
            workspaceId: testWorkspaceId,
            settings: any(named: 'settings'),
          ),
        ).called(1);
        readSettingsController().add(
          const CompactionSettings(remainingTokenThreshold: 500),
        );
        pending.completeError(Exception('save failed'));
        final _ = await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          '321',
        );
        final exit = guard.canExit(
          tester.element(find.byType(CompactionSettingsSection)),
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Keep editing'));
        final _ = await tester.pumpAndSettle();
        expect(await exit, isFalse);
      },
    );

    testWidgets('reset blocks exits and retains text on failure', (
      tester,
    ) async {
      final guard = DraftExitGuard();
      final pending = Completer<void>();
      when(() => readMockSave().reset(workspaceId: testWorkspaceId))
          .thenAnswer((_) => pending.future);
      await pumpSubject(tester, guard: guard);
      await tester.enterText(find.byType(EditableText).first, 'reset draft');
      final reset = tester.widget<AuraButton>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('settings_compaction_reset')),
          matching: find.byType(AuraButton),
        ),
      );
      reset.onPressed();
      await tester.pump();
      reset.onPressed();
      expect(
        await guard.canExit(
          tester.element(find.byType(CompactionSettingsSection)),
        ),
        isFalse,
      );
      verify(() => readMockSave().reset(workspaceId: testWorkspaceId))
          .called(1);
      pending.completeError(Exception('reset failed'));
      final _ = await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'reset draft',
      );
      final exit = guard.canExit(
        tester.element(find.byType(CompactionSettingsSection)),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(await exit, isFalse);
    });

    testWidgets('successful save becomes clean without a stream echo', (
      tester,
    ) async {
      final guard = DraftExitGuard();
      when(
        () => readMockSave()(
          workspaceId: testWorkspaceId,
          settings: any(named: 'settings'),
        ),
      ).thenAnswer(
        (invocation) async =>
            invocation.namedArguments[#settings] as CompactionSettings,
      );
      await pumpSubject(tester, guard: guard);
      await tester.enterText(find.byType(EditableText).first, '321');
      await tester.tap(
        find.byKey(const ValueKey<String>('settings_compaction_save')),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        await guard.canExit(
          tester.element(find.byType(CompactionSettingsSection)),
        ),
        isTrue,
      );
    });
  });

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
      final remainingField = tester.widget<AuraInput>(find.byType(AuraInput));
      expect(slider.value, 45);
      expect(remainingField.controller?.text, '999');
      expect(remainingField.textInputAction, TextInputAction.done);
    });
  });

  group('model budgets', () {
    testWidgets('edits and saves exact provider/model override', (
      tester,
    ) async {
      final now = DateTime(2026);
      final model = WorkspaceModelSelectionWithConnectionEntity(
        workspaceModelSelection: .new(
          id: 'selection',
          modelId: 'model-a',
          createdAt: now,
          updatedAt: now,
          modelConnectionId: 'connection',
          modelName: 'Model A',
        ),
        modelConnection: .new(
          id: 'connection',
          name: 'Provider connection',
          modelId: 'provider',
          createdAt: now,
          updatedAt: now,
          workspaceId: testWorkspaceId,
          hasKey: true,
        ),
        modelsProvider: const .new(
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
      final guard = DraftExitGuard();
      await pumpSubject(tester, models: [model], guard: guard);

      await tester.pump();
      await tester.pump();
      expect(find.text('Provider / Model A'), findsOneWidget);
      expect(
        await guard.canExit(
          tester.element(find.byType(CompactionSettingsSection)),
        ),
        isTrue,
      );

      final fields = find.byType(EditableText);
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), 'invalid budget');
      readSettingsController().add(
        const CompactionSettings(
          modelOverrides: {
            'provider/model-a': CompactionModelOverride(reserveTokens: 999),
          },
        ),
      );
      await tester.pump();
      expect(
        tester.widget<EditableText>(fields.at(1)).controller.text,
        'invalid budget',
      );
      final exit = guard.canExit(
        tester.element(find.byType(CompactionSettingsSection)),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(await exit, isFalse);
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
      await tester.enterText(find.byType(AuraInput), '3000');

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

    testWidgets('saves remaining threshold from done keyboard action', (
      tester,
    ) async {
      when(
        () => readMockSave()(
          workspaceId: testWorkspaceId,
          settings: any(named: 'settings'),
        ),
      ).thenAnswer((_) async => CompactionSettings.defaults);

      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);
      await tester.enterText(find.byType(AuraInput), '3000');
      await tester.testTextInput.receiveAction(.done);
      final _ = await tester.pumpAndSettle();

      expect(
        () => verify(
          () => readMockSave()(
            workspaceId: testWorkspaceId,
            settings: const CompactionSettings(remainingTokenThreshold: 3000),
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
      await tester.enterText(find.byType(AuraInput), '2000');

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
      when(() => readMockSave().reset(workspaceId: testWorkspaceId))
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
            verify(() => readMockSave().reset(workspaceId: testWorkspaceId))
                .called(1),
        returnsNormally,
      );
    });

    testWidgets('resets form fields on success', (tester) async {
      when(() => readMockSave().reset(workspaceId: testWorkspaceId))
          .thenAnswer((_) => Future<void>.value());

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

      verify(() => readMockSave().reset(workspaceId: testWorkspaceId))
          .called(1);

      final slider = tester.widget<AuraSlider>(find.byType(AuraSlider));
      final remainingField = tester.widget<AuraInput>(find.byType(AuraInput));
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
