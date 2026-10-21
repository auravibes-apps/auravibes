import 'package:auravibes_ui/src/atoms/aura_corner_radius_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_icon_button.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows hover feedback, keeps visible focus, and no pressed fill',
    (tester) async {
      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: const MaterialApp(
            home: Scaffold(
              body: AuraIconButton(icon: Icons.close, onPressed: _noop),
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      final overlayColor = iconButton.style?.overlayColor;

      expect(
        overlayColor?.resolve({WidgetState.focused}),
        AuraTheme.light.colors.surfaceVariant,
      );
      expect(
        overlayColor?.resolve({WidgetState.hovered}),
        AuraTheme.light.colors.onSurface.withValues(alpha: 0.08),
      );
      expect(overlayColor?.resolve({WidgetState.pressed}), Colors.transparent);
      expect(
        iconButton.style?.splashFactory,
        isNot(same(ThemeData().splashFactory)),
      );
    },
  );

  testWidgets('uses local content radius when a corner scope is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: Scaffold(
            body: AuraCornerRadiusScope.select(
              level: .xl,
              child: AuraCornerRadiusScope.adjust(
                delta: 4,
                child: const AuraIconButton(
                  icon: Icons.close,
                  onPressed: _noop,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final shape = tester
        .widget<IconButton>(find.byType(IconButton))
        .style
        ?.shape
        ?.resolve({});

    expect(
      shape,
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AuraTheme.light.fromBorderRadius(.xl) - 4,
        ),
      ),
    );
  });
}

void _noop() {
  final _ = Object();
}
