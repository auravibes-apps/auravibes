import 'dart:ui' show PointerDeviceKind;

import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraPressable', () {
    testWidgets('uses an 8 percent hover state layer', (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );

      await tester.pumpWidget(_host());

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byType(AuraPressable)));
      final _ = await tester.pumpAndSettle();

      expect(_stateLayerColor(tester).a, closeTo(0.08, 0.001));

      await gesture.removePointer();
    });

    testWidgets('uses a 16 percent pressed state layer', (tester) async {
      await tester.pumpWidget(_host());

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AuraPressable)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(_stateLayerColor(tester).a, closeTo(0.16, 0.001));

      await gesture.up();
    });
  });
}

Color _stateLayerColor(WidgetTester tester) {
  final layer = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );

  // AnimatedContainer's color shorthand is normalized into decoration.
  final decoration = layer.decoration;
  if (decoration is BoxDecoration) {
    final color = decoration.color;
    if (color != null) return color;
  }

  fail('Expected the state layer to have a color.');
}

Widget _host() {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 80,
        child: AuraPressable(
          child: const Text('Press'),
          color: AuraTheme.light.colors.primary,
          onPressed: _noop,
        ),
      ),
    ),
    theme: ThemeData(extensions: [AuraTheme.light]),
  );
}

void _noop() {
  final _ = Object();
}
