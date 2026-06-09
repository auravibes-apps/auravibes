import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders app bar with menu icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          appBar: AuraAppBarWithDrawer(
            title: Text('Test AppBar'),
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('renders with title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          appBar: AuraAppBarWithDrawer(
            title: Text('Test Title'),
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
  });

  testWidgets('renders with actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          appBar: AuraAppBarWithDrawer(
            title: Text('Test AppBar'),
            actions: [
              Icon(Icons.settings),
            ],
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('preferredSize includes bottom height', (tester) {
    const bar = AuraAppBarWithDrawer(
      title: Text('Test AppBar'),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: SizedBox.shrink(),
      ),
    );

    expect(
      bar.preferredSize,
      equals(const Size.fromHeight(kToolbarHeight + 48)),
    );

    return Future<void>.value();
  });

  testWidgets('preferredSize without bottom is kToolbarHeight', (tester) {
    const bar = AuraAppBarWithDrawer(
      title: Text('Test AppBar'),
    );

    expect(bar.preferredSize, equals(const Size.fromHeight(kToolbarHeight)));

    return Future<void>.value();
  });

  testWidgets('toggle drawer when controller available', (tester) async {
    final controller = ResponsiveSlidingDrawerController();

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveSlidingDrawerProvider(
          controller: controller,
          child: const Scaffold(
            appBar: AuraAppBarWithDrawer(
              title: Text('Test AppBar'),
            ),
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();

    expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
  });
}
