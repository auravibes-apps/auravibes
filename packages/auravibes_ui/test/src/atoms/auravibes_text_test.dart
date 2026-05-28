// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraText', () {
    testWidgets('renders text correctly', (tester) async {
      const testText = 'Hello, World!';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraText(child: Text(testText)),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    group('AuraTextStyle enum', () {
      test('has all expected values', () {
        expect(AuraTextStyle.values, hasLength(13));
        expect(AuraTextStyle.values, contains(AuraTextStyle.heading1));
        expect(AuraTextStyle.values, contains(AuraTextStyle.heading2));
        expect(AuraTextStyle.values, contains(AuraTextStyle.heading3));
        expect(AuraTextStyle.values, contains(AuraTextStyle.heading4));
        expect(AuraTextStyle.values, contains(AuraTextStyle.heading5));
        expect(AuraTextStyle.values, contains(AuraTextStyle.heading6));
        expect(AuraTextStyle.values, contains(AuraTextStyle.bodyLarge));
        expect(AuraTextStyle.values, contains(AuraTextStyle.body));
        expect(AuraTextStyle.values, contains(AuraTextStyle.bodySmall));
        expect(AuraTextStyle.values, contains(AuraTextStyle.caption));
        expect(AuraTextStyle.values, contains(AuraTextStyle.overline));
        expect(AuraTextStyle.values, contains(AuraTextStyle.button));
        expect(AuraTextStyle.values, contains(AuraTextStyle.code));
      });
    });
  });
}
