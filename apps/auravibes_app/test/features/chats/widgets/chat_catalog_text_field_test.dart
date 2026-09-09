import 'package:auravibes_app/features/chats/widgets/chat_catalog_text_field.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    home: Scaffold(body: child),
    theme: .new(extensions: [AuraTheme.light]),
  );

  testWidgets('model updates replace and clear text without user callbacks', (
    tester,
  ) async {
    final edits = <String>[];
    for (final value in <String?>['Initial', 'Replacement', null]) {
      await tester.pumpWidget(
        app(
          ChatCatalogTextField(
            onChanged: edits.add,
            value: value,
            label: 'Name',
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, value ?? '');
      expect(
        tester.widget<AuraInput>(find.byType(AuraInput)).initialValue,
        isNull,
      );
    }
    expect(edits, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'user edits retain focus, caret and composing range on model echo',
    (tester) async {
      var value = 'Initial';
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => ChatCatalogTextField(
              onChanged: (next) => setState(() => value = next),
              value: value,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      final original = tester.widget<TextField>(find.byType(TextField));
      const edit = TextEditingValue(
        text: 'Edited',
        selection: .collapsed(offset: 3),
        composing: .new(start: 1, end: 4),
      );
      tester.testTextInput.updateEditingValue(edit);
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(value, 'Edited');
      expect(field.controller, same(original.controller));
      expect(field.controller?.value, edit);
      expect(field.focusNode, same(original.focusNode));
      expect(field.focusNode?.hasFocus, isTrue);
    },
  );

  testWidgets('variants preserve mapping without numeric filtering', (
    tester,
  ) async {
    for (final variant in [null, 'multiline', 'number', 'password']) {
      String? edited;
      await tester.pumpWidget(
        app(
          ChatCatalogTextField(
            onChanged: (next) => edited = next,
            label: 'Value',
            variant: variant,
          ),
        ),
      );
      final input = tester.widget<AuraInput>(find.byType(AuraInput));
      expect(input.maxLines, variant == 'multiline' ? 4 : 1);
      expect(input.obscureText, variant == 'password');
      expect(
        input.keyboardType,
        variant == 'number' ? TextInputType.number : null,
      );
      expect(input.inputFormatters, isNull);
      expect(input.semanticLabel, 'Value');
      await tester.enterText(find.byType(TextField), 'letters');
      expect(edited, 'letters');
    }
  });
}
