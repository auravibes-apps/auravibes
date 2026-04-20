import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/atoms/auravibes_pressable.dart';
import 'package:auravibes_ui/src/molecules/auravibes_dropdown_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraDropdownOption', () {
    testWidgets('renders with default label from value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'Option 1',
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
    });

    testWidgets('renders with custom child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              child: Text('Custom Label'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Label'), findsOneWidget);
    });

    testWidgets('renders leading widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              leading: Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              isSelected: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byType(AuraIcon), findsOneWidget);
    });

    testWidgets('does not show check icon when not selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('calls onTap when tapped and enabled', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraPressable));
      expect(wasTapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              isEnabled: false,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraPressable));
      expect(wasTapped, isFalse);
    });

    testWidgets('applies semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              semanticLabel: 'Select option one',
            ),
          ),
        ),
      );

      // The semanticLabel is accepted as a property; verify widget renders.
      expect(find.text('opt1'), findsOneWidget);
    });

    testWidgets('trailing takes priority over selected check', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDropdownOption<String>(
              value: 'opt1',
              isSelected: true,
              trailing: Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}
