import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preserves inherited SDK theme and provides Material surface', (
    tester,
  ) async {
    final hostTheme = ThemeData(
      colorScheme: .fromSeed(seedColor: Colors.purple),
      textTheme: const .new(headlineLarge: .new(fontSize: 37)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuraSdkMaterialSurface(
          child: Builder(
            builder: (context) => Column(
              children: [
                Text(
                  'theme',
                  key: const ValueKey('theme-text'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Icon(
                  Icons.ac_unit,
                  key: const ValueKey('theme-icon'),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        theme: hostTheme,
      ),
    );

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('theme-text')))
          .style
          ?.fontSize,
      37,
    );
    expect(
      tester.widget<Icon>(find.byKey(const ValueKey('theme-icon'))).color,
      hostTheme.colorScheme.primary,
    );
    expect(find.byType(Material), findsOneWidget);
  });
}
