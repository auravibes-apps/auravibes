// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_compaction_settings_repository_provider.dart';
import 'package:auravibes_app/features/settings/usecases/save_workspace_compaction_settings_usecase.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

class MockSaveUsecase extends Mock
    implements SaveWorkspaceCompactionSettingsUsecase {}

class MockCompactionSettingsRepository extends Mock
    implements WorkspaceCompactionSettingsRepository {}

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

  tearDown(() {
    final _ = settingsController?.close();
  });

  Widget buildSubject() {
    return TestableApp(
      child: Theme(
        data: ThemeData(extensions: [AuraTheme.light]),
        child: const Scaffold(
          body: Material(
            child: CompactionSettingsSection(
              workspaceId: testWorkspaceId,
            ),
          ),
        ),
      ),
      overrides: [
        compactionSettingsProvider(testWorkspaceId).overrideWith(
          (ref) => readSettingsController().stream,
        ),
        saveWorkspaceCompactionSettingsUsecaseProvider.overrideWith(
          (ref) => readMockSave(),
        ),
        workspaceCompactionSettingsRepositoryProvider.overrideWith(
          (ref) => readMockRepository(),
        ),
      ],
    );
  }

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildSubject());
    });
    await tester.pump();
    await tester.pump();
  }

  group('render', () {
    testWidgets('renders title, subtitle and switch', (tester) async {
      readSettingsController().add(CompactionSettings.defaults);
      await pumpSubject(tester);
      expect(find.byType(CompactionSettingsSection), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
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

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);

      final textFields = find.byType(TextField);
      final usageField = tester.widget<TextField>(textFields.first);
      final remainingField = tester.widget<TextField>(textFields.last);
      expect(usageField.controller?.text, '45');
      expect(remainingField.controller?.text, '999');
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

      await tester.enterText(find.byType(TextField).first, '50');
      await tester.enterText(find.byType(TextField).last, '3000');

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

      await tester.enterText(find.byType(TextField).first, '2');
      await tester.enterText(find.byType(TextField).last, '2000');

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
              usagePercentageThreshold: 2,
            ),
          ),
        ).called(1),
        returnsNormally,
      );
    });
  });

  group('_resetDefaults', () {
    testWidgets('calls reset usecase even when it fails', (tester) async {
      when(
        () => readMockRepository().resetOverrides(testWorkspaceId),
      ).thenThrow(Exception('DB error'));

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
        () => verify(
          () => readMockRepository().resetOverrides(testWorkspaceId),
        ).called(1),
        returnsNormally,
      );
    });

    testWidgets('resets form fields on success', (tester) async {
      when(
        () => readMockRepository().resetOverrides(testWorkspaceId),
      ).thenAnswer((_) async => CompactionSettings.defaults);

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

      verify(
        () => readMockRepository().resetOverrides(testWorkspaceId),
      ).called(1);

      final textFields = find.byType(TextField);
      final usageField = tester.widget<TextField>(textFields.first);
      final remainingField = tester.widget<TextField>(textFields.last);
      expect(
        usageField.controller?.text,
        '${CompactionSettings.defaults.usagePercentageThreshold}',
      );
      expect(
        remainingField.controller?.text,
        '${CompactionSettings.defaults.remainingTokenThreshold}',
      );
    });
  });
}
