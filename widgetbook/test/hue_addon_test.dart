import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart' show test;
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/main.dart';

void main() {
  test('hue addon exposes the full circle in one-degree steps', () {
    final addon = AuraHueAddon();
    final field = addon.field as IntSliderField;
    expect(field.min, 0);
    expect(field.max, 360);
    expect(field.divisions, 360);
    expect(field.initialValue, addon.initialValue);
  });

  for (final brightness in Brightness.values) {
    for (final hue in [0, 186, 300, 360]) {
      testWidgets('hue $hue updates ${brightness.name} theme', (tester) async {
        final addon = AuraHueAddon();
        final base = ThemeData(brightness: brightness);
        AuraColorScheme? actual;
        ColorScheme? material;
        Color? canvas;
        await tester.pumpWidget(
          Builder(
            builder: (context) => WidgetbookConfig.applyApp(
              context,
              Builder(
                builder: (context) => WidgetbookConfig.applyTheme(
                  context,
                  base,
                  Builder(
                    builder: (context) => addon.apply(
                      context,
                      Builder(
                        builder: (context) {
                          actual = context.auraColors;
                          material = Theme.of(context).colorScheme;
                          canvas = Theme.of(context).scaffoldBackgroundColor;

                          return const SizedBox.shrink();
                        },
                      ),
                      hue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final expected = AuraComputedColorScheme(
          primaryHue: hue.toDouble(),
          brightness: brightness == Brightness.light ? .light : .dark,
        );
        expect(actual?.primary, expected.primary);
        expect(actual?.fillFor(.primary), expected.fillFor(.primary));
        expect(actual?.background, expected.background);
        expect(material?.primary, expected.primary);
        expect(material?.onErrorContainer, expected.onError);
        expect(material?.brightness, brightness);
        expect(canvas, expected.background);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
