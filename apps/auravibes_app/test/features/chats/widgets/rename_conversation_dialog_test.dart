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

  Widget buildSubject(
    Completer<String?> result, {
    FocusNode? sourceFocusNode,
  }) => EasyLocalization(
    child: Builder(
      builder: (context) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                if (sourceFocusNode != null)
                  TextField(focusNode: sourceFocusNode),
                TextButton(
                  onPressed: () => unawaited(openDialog(context, result)),
                  child: const Text('Open'),
                ),
              ],
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
    Completer<String?> result, {
    FocusNode? sourceFocusNode,
  }) async {
    await tester.runAsync(
      () => tester.pumpWidget(
        buildSubject(result, sourceFocusNode: sourceFocusNode),
      ),
    );
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

  testWidgets('closing the rename dialog does not restore source focus', (
    tester,
  ) async {
    final result = Completer<String?>();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpSubject(tester, result, sourceFocusNode: focusNode);
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Open'));
    final _ = await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isFalse);
    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isFalse);
    expect(await result.future, isNull);
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
