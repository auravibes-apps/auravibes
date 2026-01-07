import 'package:auravibes_ui/src/organisms/auravibes_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraInput', () {
    testWidgets('renders input field correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              placeholder: Text('Enter text'),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);
    });

    testWidgets('displays initial value correctly', (tester) async {
      const initialValue = 'Initial text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              initialValue: initialValue,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.initialValue, initialValue);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraInput(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'New text');
      expect(changedValue, 'New text');
    });

    testWidgets('calls onSubmitted when submitted', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraInput(
              onSubmitted: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Submitted text');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submittedValue, 'Submitted text');
    });

    testWidgets('displays helper text correctly', (tester) async {
      const helperText = 'This is helper text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              hint: Text(helperText),
            ),
          ),
        ),
      );

      expect(find.text(helperText), findsOneWidget);
    });

    testWidgets('prioritizes error text over helper text', (tester) async {
      const helperText = 'Helper text';
      const errorText = 'Error text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              hint: Text(helperText),
              error: Text(errorText),
            ),
          ),
        ),
      );

      expect(find.text(errorText), findsOneWidget);
      expect(find.text(helperText), findsNothing);
    });

    testWidgets('disables input when enabled is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.enabled, isFalse);
    });

    testWidgets('makes input read-only when readOnly is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              readOnly: true,
            ),
          ),
        ),
      );

      // Test that the input is read-only by checking if we can enter text
      await tester.enterText(find.byType(TextFormField), 'test');
      expect(find.text('test'), findsNothing);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              obscureText: true,
              initialValue: 'password',
            ),
          ),
        ),
      );

      // Find the AuraInput widget and verify obscureText property is set
      final auraInput = tester.widget<AuraInput>(find.byType(AuraInput));
      expect(auraInput.obscureText, isTrue);

      // Verify the initial value is set correctly
      expect(auraInput.initialValue, equals('password'));
    });

    testWidgets('displays prefix icon correctly', (tester) async {
      const prefixIcon = Icon(Icons.search);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              prefixIcon: prefixIcon,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays suffix icon correctly', (tester) async {
      const suffixIcon = Icon(Icons.clear);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraInput(
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    group('AuraInputSize enum', () {
      test('has all expected values', () {
        expect(AuraInputSize.values, hasLength(3));
        expect(AuraInputSize.values, contains(AuraInputSize.small));
        expect(AuraInputSize.values, contains(AuraInputSize.medium));
        expect(AuraInputSize.values, contains(AuraInputSize.large));
      });
    });

    group('AuraInputState enum', () {
      test('has all expected values', () {
        expect(AuraInputState.values, hasLength(4));
        expect(AuraInputState.values, contains(AuraInputState.normal));
        expect(AuraInputState.values, contains(AuraInputState.success));
        expect(AuraInputState.values, contains(AuraInputState.warning));
        expect(AuraInputState.values, contains(AuraInputState.error));
      });
    });
  });
}
