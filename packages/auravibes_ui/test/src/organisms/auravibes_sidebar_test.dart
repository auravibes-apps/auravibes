
import 'package:auravibes_ui/src/organisms/aura_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraSidebar', () {
    testWidgets('renders navigation items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                AuraNavigationData(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
              onNavigationTap: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('has expanded width when isExpanded is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
              ],
              onNavigationTap: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AuraSidebar));
      expect(size.width, 280);
    });

    testWidgets('has collapsed width when isExpanded is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
              ],
              onNavigationTap: (_) {
                final _ = Object();
              },
              isExpanded: false,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AuraSidebar));
      expect(size.width, 80);
    });

    testWidgets('calls onNavigationTap with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                AuraNavigationData(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
              onNavigationTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Settings'));
      expect(tappedIndex, 1);
    });

    testWidgets('renders header when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [],
              onNavigationTap: (_) {
                final _ = Object();
              },
              header: const Text('Header'),
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('renders footer when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [],
              onNavigationTap: (_) {
                final _ = Object();
              },
              footer: const Text('Footer'),
            ),
          ),
        ),
      );

      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('renders middleSection when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [],
              onNavigationTap: (_) {
                final _ = Object();
              },
              middleSection: const Text('Middle'),
            ),
          ),
        ),
      );

      expect(find.text('Middle'), findsOneWidget);
    });

    testWidgets('separates footer navigation items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                AuraNavigationData(
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  footer: true,
                ),
              ],
              onNavigationTap: (_) {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Home'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SafeArea),
          matching: find.text('Logout'),
        ),
        findsOneWidget,
      );
    });
  });

  group('AuraNavigationData', () {
    test('holds icon, label, and footer flag', () {
      const data = AuraNavigationData(
        icon: Icon(Icons.home),
        label: Text('Home'),
        footer: true,
      );

      final icon = data.icon as Icon;
      final label = data.label as Text;
      expect(icon.icon, Icons.home);
      expect(label.data, 'Home');
      expect(data.footer, isTrue);
    });

    test('copyWith creates updated instance', () {
      const data = AuraNavigationData(
        icon: Icon(Icons.home),
        label: Text('Home'),
      );

      final updated = data.copyWith(footer: true);
      expect(updated.footer, isTrue);
      expect(identical(updated.icon, data.icon), isTrue);
      expect(identical(updated.label, data.label), isTrue);
      expect(data.footer, isFalse);
    });
  });
}
