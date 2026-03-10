import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/molecules/auravibes_badge.dart';
import 'package:auravibes_ui/src/organisms/auravibes_app_bar_action.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraAppBarAction', () {
    testWidgets('renders app bar action button correctly', (tester) async {
      const testIcon = Icons.notifications;
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.byType(AuraIcon), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('displays badge when provided', (tester) async {
      const testIcon = Icons.notifications;
      final testBadge = AuraBadge.count(count: 7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
              badge: testBadge,
            ),
          ),
        ),
      );

      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.byType(AuraBadge), findsOneWidget);
    });

    testWidgets('applies custom color correctly', (tester) async {
      const testIcon = Icons.notifications;
      const customColorVariant = AuraColorVariant.error;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
              color: customColorVariant,
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.color, customColorVariant);
    });

    testWidgets('applies default color in light theme', (tester) async {
      const testIcon = Icons.notifications;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      // Default color is now AuraColorVariant.onSurfaceVariant
      expect(auraIcon.color, AuraColorVariant.onSurfaceVariant);
    });

    testWidgets('applies default color in dark theme', (tester) async {
      const testIcon = Icons.notifications;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [AuraTheme.dark],
          ),
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      // Default color in dark theme is also AuraColorVariant.onSurfaceVariant
      expect(auraIcon.color, AuraColorVariant.onSurfaceVariant);
    });

    testWidgets('uses app bar theme foreground color when available', (
      tester,
    ) async {
      const testIcon = Icons.notifications;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: [AuraTheme.light],
            appBarTheme: const AppBarTheme(
              foregroundColor: Colors.purple,
            ),
          ),
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      // In const-first design, AppBarTheme foregroundColor is ignored
      // The widget always uses AuraColorVariant.onSurfaceVariant
      expect(auraIcon.color, AuraColorVariant.onSurfaceVariant);
    });

    testWidgets('handles null onPressed correctly', (tester) async {
      const testIcon = Icons.notifications;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: null,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('applies tooltip correctly', (tester) async {
      const testIcon = Icons.notifications;
      const tooltipMessage = 'Notifications';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
              tooltip: tooltipMessage,
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, tooltipMessage);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const testIcon = Icons.notifications;
      const semanticLabel = 'View notifications';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.semanticLabel, semanticLabel);
    });

    testWidgets('applies proper button constraints and padding', (
      tester,
    ) async {
      const testIcon = Icons.notifications;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.iconSize, 24.0);
      expect(iconButton.padding, const EdgeInsets.all(DesignSpacing.sm));
      expect(
        iconButton.constraints,
        const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      );
    });

    testWidgets('applies proper icon size', (tester) async {
      const testIcon = Icons.notifications;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
            ),
          ),
        ),
      );

      final auraIcon = tester.widget<AuraIcon>(find.byType(AuraIcon));
      expect(auraIcon.size, AuraIconSize.medium);
    });

    testWidgets('applies transparent background', (tester) async {
      const testIcon = Icons.notifications;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAppBarAction(
              icon: testIcon,
              onPressed: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        iconButton.style?.backgroundColor?.resolve({}),
        Colors.transparent,
      );
    });
  });
}
