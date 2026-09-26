import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
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
}
