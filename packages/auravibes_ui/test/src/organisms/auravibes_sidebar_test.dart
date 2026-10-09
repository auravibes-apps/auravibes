import 'dart:ui' show Tristate;

import 'package:auravibes_ui/src/organisms/aura_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraSidebar', () {
    testWidgets('renders navigation items at expanded and collapsed widths', (
      tester,
    ) async {
      int? tappedIndex;
      const items = [
        AuraNavigationData(icon: Icon(Icons.home), label: Text('Home')),
        AuraNavigationData(icon: Icon(Icons.settings), label: Text('Settings')),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AuraSidebar(
                  navigationItems: items,
                  onNavigationTap: (index) => tappedIndex = index,
                ),
                AuraSidebar(
                  navigationItems: items,
                  onNavigationTap: (index) => tappedIndex = index,
                  isExpanded: false,
                ),
              ],
            ),
          ),
        ),
      );

      final sidebars = find.byType(AuraSidebar);
      expect(sidebars, findsNWidgets(2));
      expect(tester.getSize(sidebars.at(0)).width, 280);
      expect(tester.getSize(sidebars.at(1)).width, 80);
      expect(
        find.descendant(of: sidebars.at(0), matching: find.text('Home')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sidebars.at(0), matching: find.text('Settings')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: sidebars.at(0), matching: find.text('Settings')),
      );
      expect(tappedIndex, 1);
    });

    testWidgets('fits navigation labels at large RTL text scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(200, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const .linear(2)),
                  child: Directionality(
                    textDirection: .rtl,
                    child: AuraSidebar(
                      navigationItems: const [
                        AuraNavigationData(
                          icon: Icon(Icons.home),
                          label: Text('Nuevo Chat'),
                          semanticLabel: 'Nuevo Chat',
                        ),
                      ],
                      onNavigationTap: (_) {
                        final _ = Object();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Nuevo Chat'), findsOneWidget);
        expect(find.bySemanticsLabel('Nuevo Chat'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('exposes selected and unselected semantics', (tester) async {
      int? tappedIndex;
      final semantics = tester.ensureSemantics();

      Widget buildSidebar(int selectedIndex) => MaterialApp(
        home: Scaffold(
          body: AuraSidebar(
            navigationItems: const [
              AuraNavigationData(
                icon: Icon(Icons.home),
                label: Text('Home'),
                semanticLabel: 'Home',
              ),
              AuraNavigationData(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
                semanticLabel: 'Settings',
              ),
              AuraNavigationData(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                footer: true,
                semanticLabel: 'Logout',
              ),
            ],
            onNavigationTap: (index) => tappedIndex = index,
            selectedIndex: selectedIndex,
          ),
        ),
      );

      await tester.pumpWidget(buildSidebar(1));

      final home = tester.getSemantics(find.bySemanticsLabel('Home'));
      final settings = tester.getSemantics(find.bySemanticsLabel('Settings'));
      final logout = tester.getSemantics(find.bySemanticsLabel('Logout'));
      expect(home.flagsCollection.isSelected, Tristate.isFalse);
      expect(settings.flagsCollection.isSelected, Tristate.isTrue);
      expect(logout.flagsCollection.isSelected, Tristate.isFalse);
      expect(settings.label, 'Settings');
      final settingsData = settings.getSemanticsData();
      expect(settingsData.flagsCollection.isButton, isTrue);
      expect(settingsData.hasAction(.tap), isTrue);

      await tester.tap(find.bySemanticsLabel('Settings'));
      expect(tappedIndex, 1);

      await tester.pumpWidget(buildSidebar(2));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Settings'))
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Logout'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      semantics.dispose();
    });

    testWidgets('keeps keyboard activation', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                  semanticLabel: 'Home',
                ),
                AuraNavigationData(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                  semanticLabel: 'Settings',
                ),
              ],
              onNavigationTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      expect(await tester.sendKeyEvent(.tab), isTrue);
      expect(await tester.sendKeyEvent(.tab), isTrue);
      expect(await tester.sendKeyEvent(.enter), isTrue);
      expect(tappedIndex, 1);
    });

    testWidgets('renders optional header, middle section, and footer', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [],
              onNavigationTap: (_) {
                final _ = Object();
              },
              header: const Text('Header'),
              middleSection: const Text('Middle'),
              footer: const Text('Footer'),
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
      expect(find.text('Middle'), findsOneWidget);
    });

    testWidgets('separates footer navigation items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraSidebar(
              navigationItems: const [
                AuraNavigationData(icon: Icon(Icons.home), label: Text('Home')),
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
        find.descendant(of: find.byType(ListView), matching: find.text('Home')),
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
  });
}
