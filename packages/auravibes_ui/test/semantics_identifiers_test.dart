import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stable semantics identifiers', () {
    testWidgets('AuraPressable exposes one keyed semantics node', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var presses = 0;

      await _pump(
        tester,
        AuraPressable(
          child: const Text('Save'),
          color: AuraTheme.light.colors.primary,
          key: const ValueKey<String>('pressable-widget'),
          onPressed: () => presses++,
          identifier: 'pressable-save',
          semanticLabel: 'Save changes',
        ),
      );

      _expectIdentifier('pressable-save');
      expect(_keyFinder('pressable-widget'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Save changes')), findsOneWidget);

      await tester.tap(_keyFinder('pressable-save'));
      expect(presses, 1);
      semantics.dispose();
    });

    testWidgets('omitted identifiers are not derived from labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await _pump(
        tester,
        const AuraButton(
          onPressed: _noop,
          child: Text('Save'),
          semanticLabel: 'Save changes',
        ),
      );

      expect(_keyFinder('Save changes'), findsNothing);
      expect(find.bySemanticsIdentifier('Save changes'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Save changes')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('core controls expose identifiers on hittable nodes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var buttonPresses = 0;
      var tilePresses = 0;
      var iconPresses = 0;
      var optionPresses = 0;

      await _pump(
        tester,
        Column(
          mainAxisSize: .min,
          children: [
            AuraButton(
              onPressed: () => buttonPresses++,
              child: const Text('Save'),
              identifier: 'button-save',
              semanticLabel: 'Save changes',
            ),
            AuraTile(
              child: const Text('Workspace'),
              onTap: () => tilePresses++,
              identifier: 'tile-workspace',
              semanticLabel: 'Open workspace',
            ),
            AuraIconButton(
              icon: Icons.settings,
              onPressed: () => iconPresses++,
              identifier: 'icon-settings',
              semanticLabel: 'Settings',
            ),
            const AuraInput(identifier: 'input-name', semanticLabel: 'Name'),
            AuraDropdownOption<String>(
              value: 'one',
              onTap: () => optionPresses++,
              identifier: 'standalone-option-one',
              semanticLabel: 'Option one',
            ),
          ],
        ),
      );

      [
        'button-save',
        'tile-workspace',
        'icon-settings',
        'input-name',
        'standalone-option-one',
      ].forEach(_expectIdentifier);

      await tester.tap(_keyFinder('button-save'));
      await tester.tap(_keyFinder('tile-workspace'));
      await tester.tap(_keyFinder('icon-settings'));
      await tester.tap(_keyFinder('standalone-option-one'));

      expect(buttonPresses, 1);
      expect(tilePresses, 1);
      expect(iconPresses, 1);
      expect(optionPresses, 1);
      semantics.dispose();
    });

    testWidgets('dropdown trigger and options expose identifiers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      String? selected;

      await _pump(
        tester,
        AuraDropdownSelector<String>(
          options: const [
            AuraDropdownOption<String>(
              value: 'one',
              child: Text('One'),
              identifier: 'workspace-one',
            ),
          ],
          onChanged: (value) => selected = value,
          identifier: 'workspace-selector',
          semanticLabel: 'Workspace',
        ),
      );

      _expectIdentifier('workspace-selector');
      await tester.tap(_keyFinder('workspace-selector'));
      await tester.pump();

      _expectIdentifier('workspace-one');
      await tester.tap(_keyFinder('workspace-one'));
      await tester.pump();
      expect(selected, 'one');
      semantics.dispose();
    });

    testWidgets('popup trigger and items expose identifiers', (tester) async {
      final semantics = tester.ensureSemantics();
      var itemPresses = 0;

      await _pump(
        tester,
        AuraPopupMenuButton(
          items: [
            AuraPopupMenuItem(
              title: const Text('Rename'),
              onTap: () => itemPresses++,
              identifier: 'rename-action',
            ),
          ],
          identifier: 'more-actions',
          tooltip: 'More actions',
        ),
      );

      _expectIdentifier('more-actions');
      await tester.tap(_keyFinder('more-actions'));
      await tester.pump();

      _expectIdentifier('rename-action');
      await tester.tap(_keyFinder('rename-action'));
      await tester.pump();
      expect(itemPresses, 1);
      semantics.dispose();
    });

    for (final presentation in AuraChoicePickerPresentation.values) {
      testWidgets('choice $presentation items expose identifiers', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        List<String>? selected;

        await _pump(
          tester,
          AuraChoicePicker<String>(
            options: const [
              AuraChoiceOption<String>(
                value: 'alpha',
                label: Text('Alpha'),
                identifier: 'choice-alpha',
                semanticLabel: 'Alpha choice',
              ),
            ],
            value: const [],
            onChanged: (value) => selected = value,
            presentation: presentation,
          ),
        );

        _expectIdentifier('choice-alpha');
        await tester.tap(_keyFinder('choice-alpha'));
        expect(selected, const ['alpha']);
        semantics.dispose();
      });
    }
  });
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    AuraThemeScope(
      theme: .light,
      child: MaterialApp(
        home: Scaffold(
          body: Portal(child: Center(child: child)),
        ),
      ),
    ),
  );
}

Finder _keyFinder(String identifier) =>
    find.byKey(ValueKey<String>(identifier));

void _expectIdentifier(String identifier) {
  final keyFinder = _keyFinder(identifier);
  final semanticsFinder = find.bySemanticsIdentifier(identifier);

  expect(keyFinder, findsOneWidget);
  expect(semanticsFinder, findsOneWidget);
  expect(keyFinder.evaluate().single, semanticsFinder.evaluate().single);
}

void _noop() {
  final _ = Object();
}
