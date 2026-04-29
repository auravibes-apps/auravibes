import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders app bar with menu icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: const Scaffold(
          appBar: AuraAppBarWithDrawer(),
        ),
      ),
    );

    expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('renders with title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: const Scaffold(
          appBar: AuraAppBarWithDrawer(
            title: Text('Test Title'),
          ),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
  });

  testWidgets('renders with actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: const Scaffold(
          appBar: AuraAppBarWithDrawer(
            actions: [
              Icon(Icons.settings),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('preferredSize includes bottom height', (tester) async {
    const bar = AuraAppBarWithDrawer(
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: SizedBox.shrink(),
      ),
    );

    expect(
      bar.preferredSize,
      equals(const Size.fromHeight(kToolbarHeight + 48)),
    );
  });

  testWidgets('preferredSize without bottom is kToolbarHeight', (tester) async {
    const bar = AuraAppBarWithDrawer();

    expect(bar.preferredSize, equals(const Size.fromHeight(kToolbarHeight)));
  });

  testWidgets('toggle drawer when controller available', (tester) async {
    final controller = ResponsiveSlidingDrawerController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: ResponsiveSlidingDrawerProvider(
          controller: controller,
          child: const Scaffold(
            appBar: AuraAppBarWithDrawer(),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();

    expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
  });
}
