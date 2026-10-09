import 'package:auravibes_ui/src/atoms/aura_typing_indicator.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTypingIndicator', () {
    testWidgets(
      'renders sizes, colors, semantics, visibility, and animations',
      (tester) async {
        await tester.pumpWidget(
          AuraThemeScope(
            theme: .light,
            child: MaterialApp(
              home: const Scaffold(
                body: Column(
                  mainAxisSize: .min,
                  children: [
                    AuraTypingIndicator(key: ValueKey('default')),
                    AuraTypingIndicator(
                      key: ValueKey('hidden'),
                      showContainer: false,
                      semanticLabel: null,
                    ),
                    AuraTypingIndicator(
                      key: ValueKey('small'),
                      size: .small,
                      semanticLabel: null,
                    ),
                    AuraTypingIndicator(
                      key: ValueKey('large'),
                      size: .large,
                      semanticLabel: null,
                    ),
                    AuraTypingIndicator(
                      key: ValueKey('custom-color'),
                      color: Colors.red,
                      semanticLabel: null,
                    ),
                    AuraTypingIndicator(
                      key: ValueKey('custom-duration'),
                      animationDuration: .new(milliseconds: 1000),
                      semanticLabel: null,
                    ),
                  ],
                ),
              ),
              theme: .light(),
            ),
          ),
        );

        Finder within(String key, Finder matching) => find.descendant(
          of: find.byKey(ValueKey<String>(key)),
          matching: matching,
        );
        List<Container> dotContainers(String key) => tester
            .widgetList<Container>(within(key, find.byType(Container)))
            .where((container) {
              final decoration = container.decoration;

              return decoration is BoxDecoration &&
                  decoration.shape == BoxShape.circle;
            })
            .toList();

        expect(
          within('default', find.byType(Container)),
          findsAtLeastNWidgets(3),
        );
        expect(within('hidden', find.byType(Align)), findsNothing);
        expect(within('hidden', find.byType(Row)), findsOneWidget);
        for (final key in ['default', 'small', 'large']) {
          expect(within(key, find.byType(Row)), findsOneWidget);
        }

        final customColorDots = dotContainers('custom-color');
        expect(customColorDots, hasLength(3));
        for (final container in customColorDots) {
          final decoration =
              (container.decoration ??
                      fail('Expected container.decoration to be non-null'))
                  as BoxDecoration;
          expect(decoration.color, Colors.red);
        }

        final defaultColorDots = dotContainers('default');
        expect(defaultColorDots, hasLength(3));
        for (final container in defaultColorDots) {
          final decoration =
              (container.decoration ??
                      fail('Expected container.decoration to be non-null'))
                  as BoxDecoration;
          expect(decoration.color, DesignColors.neutral700);
        }

        expect(find.bySemanticsLabel('AI is typing'), findsOneWidget);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          within('default', find.byType(AnimatedBuilder)),
          findsNWidgets(3),
        );
        expect(
          within('custom-duration', find.byType(AnimatedBuilder)),
          findsNWidgets(3),
        );
      },
    );

    group('AuraTypingIndicatorSize enum', () {
      test('has all expected values', () {
        expect(AuraTypingIndicatorSize.values, hasLength(3));
        expect(
          AuraTypingIndicatorSize.values,
          contains(AuraTypingIndicatorSize.small),
        );
        expect(
          AuraTypingIndicatorSize.values,
          contains(AuraTypingIndicatorSize.medium),
        );
        expect(
          AuraTypingIndicatorSize.values,
          contains(AuraTypingIndicatorSize.large),
        );
      });
    });
  });
}
