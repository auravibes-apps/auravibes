import 'dart:async';

import 'package:auravibes_app/features/chats/widgets/conversation_task_brief_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> openDialog(
    BuildContext context,
    Completer<ConversationTaskBriefEditResult?> result, {
    String? taskBrief,
  }) async {
    result.complete(
      await ConversationTaskBriefDialog.show(context, taskBrief: taskBrief),
    );
  }

  Widget buildSubject(
    Completer<ConversationTaskBriefEditResult?> result, {
    String? taskBrief,
  }) => EasyLocalization(
    child: Builder(
      builder: (context) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  unawaited(openDialog(context, result, taskBrief: taskBrief)),
              child: const Text('Open'),
            ),
          ),
        ),
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );

  Future<void> pumpSubject(
    WidgetTester tester,
    Completer<ConversationTaskBriefEditResult?> result, {
    String? taskBrief,
  }) async {
    await tester.runAsync(
      () => tester.pumpWidget(buildSubject(result, taskBrief: taskBrief)),
    );
    final _ = await tester.pumpAndSettle();
  }

  for (final initial in [null, 'Existing saved brief']) {
    testWidgets('whitespace-only draft cannot save or clear initial=$initial', (
      tester,
    ) async {
      final result = Completer<ConversationTaskBriefEditResult?>();
      await pumpSubject(tester, result, taskBrief: initial);
      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), ' \n\t ');
      final _ = await tester.pumpAndSettle();

      final save = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Save'),
      );
      expect(save.onPressed, isNull);
      expect(result.isCompleted, isFalse);
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();
      expect(await result.future, isNull);
    });
  }

  testWidgets('creates an exact multiline brief from an empty draft', (
    tester,
  ) async {
    final result = Completer<ConversationTaskBriefEditResult?>();
    await pumpSubject(tester, result);
    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Clear brief'), findsNothing);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
          .onPressed,
      isNull,
    );
    const brief = '  Objetivo 🎯\nKeep the deadline.  ';
    await tester.enterText(find.byType(TextField), brief);
    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();
    expect(await result.future, (clear: false, value: brief));
  });

  testWidgets('dismiss leaves the saved brief untouched', (tester) async {
    final result = Completer<ConversationTaskBriefEditResult?>();
    await pumpSubject(tester, result, taskBrief: 'Existing objective.');
    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    final _ = await tester.pumpAndSettle();
    expect(await result.future, isNull);
  });

  testWidgets('prefills and preserves the exact user-edited text', (
    tester,
  ) async {
    final result = Completer<ConversationTaskBriefEditResult?>();
    const brief = '  Keep the deadline in view.\nReview open tasks.  ';
    await pumpSubject(tester, result, taskBrief: brief);

    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, brief);

    await tester.enterText(find.byType(TextField), '  New objective.  ');
    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();

    expect(await result.future, (clear: false, value: '  New objective.  '));
  });

  testWidgets('clears the saved brief only when the user selects Clear', (
    tester,
  ) async {
    final result = Completer<ConversationTaskBriefEditResult?>();
    await pumpSubject(tester, result, taskBrief: 'Existing objective.');

    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Clear brief'));
    final _ = await tester.pumpAndSettle();

    expect(await result.future, (clear: true, value: null));
  });

  testWidgets('cancel leaves the saved brief untouched', (tester) async {
    final result = Completer<ConversationTaskBriefEditResult?>();
    await pumpSubject(tester, result, taskBrief: 'Existing objective.');

    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();

    expect(await result.future, isNull);
  });
}
