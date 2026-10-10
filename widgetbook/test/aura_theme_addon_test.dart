import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/main.dart' show WidgetbookConfig;

void main() {
  testWidgets('hue and scope radius addons share one AuraThemeScope', (
    tester,
  ) async {
    final addons = WidgetbookConfig.create().addons ?? const [];
    final hueAddon =
        addons.singleWhere((addon) => addon.name == 'Hue') as Addon<int>;
    expect(hueAddon.fields.single.name, 'degrees');

    final radiusAddon = addons.singleWhere(
      (addon) => addon.name == 'Global border radius level',
    ) as Addon<AuraBorderRadius>;
    expect(radiusAddon.fields.single.name, 'level');

    var level = AuraBorderRadius.sm;
    var hue = 180;
    var resolvedRadius = 0.0;
    var resolvedTheme = AuraTheme.light;
    var resolvedMaterialPrimary = AuraTheme.light.colors.primary;

    material_ui.Widget buildWidget() => material_ui.MaterialApp(
      home: material_ui.Builder(
        builder: (context) => WidgetbookConfig.applyTheme(
          context,
          .light(),
          material_ui.Builder(
            builder: (themeContext) => hueAddon.apply(
              themeContext,
              material_ui.Builder(
                builder: (hueContext) => radiusAddon.apply(
                  hueContext,
                  material_ui.Builder(
                    builder: (context) {
                      resolvedTheme =
                          AuraThemeScope.maybeOf(context) ?? AuraTheme.light;
                      resolvedRadius = resolvedTheme.fromBorderRadius(.lg);
                      resolvedMaterialPrimary = material_ui.Theme.of(context)
                          .colorScheme
                          .primary;

                      return const material_ui.SizedBox.shrink();
                    },
                  ),
                  level,
                ),
              ),
              hue,
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildWidget());
    expect(resolvedRadius, 2);
    expect(resolvedTheme.globalBorderRadiusLevel, AuraBorderRadius.sm);
    final expectedColors = AuraComputedColorScheme(
      primaryHue: hue.toDouble(),
      brightness: .light,
    );
    expect(resolvedTheme.colors.primary, expectedColors.primary);
    expect(resolvedMaterialPrimary, expectedColors.primary);
    expect(find.byType(AuraThemeScope), findsOneWidget);

    level = AuraBorderRadius.xl;
    await tester.pumpWidget(buildWidget());
    await tester.pump(const Duration(milliseconds: 100));
    expect(resolvedRadius, closeTo(9, 0.1));

    await tester.pump(const Duration(milliseconds: 100));
    expect(resolvedRadius, 16);
    expect(resolvedTheme.borderRadius, AuraTheme.light.borderRadius);
    expect(find.byType(AuraThemeScope), findsOneWidget);

    hue = 240;
    await tester.pumpWidget(buildWidget());
    await tester.pump(const Duration(milliseconds: 200));
    final updatedColors = AuraComputedColorScheme(
      primaryHue: hue.toDouble(),
      brightness: .light,
    );
    expect(resolvedTheme.colors.primary, updatedColors.primary);
    expect(resolvedMaterialPrimary, updatedColors.primary);
    expect(resolvedRadius, 16);
    expect(find.byType(AuraThemeScope), findsOneWidget);
  });
}
