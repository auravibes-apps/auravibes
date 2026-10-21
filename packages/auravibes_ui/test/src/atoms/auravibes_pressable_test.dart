import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraPressable', () {
    for (final activation in <({String name, LogicalKeyboardKey key})>[
      (name: 'Enter', key: .enter),
      (name: 'NumpadEnter', key: .numpadEnter),
      (name: 'Space', key: .space),
    ]) {
      testWidgets('activates with ${activation.name}', (tester) async {
        var pressCount = 0;
        await tester.pumpWidget(_host(onPressed: () => pressCount++));

        expect(await tester.sendKeyEvent(.tab), isTrue);
        await tester.pump();
        expect(await tester.sendKeyEvent(activation.key), isTrue);
        await tester.pump();

        expect(pressCount, 1);
      });
    }

    testWidgets('uses hover and pressed state layer opacities', (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy = .alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );

      await tester.pumpWidget(_host());

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byType(AuraPressable)));
      final _ = await tester.pumpAndSettle();

      expect(_stateLayerColor(tester).a, closeTo(0.08, 0.001));

      await gesture.removePointer();
      await tester.pump();

      final pressGesture = await tester.startGesture(
        tester.getCenter(find.byType(AuraPressable)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(_stateLayerColor(tester).a, closeTo(0.16, 0.001));

      await pressGesture.up();
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

Widget _host({VoidCallback? onPressed}) {
  return AuraThemeScope(
    theme: .light,
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 80,
          child: AuraPressable(
            child: const Text('Press'),
            color: AuraTheme.light.colors.primary,
            onPressed: onPressed ?? _noop,
          ),
        ),
      ),
      theme: .new(),
    ),
  );
}

void _noop() {
  final _ = Object();
}
