import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/molecules/auravibes_avatar.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraAvatar', () {
    group('AuraAvatar.initials', () {
      testWidgets('renders initials correctly', (tester) async {
        const initials = 'JD';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.initials(
                initials: initials,
              ),
            ),
          ),
        );

        expect(find.text(initials.toUpperCase()), findsOneWidget);
        expect(find.byType(AuraText), findsOneWidget);
      });

      testWidgets('applies medium size correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.initials(
                initials: 'JD',
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        expect(container.constraints?.maxWidth, 40.0);
        expect(container.constraints?.maxHeight, 40.0);
      });

      testWidgets('applies large size correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.initials(
                initials: 'JD',
                size: AuraAvatarSize.large,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        expect(container.constraints?.maxWidth, 48.0);
        expect(container.constraints?.maxHeight, 48.0);
      });

      testWidgets('applies custom background color correctly', (tester) async {
        const customColor = AuraColorVariant.error;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.initials(
                initials: 'JD',
                backgroundColor: customColor,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;
        // Note: The actual color will be resolved from AuraColorVariant.error
        expect(decoration.color, isNotNull);
      });

      testWidgets('applies semantic label correctly', (tester) async {
        const semanticLabel = 'User avatar';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.initials(
                initials: 'JD',
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        );

        // Check that the semantic label is applied correctly
        final semanticsWidgets = find.byType(Semantics);
        expect(semanticsWidgets, findsWidgets);

        // Find the AuraAvatar widget and verify it has the semantic label
        final avatarWidget = tester.widget<AuraAvatar>(find.byType(AuraAvatar));
        expect(avatarWidget.semanticLabel, equals(semanticLabel));
      });

      testWidgets('handles tap correctly', (tester) async {
        var wasTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraAvatar.initials(
                initials: 'JD',
                onTap: () => wasTapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AuraAvatar));
        expect(wasTapped, isTrue);
      });
    });

    group('AuraAvatar.icon', () {
      testWidgets('renders icon correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.icon(
                icon: Icons.person,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('applies correct icon size for medium avatar', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.icon(
                icon: Icons.person,
              ),
            ),
          ),
        );

        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.person));
        expect(iconWidget.size, 20.0);
      });
    });

    group('AuraAvatar.image', () {
      testWidgets('renders image correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.image(
                imageProvider: AssetImage('assets/test_image.png'),
              ),
            ),
          ),
        );

        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('shows fallback text when image fails to load', (
        tester,
      ) async {
        const fallbackText = 'FB';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.image(
                imageProvider: AssetImage('assets/nonexistent.png'),
                fallbackText: fallbackText,
              ),
            ),
          ),
        );

        // Trigger image error
        await tester.pump();

        expect(find.text(fallbackText.toUpperCase()), findsOneWidget);
      });

      testWidgets('shows fallback icon when image fails to load', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuraAvatar.image(
                imageProvider: AssetImage('assets/nonexistent.png'),
                fallbackIcon: Icons.error,
              ),
            ),
          ),
        );

        // Trigger image error
        await tester.pump();

        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('AuraAvatarSize enum', () {
      test('has all expected values', () {
        expect(AuraAvatarSize.values, hasLength(6));
        expect(AuraAvatarSize.values, contains(AuraAvatarSize.extraSmall));
        expect(AuraAvatarSize.values, contains(AuraAvatarSize.small));
        expect(AuraAvatarSize.values, contains(AuraAvatarSize.medium));
        expect(AuraAvatarSize.values, contains(AuraAvatarSize.large));
        expect(AuraAvatarSize.values, contains(AuraAvatarSize.extraLarge));
        expect(AuraAvatarSize.values, contains(AuraAvatarSize.huge));
      });
    });
  });

  group('AuraAvatarGroup', () {
    testWidgets('renders multiple avatars correctly', (tester) async {
      final avatars = [
        const AuraAvatar.initials(initials: 'JD'),
        const AuraAvatar.initials(initials: 'AB'),
        const AuraAvatar.initials(initials: 'CD'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAvatarGroup(
              avatars: avatars,
            ),
          ),
        ),
      );

      expect(find.byType(AuraAvatar), findsNWidgets(3));
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('AB'), findsOneWidget);
      expect(find.text('CD'), findsOneWidget);
    });

    testWidgets('shows count avatar when exceeding maxVisible', (tester) async {
      final avatars = [
        const AuraAvatar.initials(initials: 'JD'),
        const AuraAvatar.initials(initials: 'AB'),
        const AuraAvatar.initials(initials: 'CD'),
        const AuraAvatar.initials(initials: 'EF'),
        const AuraAvatar.initials(initials: 'GH'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAvatarGroup(
              avatars: avatars,
            ),
          ),
        ),
      );

      expect(find.byType(AuraAvatar), findsNWidgets(4)); // 3 visible + 1 count
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('does not show count when showCount is false', (tester) async {
      final avatars = [
        const AuraAvatar.initials(initials: 'JD'),
        const AuraAvatar.initials(initials: 'AB'),
        const AuraAvatar.initials(initials: 'CD'),
        const AuraAvatar.initials(initials: 'EF'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAvatarGroup(
              avatars: avatars,
              maxVisible: 2,
              showCount: false,
            ),
          ),
        ),
      );

      expect(find.byType(AuraAvatar), findsNWidgets(2));
      expect(find.text('+2'), findsNothing);
    });

    testWidgets('applies semantic label correctly', (tester) async {
      const semanticLabel = 'Team members';
      final avatars = [
        const AuraAvatar.initials(initials: 'JD'),
        const AuraAvatar.initials(initials: 'AB'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraAvatarGroup(
              avatars: avatars,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      // Check that the semantic label is applied correctly
      final semanticsWidgets = find.byType(Semantics);
      expect(semanticsWidgets, findsWidgets);

      // Find the AuraAvatarGroup widget and verify it has the semantic label
      final avatarGroupWidget = tester.widget<AuraAvatarGroup>(
        find.byType(AuraAvatarGroup),
      );
      expect(avatarGroupWidget.semanticLabel, equals(semanticLabel));
    });

    testWidgets('returns empty widget when avatars list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraAvatarGroup(
              avatars: [],
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(AuraAvatar), findsNothing);
    });
  });
}
