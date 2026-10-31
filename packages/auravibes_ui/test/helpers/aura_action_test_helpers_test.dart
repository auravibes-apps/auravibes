import 'dart:ui' show Tristate;

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aura_action_test_helpers.dart';

void main() {
  group('Aura action test helpers', () {
    testWidgets('finds and activates a directly identified action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      var presses = 0;

      await _pump(
        tester,
        AuraButton(
          onPressed: () => presses++,
          child: const Text('Save'),
          identifier: 'save-action',
          semanticLabel: 'Save changes',
        ),
      );

      final action = findAuraAction(semanticsIdentifier: 'save-action');
      expect(action, findsOneWidget);
      final data = tester.getSemantics(action).getSemanticsData();
      expect(data.label, 'Save changes');
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.hasAction(.tap), isTrue);
      expect(find.text('Save'), findsOneWidget);

      await tapAuraAction(tester, semanticsIdentifier: 'save-action');
      expect(presses, 1);
    });

    testWidgets('matches an outer key to its nested semantic action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      var presses = 0;
      const actionKey = ValueKey<String>('save-control');

      await _pump(
        tester,
        KeyedSubtree(
          key: actionKey,
          child: AuraButton(
            onPressed: () => presses++,
            child: const Text('Save'),
            identifier: 'nested-save-action',
            semanticLabel: 'Save changes',
          ),
        ),
      );

      final action = findAuraAction(
        key: actionKey,
        semanticsIdentifier: 'nested-save-action',
      );
      expect(action, findsOneWidget);
      await tapAuraAction(
        tester,
        key: actionKey,
        semanticsIdentifier: 'nested-save-action',
      );
      expect(presses, 1);
    });

    testWidgets('rejects duplicate semantic identifiers as ambiguous', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await _pump(
        tester,
        const Column(
          mainAxisSize: .min,
          children: [
            AuraButton(
              onPressed: _noop,
              child: Text('First save'),
              identifier: 'duplicate-action',
              semanticLabel: 'First save',
            ),
            AuraButton(
              onPressed: _noop,
              child: Text('Second save'),
              identifier: 'duplicate-action',
              semanticLabel: 'Second save',
            ),
          ],
        ),
      );

      expect(
        () => findAuraAction(semanticsIdentifier: 'duplicate-action'),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            contains('ambiguous'),
          ),
        ),
      );
    });

    testWidgets('reports a missing action and suggests revealing hidden UI', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await _pump(tester, const SizedBox.shrink());

      expect(
        () => findAuraAction(
          semanticsIdentifier: 'missing-action',
          description: 'Save action',
        ),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            allOf(contains('Save action'), contains('hidden or offstage')),
          ),
        ),
      );
    });

    testWidgets('rejects disabled actions with a clear diagnostic', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await _pump(
        tester,
        const AuraButton(
          onPressed: _noop,
          child: Text('Save'),
          disabled: true,
          identifier: 'disabled-action',
          semanticLabel: 'Save changes',
        ),
      );

      await expectLater(
        tapAuraAction(tester, semanticsIdentifier: 'disabled-action'),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            contains('disabled'),
          ),
        ),
      );
    });

    testWidgets('reports a hidden menu item until its menu is opened', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
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

      expect(
        () => findAuraAction(semanticsIdentifier: 'rename-action'),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            contains('hidden or offstage'),
          ),
        ),
      );

      await tapAuraAction(tester, semanticsIdentifier: 'more-actions');
      await tester.pump(const Duration(milliseconds: 500));
      await tapAuraAction(tester, semanticsIdentifier: 'rename-action');
      await tester.pump(const Duration(milliseconds: 500));
      expect(itemPresses, 1);
    });

    testWidgets('rejects offstage targets before attempting activation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      const actionKey = ValueKey<String>('offstage-action');

      await _pump(
        tester,
        const Offstage(
          child: AuraButton(
            key: actionKey,
            onPressed: _noop,
            child: Text('Hidden save'),
            identifier: 'offstage-action',
          ),
        ),
      );

      await expectLater(
        tapAuraAction(tester, key: actionKey),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            anyOf(contains('offstage'), contains('hit-testable')),
          ),
        ),
      );
    });
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

void _noop() => throw StateError('Unexpected test action.');
