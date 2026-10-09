import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/molecules/aura_dropdown_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and handles dropdown option states', (tester) async {
    var enabledWasTapped = false;
    var disabledWasTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisSize: .min,
            children: [
              const AuraDropdownOption<String>(
                value: 'Option 1',
                key: ValueKey('default'),
              ),
              const AuraDropdownOption<String>(
                value: 'opt1',
                key: ValueKey('custom'),
                child: Text('Custom Label'),
              ),
              const AuraDropdownOption<String>(
                value: 'opt1',
                key: ValueKey('leading'),
                leading: Icon(Icons.star),
              ),
              const AuraDropdownOption<String>(
                value: 'opt1',
                key: ValueKey('trailing'),
                trailing: Icon(Icons.arrow_forward),
              ),
              const AuraDropdownOption<String>(
                value: 'opt1',
                key: ValueKey('selected'),
                isSelected: true,
              ),
              const AuraDropdownOption<String>(
                value: 'opt1',
                key: ValueKey('unselected'),
              ),
              AuraDropdownOption<String>(
                value: 'opt1',
                key: const ValueKey('enabled'),
                onTap: () => enabledWasTapped = true,
              ),
              AuraDropdownOption<String>(
                value: 'opt1',
                key: const ValueKey('disabled'),
                isEnabled: false,
                onTap: () => disabledWasTapped = true,
              ),
              const AuraDropdownOption<String>(
                value: 'opt1',
                key: ValueKey('semantic'),
                semanticLabel: 'Select option one',
              ),
              const AuraDropdownOption<String>(
                value: 'opt1',
                key: ValueKey('priority'),
                trailing: Icon(Icons.star),
                isSelected: true,
              ),
            ],
          ),
        ),
      ),
    );

    Finder option(String key) => find.byKey(ValueKey<String>(key));
    Finder within(String key, Finder matching) =>
        find.descendant(of: option(key), matching: matching);

    expect(within('default', find.text('Option 1')), findsOneWidget);
    expect(within('custom', find.text('Custom Label')), findsOneWidget);
    expect(within('leading', find.byIcon(Icons.star)), findsOneWidget);
    expect(
      within('trailing', find.byIcon(Icons.arrow_forward)),
      findsOneWidget,
    );
    expect(within('selected', find.byIcon(Icons.check)), findsOneWidget);
    expect(within('selected', find.byType(AuraIcon)), findsOneWidget);
    expect(within('unselected', find.byIcon(Icons.check)), findsNothing);

    await tester.tap(within('enabled', find.byType(AuraPressable)));
    expect(enabledWasTapped, isTrue);
    await tester.tap(within('disabled', find.byType(AuraPressable)));
    expect(disabledWasTapped, isFalse);

    final semanticsFinder = within('semantic', find.byType(Semantics));
    expect(semanticsFinder, findsOneWidget);
    final semantics = tester.widget<Semantics>(semanticsFinder);
    expect(semantics.properties.label, 'Select option one');

    expect(within('priority', find.byIcon(Icons.star)), findsOneWidget);
    expect(within('priority', find.byIcon(Icons.check)), findsNothing);
  });
}
