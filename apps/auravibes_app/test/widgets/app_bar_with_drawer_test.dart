import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders app bar with menu icon', (tester) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(
            appBar: AuraAppBarWithDrawer(title: Text('Test AppBar')),
          ),
          theme: .new(),
          localizationsDelegates: const [
            ...GlobalMaterialLocalizations.delegates,
            sdk_localizations.GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );

    expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('renders with title', (tester) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(
            appBar: AuraAppBarWithDrawer(title: Text('Test Title')),
          ),
          theme: .new(),
          localizationsDelegates: const [
            ...GlobalMaterialLocalizations.delegates,
            sdk_localizations.GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
  });

  testWidgets('renders with actions', (tester) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(
            appBar: AuraAppBarWithDrawer(
              title: Text('Test AppBar'),
              actions: [Icon(Icons.settings)],
            ),
          ),
          theme: .new(),
          localizationsDelegates: const [
            ...GlobalMaterialLocalizations.delegates,
            sdk_localizations.GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('keeps menu access beside an explicit leading action', (
    tester,
  ) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(
            appBar: AuraAppBarWithDrawer(
              title: Text('Test AppBar'),
              leading: AuraIconButton(icon: Icons.arrow_back),
            ),
          ),
          theme: .new(),
          localizationsDelegates: const [
            ...GlobalMaterialLocalizations.delegates,
            sdk_localizations.GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'AppBar',
      ),
      findsOneWidget,
    );
  });

  testWidgets('adds back access for a nested route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/parent',
          builder: (_, _) => const Scaffold(body: Text('Parent')),
          routes: [
            GoRoute(
              path: 'child',
              builder: (_, _) => const Scaffold(
                appBar: AuraAppBarWithDrawer(title: Text('Child')),
              ),
            ),
          ],
        ),
      ],
      initialLocation: '/parent/child',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp.router(
          routerConfig: router,
          theme: .new(),
          localizationsDelegates: const [
            ...GlobalMaterialLocalizations.delegates,
            sdk_localizations.GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Parent'), findsOneWidget);
  });

  testWidgets('preferredSize includes bottom height', (tester) {
    const bar = AuraAppBarWithDrawer(
      title: Text('Test AppBar'),
      bottom: PreferredSize(
        preferredSize: .fromHeight(48),
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
    const bar = AuraAppBarWithDrawer(title: Text('Test AppBar'));

    expect(bar.preferredSize, equals(const Size.fromHeight(kToolbarHeight)));

    return Future<void>.value();
  });

  testWidgets('toggle drawer when controller available', (tester) async {
    final controller = ResponsiveSlidingDrawerController();

    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: ResponsiveSlidingDrawerProvider(
            controller: controller,
            child: const Scaffold(
              appBar: AuraAppBarWithDrawer(title: Text('Test AppBar')),
            ),
          ),
          theme: .new(),
          localizationsDelegates: const [
            ...GlobalMaterialLocalizations.delegates,
            sdk_localizations.GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();

    expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
  });
}
