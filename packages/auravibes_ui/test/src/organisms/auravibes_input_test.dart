import 'package:auravibes_ui/src/organisms/aura_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraInput', () {
    testWidgets('renders placeholder, hint, and icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              placeholder: Text('Enter text'),
              hint: Text('This is helper text'),
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.clear),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);
      expect(find.text('This is helper text'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('displays initial value and obscures it when requested', (
      tester,
    ) async {
      const initialValue = 'password';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(initialValue: initialValue, obscureText: true),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.initialValue, initialValue);
      expect(
        tester.widget<AuraInput>(find.byType(AuraInput)).obscureText,
        isTrue,
      );
    });

    testWidgets('calls onChanged and onSubmitted', (tester) async {
      String? changedValue;
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraInput(
              onChanged: (value) => changedValue = value,
              onSubmitted: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Submitted text');
      expect(changedValue, 'Submitted text');
      await tester.testTextInput.receiveAction(.done);
      expect(submittedValue, 'Submitted text');
    });

    testWidgets('next action focuses the following AuraInput', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AuraInput(textInputAction: .next),
                AuraInput(textInputAction: .done),
              ],
            ),
          ),
        ),
      );

      final fields = find.byType(EditableText);
      final nextFieldFocus = tester
          .widget<EditableText>(fields.at(1))
          .focusNode;
      await tester.tap(fields.first);
      await tester.pump();
      await tester.testTextInput.receiveAction(.next);
      final _ = await tester.pumpAndSettle();

      expect(nextFieldFocus.hasFocus, isTrue);
    });

    testWidgets('enforces the configured maximum length', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AuraInput(maxLength: 5))),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, 5);

      await tester.enterText(find.byType(TextFormField), '123456789');

      expect(find.text('12345'), findsOneWidget);
      expect(find.text('123456789'), findsNothing);
    });

    testWidgets('prioritizes error text over helper text', (tester) async {
      const helperText = 'Helper text';
      const errorText = 'Error text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(hint: Text(helperText), error: Text(errorText)),
          ),
        ),
      );

      expect(find.text(errorText), findsOneWidget);
      expect(find.text(helperText), findsNothing);
    });

    testWidgets('disables input and respects read-only state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [AuraInput(enabled: false), AuraInput(readOnly: true)],
            ),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      expect(tester.widget<TextFormField>(fields.at(0)).enabled, isFalse);

      await tester.enterText(fields.at(1), 'test');
      expect(find.text('test'), findsNothing);
    });

    testWidgets('displays header above field and footer below', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(header: Text('Header'), footer: Text('Footer')),
          ),
        ),
      );

      final headerTop = tester.getTopLeft(find.text('Header')).dy;
      final fieldTop = tester.getTopLeft(find.byType(TextFormField)).dy;
      final footerTop = tester.getTopLeft(find.text('Footer')).dy;

      expect(headerTop, lessThan(fieldTop));
      expect(footerTop, greaterThan(fieldTop));
    });

    test('has all expected size and state enum values', () {
      expect(AuraInputSize.values, hasLength(3));
      expect(AuraInputSize.values, contains(AuraInputSize.small));
      expect(AuraInputSize.values, contains(AuraInputSize.medium));
      expect(AuraInputSize.values, contains(AuraInputSize.large));
      expect(AuraInputState.values, hasLength(4));
      expect(AuraInputState.values, contains(AuraInputState.normal));
      expect(AuraInputState.values, contains(AuraInputState.success));
      expect(AuraInputState.values, contains(AuraInputState.warning));
      expect(AuraInputState.values, contains(AuraInputState.error));
    });
  });
}
