import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('auraTheme falls back to light without a scope', (tester) async {
    var theme = AuraTheme.dark;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          theme = context.auraTheme;

          return const SizedBox.shrink();
        },
      ),
    );

    expect(theme, same(AuraTheme.light));
  });

  testWidgets('scope provides theme and rebuilds dependents', (tester) async {
    final firstTheme = AuraTheme.light;
    final secondTheme = AuraTheme.dark;
    var builds = 0;
    var observedTheme = firstTheme;

    final child = Builder(
      builder: (context) {
        builds++;
        observedTheme = context.auraTheme;

        return const SizedBox.shrink();
      },
    );
    Widget buildApp(AuraTheme theme) =>
        AuraThemeScope(theme: theme, child: child);

    await tester.pumpWidget(buildApp(firstTheme));
    expect(observedTheme, same(firstTheme));
    expect(builds, 1);

    await tester.pumpWidget(buildApp(firstTheme));
    expect(builds, 1);

    await tester.pumpWidget(buildApp(secondTheme));
    expect(observedTheme, same(secondTheme));
    expect(builds, 2);
  });

  testWidgets('interaction targets update with the inherited theme', (
    tester,
  ) async {
    const iconButtonKey = ValueKey('icon-button-target');
    const linkKey = ValueKey('link-target');
    final child = MaterialApp(
      home: Scaffold(
        body: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraIconButton(
              key: iconButtonKey,
              icon: Icons.close,
              onPressed: _noop,
            ),
            AuraLink(key: linkKey, label: 'Open', onPressed: _noop),
          ],
        ),
      ),
    );

    Widget buildApp(double minimumTargetSize) => AuraThemeScope(
      theme: AuraTheme.light.copyWith(
        interactionSizes: AuraInteractionSizeScale(
          minimumTargetSize: minimumTargetSize,
        ),
      ),
      child: child,
    );

    await tester.pumpWidget(buildApp(48));
    expect(tester.getSize(find.byKey(iconButtonKey)), const Size(48, 48));
    expect(tester.getSize(find.byKey(linkKey)).height, 48);

    await tester.pumpWidget(buildApp(64));
    expect(tester.getSize(find.byKey(iconButtonKey)), const Size(64, 64));
    expect(tester.getSize(find.byKey(linkKey)).height, 64);
  });
}

void _noop() {}
