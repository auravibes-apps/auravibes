import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/usecases/reset_workspace_compaction_settings_usecase.dart';
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

class MockResetUsecase extends Mock
    implements ResetWorkspaceCompactionSettingsUsecase {}

void main() {
  const testWorkspaceId = 'test-ws';

  late MockSaveUsecase mockSave;
  late MockResetUsecase mockReset;
  late StreamController<CompactionSettings> settingsController;

  setUpAll(() {
    registerFallbackValue(CompactionSettings.defaults);
  });

  setUp(() {
    mockSave = MockSaveUsecase();
    mockReset = MockResetUsecase();
    settingsController = StreamController<CompactionSettings>.broadcast();
  });

  tearDown(() {
    settingsController.close();
  });

  Widget buildSubject() {
    return testableApp(
      overrides: [
        compactionSettingsProvider(testWorkspaceId).overrideWith(
          (ref) => settingsController.stream,
        ),
        saveWorkspaceCompactionSettingsUsecaseProvider.overrideWith(
          (ref) => mockSave,
        ),
        resetWorkspaceCompactionSettingsUsecaseProvider.overrideWith(
          (ref) => mockReset,
        ),
      ],
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
      settingsController.add(CompactionSettings.defaults);
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
      settingsController.add(CompactionSettings.defaults);
      await pumpSubject(tester);

      settingsController.add(
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
        () => mockSave(
          workspaceId: testWorkspaceId,
          settings: any(named: 'settings'),
        ),
      ).thenAnswer((_) async => CompactionSettings.defaults);

      settingsController.add(CompactionSettings.defaults);
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

      verify(
        () => mockSave(
          workspaceId: testWorkspaceId,
          settings: const CompactionSettings(
            usagePercentageThreshold: 50,
            remainingTokenThreshold: 3000,
          ),
        ),
      ).called(1);
    });

    testWidgets('shows validation error on usecase exception', (tester) async {
      when(
        () => mockSave(
          workspaceId: testWorkspaceId,
          settings: any(named: 'settings'),
        ),
      ).thenThrow(
        const CompactionSettingsValidationException(
          LocaleKeys.compaction_settings_validation_usage_range,
        ),
      );

      settingsController.add(CompactionSettings.defaults);
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

      verify(
        () => mockSave(
          workspaceId: testWorkspaceId,
          settings: const CompactionSettings(
            usagePercentageThreshold: 2,
          ),
        ),
      ).called(1);
    });
  });

  group('_resetDefaults', () {
    testWidgets('calls reset usecase even when it fails', (tester) async {
      when(
        () => mockReset(workspaceId: testWorkspaceId),
      ).thenThrow(Exception('DB error'));

      settingsController.add(CompactionSettings.defaults);
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

      verify(() => mockReset(workspaceId: testWorkspaceId)).called(1);
    });

    testWidgets('resets form fields on success', (tester) async {
      when(
        () => mockReset(workspaceId: testWorkspaceId),
      ).thenAnswer((_) async => CompactionSettings.defaults);

      settingsController.add(CompactionSettings.defaults);
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

      verify(() => mockReset(workspaceId: testWorkspaceId)).called(1);

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
