// ignore_for_file: avoid-returning-widgets
// Required: Widget tests use helpers that build widgets under test.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-moving-to-variable
// Required: Tests repeat finders and fixture lookups for clarity.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.
import 'dart:async';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/add_tool_modal.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _wsId = 'ws1';

Widget _buildSubject(List<Object> overrides) {
  return EasyLocalization(
    child: ProviderScope(
      overrides: overrides.cast(),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            home: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const Scaffold(body: SizedBox.shrink()),
            ),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
          );
        },
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}

Future<void> _pumpAndInit(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
  });
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _showDialog(WidgetTester tester) async {
  await tester.runAsync(() {
    AddToolModal.show(
      tester.element(find.byType(Scaffold)),
      workspaceId: _wsId,
    );

    return Future<void>.value();
  });
  await tester.pump();
  await tester.pump();
}

List<Object> _dataOverride([
  List<UserToolType> tools = const [UserToolType.calculator],
]) {
  return [
    availableToolsToAddProvider.overrideWith(
      (ref, arg) async => tools,
    ),
  ];
}

class _RecordingWorkspaceToolsNotifier extends WorkspaceToolsNotifier {
  UserToolType? _addedTool;

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async => const [];

  @override
  Future<void> addTool(UserToolType toolType) async {
    _addedTool = toolType;
  }

  bool hasAdded(UserToolType toolType) => _addedTool == toolType;
}

void main() {
  test('constructor stores workspaceId', () {
    const modal = AddToolModal(workspaceId: _wsId);
    expect(modal.workspaceId, _wsId);
  });

  group('AddToolModal', () {
    testWidgets('show opens a dialog', (tester) async {
      await _pumpAndInit(tester, _buildSubject(_dataOverride()));
      await _showDialog(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(AddToolModal), findsOneWidget);
    });

    testWidgets('renders search input', (tester) async {
      await _pumpAndInit(tester, _buildSubject(_dataOverride()));
      await _showDialog(tester);

      expect(find.byType(AuraInput), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      await _pumpAndInit(tester, _buildSubject(_dataOverride()));
      await _showDialog(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await _pumpAndInit(tester, _buildSubject(_dataOverride()));
      await _showDialog(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.byType(AddToolModal), findsNothing);
    });

    testWidgets('shows loading spinner when loading', (tester) async {
      final completer = Completer<List<UserToolType>>();

      await _pumpAndInit(
        tester,
        _buildSubject([
          availableToolsToAddProvider.overrideWith(
            (ref, arg) => completer.future,
          ),
        ]),
      );
      await _showDialog(tester);

      expect(find.byType(AuraSpinner), findsOneWidget);

      completer.complete([UserToolType.calculator]);
    });

    testWidgets('shows tools when data loaded', (tester) async {
      await _pumpAndInit(tester, _buildSubject(_dataOverride()));
      await _showDialog(tester);

      expect(find.byType(AuraTile), findsOneWidget);
    });

    testWidgets('shows empty state when no tools available', (tester) async {
      await _pumpAndInit(tester, _buildSubject(_dataOverride([])));
      await _showDialog(tester);

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows search empty state when query has no matches', (
      tester,
    ) async {
      await _pumpAndInit(tester, _buildSubject(_dataOverride()));
      await _showDialog(tester);

      await tester.enterText(find.byType(AuraInput), 'not-found');
      await tester.pump();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('adds selected tool and closes dialog', (tester) async {
      final notifier = _RecordingWorkspaceToolsNotifier();

      await _pumpAndInit(
        tester,
        _buildSubject([
          ..._dataOverride(),
          workspaceToolsProvider(_wsId).overrideWith(() => notifier),
        ]),
      );
      await _showDialog(tester);

      await tester.tap(find.byType(AuraTile));
      await tester.pump();
      await tester.pump();

      expect(notifier.hasAdded(UserToolType.calculator), isTrue);
      expect(find.byType(AddToolModal), findsNothing);
    });

    testWidgets('shows error widget when error', (tester) async {
      await _pumpAndInit(
        tester,
        _buildSubject([
          availableToolsToAddProvider.overrideWith(
            (ref, arg) => Future.error('test error'),
          ),
        ]),
      );
      await _showDialog(tester);
      final _ = await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
    });
  });
}
