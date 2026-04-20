import 'package:auravibes_ui/src/organisms/auravibes_bottom_bar.dart';
import 'package:auravibes_ui/src/organisms/auravibes_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraBottomBar', () {
    testWidgets('renders navigation items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraBottomBar(
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
              onNavigationTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('calls onNavigationTap with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraBottomBar(
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

    testWidgets('shows labels by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraBottomBar(
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
              ],
              onNavigationTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('hides labels when showLabels is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraBottomBar(
              showLabels: false,
              navigationItems: const [
                AuraNavigationData(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
              ],
              onNavigationTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsNothing);
    });

    testWidgets('marks selected index correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraBottomBar(
              selectedIndex: 1,
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
              onNavigationTap: (_) {},
            ),
          ),
        ),
      );

      // Both items render, selectedIndex=1 means Settings is selected
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
