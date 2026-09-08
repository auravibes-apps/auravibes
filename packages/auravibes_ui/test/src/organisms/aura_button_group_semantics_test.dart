import 'package:auravibes_ui/src/organisms/aura_button_group.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('merges labeled item semantics and keeps a 48px hit target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AuraButtonGroup<String>.action(
            items: const [
              AuraButtonGroupItem(
                value: 'save',
                child: Text('Save'),
                semanticLabel: 'Save changes',
              ),
            ],
            onPressed: (_) {
              return;
            },
          ),
        ),
      );

      final node = tester
          .getSemantics(find.bySemanticsLabel('Save changes'))
          .getSemanticsData();

      expect(node.hasAction(SemanticsAction.tap), isTrue);
      expect(node.rect.width, greaterThanOrEqualTo(48));
      expect(node.rect.height, greaterThanOrEqualTo(48));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('uses readable foreground colors after selection changes', (
    tester,
  ) async {
    String? selected = 'save';

    await tester.pumpWidget(
      Theme(
        data: ThemeData.light().copyWith(extensions: [AuraTheme.light]),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) => AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'save', child: Text('Save')),
                AuraButtonGroupItem(value: 'open', child: Text('Open')),
              ],
              selectedValue: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    Color textColor(String label) {
      final style = tester
          .renderObject<RenderParagraph>(find.text(label))
          .text
          .style;

      return style?.color ??
          (throw StateError('Missing text color for $label'));
    }

    expect(textColor('Save'), AuraTheme.light.colors.onPrimary);
    expect(textColor('Open'), AuraTheme.light.colors.primary);

    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(textColor('Save'), AuraTheme.light.colors.primary);
    expect(textColor('Open'), AuraTheme.light.colors.onPrimary);

    final layers = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    Color layerColor(AnimatedContainer layer) {
      final decoration = layer.decoration;
      if (decoration is! BoxDecoration) {
        throw StateError('Missing button layer color');
      }
      final color = decoration.color;
      if (color == null) throw StateError('Missing button layer color');

      return color;
    }

    expect(
      layerColor(layers.firstOrNull ?? (throw StateError('Missing layer'))),
      Colors.transparent,
    );
    expect(layerColor(layers.elementAt(1)), AuraTheme.light.colors.primary);
  });
}
