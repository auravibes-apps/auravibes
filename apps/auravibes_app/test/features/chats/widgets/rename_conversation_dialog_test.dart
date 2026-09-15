import 'dart:async';

import 'package:auravibes_app/features/chats/widgets/rename_conversation_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> openDialog(
    BuildContext context,
    Completer<String?> result,
  ) async {
    result.complete(
      await RenameConversationDialog.show(context, title: 'Original'),
    );
  }

  Widget buildSubject(Completer<String?> result) => EasyLocalization(
    child: Builder(
      builder: (context) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(openDialog(context, result)),
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
    Completer<String?> result,
  ) async {
    await tester.runAsync(() => tester.pumpWidget(buildSubject(result)));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final _ = await tester.pumpAndSettle();
  }

  testWidgets('pre-fills and trims the saved title', (tester) async {
    final result = Completer<String?>();
    await pumpSubject(tester, result);

    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Original');

    await tester.enterText(find.byType(TextField), '  Renamed  ');
    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();

    expect(await result.future, 'Renamed');
  });

  testWidgets('cancel leaves the title unchanged', (tester) async {
    final result = Completer<String?>();
    await pumpSubject(tester, result);

    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();

    expect(await result.future, isNull);
  });

  testWidgets('disables save for a blank title', (tester) async {
    final result = Completer<String?>();
    await pumpSubject(tester, result);

    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final saveButton = find.ancestor(
      of: find.text('Save'),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(saveButton).onPressed, isNull);

    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();
    expect(await result.future, isNull);
  });
}
