import 'package:auravibes_ui/src/atoms/aura_corner_radius_scope.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('positive delta reduces radius and nested adjustments clamp', (
    tester,
  ) async {
    final theme = AuraTheme.light.copyWith(
      borderRadius: const AuraBorderRadiusScale(md: 10, xl: 20),
      globalBorderRadiusLevel: .full,
    );
    final resolvedRadii = <double>[];

    await tester.pumpWidget(
      AuraThemeScope(
        theme: theme,
        child: MaterialApp(
          home: AuraCornerRadiusScope.select(
            level: .xl,
            child: Builder(
              builder: (context) {
                resolvedRadii.add(AuraCornerRadiusScope.of(context));

                return AuraCornerRadiusScope.adjust(
                  delta: 4,
                  child: Builder(
                    builder: (context) {
                      resolvedRadii.add(AuraCornerRadiusScope.of(context));

                      return AuraCornerRadiusScope.adjust(
                        delta: 20,
                        child: Builder(
                          builder: (context) {
                            resolvedRadii.add(
                              AuraCornerRadiusScope.of(context),
                            );

                            return const SizedBox.shrink();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(resolvedRadii, [20, 16, 0]);
  });

  testWidgets('explicit, scoped, global, and fallback precedence', (
    tester,
  ) async {
    final theme = AuraTheme.light.copyWith(
      borderRadius: const AuraBorderRadiusScale(md: 10, xl: 24, full: 80),
      globalBorderRadiusLevel: .full,
    );
    final resolvedRadii = <double>[];

    await tester.pumpWidget(
      AuraThemeScope(
        theme: theme,
        child: MaterialApp(
          home: Column(
            children: [
              Builder(
                builder: (context) {
                  resolvedRadii
                    ..add(AuraCornerRadiusScope.resolve(context, fallback: .md))
                    ..add(
                      AuraCornerRadiusScope.resolve(
                        context,
                        explicit: .md,
                        fallback: .xl,
                      ),
                    );

                  return const SizedBox.shrink();
                },
              ),
              AuraCornerRadiusScope.select(
                level: .xl,
                child: Builder(
                  builder: (context) {
                    resolvedRadii
                      ..add(
                        AuraCornerRadiusScope.resolve(context, fallback: .md),
                      )
                      ..add(
                        AuraCornerRadiusScope.resolve(
                          context,
                          explicit: .md,
                          fallback: .xl,
                        ),
                      );

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(resolvedRadii, [80, 10, 24, 10]);
  });

  testWidgets('selected radius updates when theme scale changes', (
    tester,
  ) async {
    var theme = AuraTheme.light.copyWith(
      borderRadius: const AuraBorderRadiusScale(xl: 20),
    );
    var resolvedRadius = 0.0;

    Widget buildWidget() => AuraThemeScope(
      theme: theme,
      child: MaterialApp(
        home: AuraCornerRadiusScope.select(
          level: .xl,
          child: Builder(
            builder: (context) {
              resolvedRadius = AuraCornerRadiusScope.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildWidget());
    expect(resolvedRadius, 20);

    theme = theme.copyWith(borderRadius: const AuraBorderRadiusScale(xl: 32));
    await tester.pumpWidget(buildWidget());
    expect(resolvedRadius, 32);
  });

  testWidgets('adjust requires a parent radius scope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuraCornerRadiusScope.adjust(
          delta: 4,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isA<FlutterError>());
  });

  testWidgets('InheritedTheme.wrap carries radius into a new subtree', (
    tester,
  ) async {
    Widget? wrapped;
    double? capturedRadius;

    await tester.pumpWidget(
      MaterialApp(
        home: AuraCornerRadiusScope.select(
          level: .xl,
          child: Builder(
            builder: (context) {
              final scope = context
                  .dependOnInheritedWidgetOfExactType<AuraCornerRadiusScope>();
              if (scope == null) throw StateError('Expected radius scope.');
              wrapped = scope.wrap(
                context,
                Builder(
                  builder: (context) {
                    capturedRadius = AuraCornerRadiusScope.of(context);

                    return const SizedBox.shrink();
                  },
                ),
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(MaterialApp(home: wrapped));
    expect(capturedRadius, AuraTheme.light.fromBorderRadius(.xl));
  });
}
