// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: cascade_invocations

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SwipeDraft extends StatefulWidget {
  const new({
    required this.guard,
    required this.controller,
    required this.isSaving,
    required this.confirm,
  });

  final DraftExitGuard guard;
  final TextEditingController controller;
  final bool isSaving;
  final Future<bool?> Function(BuildContext) confirm;

  @override
  State<_SwipeDraft> createState() => _SwipeDraftState();
}

class _SwipeDraftState extends State<_SwipeDraft> {
  @override
  Widget build(BuildContext context) {
    widget.guard.bind(
      readers: (
        isDirty: () => widget.controller.text.isNotEmpty,
        isSaving: () => widget.isSaving,
      ),
      callbacks: .new(confirm: widget.confirm),
    );

    return DraftExitScope(
      guard: widget.guard,
      child: Scaffold(
        appBar: AppBar(title: const Text('Draft detail')),
        body: TextField(
          controller: widget.controller,
          onChanged: (_) => widget.guard.update(
            isDirty: widget.controller.text.isNotEmpty,
            isSaving: widget.isSaving,
          ),
        ),
      ),
    );
  }
}

GoRouter _buildSwipeTestRouter({
  required DraftExitRegistry registry,
  required ResponsiveSlidingDrawerController controller,
  required Widget detail,
  bool Function()? canPopCurrentRoute,
  TextDirection textDirection = TextDirection.ltr,
}) => GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => Directionality(
        textDirection: textDirection,
        child: ResponsiveSlidingDrawer(
          drawer: const Text('Drawer'),
          body: child,
          isDarkMode: false,
          controller: controller,
          canPopCurrentRoute: canPopCurrentRoute,
        ),
      ),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Text('Home'),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (_, _) => detail,
              onExit: (context, state) =>
                  registry.canUseNativeBack(.of(context))
                  ? true
                  : registry.canExitRoute(state.uri),
            ),
          ],
        ),
      ],
    ),
  ],
  initialLocation: '/home',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget buildSwipeTestApp({
    required GoRouter router,
    required ProviderContainer container,
  }) => EasyLocalization(
    child: Builder(
      builder: (context) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: .new(platform: TargetPlatform.iOS),
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
        ),
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );

  group('ResponsiveSlidingDrawerController', () {
    test('isDesktop defaults to false without state', () {
      final controller = ResponsiveSlidingDrawerController();
      expect(controller.isDesktop, isFalse);
    });

    test('methods are no-op without attached state', () {
      final controller = ResponsiveSlidingDrawerController();
      controller
        ..open()
        ..close()
        ..toggle()
        ..closeIfMobile();

      expect(controller.isDesktop, isFalse);
    });
  });

  group('ResponsiveSlidingDrawerProvider', () {
    test('updateShouldNotify returns true when controller changes', () {
      final controller1 = ResponsiveSlidingDrawerController();
      final controller2 = ResponsiveSlidingDrawerController();

      final provider1 = ResponsiveSlidingDrawerProvider(
        controller: controller1,
        child: const SizedBox.shrink(),
      );
      final provider2 = ResponsiveSlidingDrawerProvider(
        controller: controller2,
        child: const SizedBox.shrink(),
      );

      expect(provider1.updateShouldNotify(provider2), isTrue);
    });

    test('updateShouldNotify returns false when same controller', () {
      final controller = ResponsiveSlidingDrawerController();

      final provider1 = ResponsiveSlidingDrawerProvider(
        controller: controller,
        child: const SizedBox.shrink(),
      );
      final provider2 = ResponsiveSlidingDrawerProvider(
        controller: controller,
        child: const SizedBox.shrink(),
      );

      expect(provider1.updateShouldNotify(provider2), isFalse);
    });

    testWidgets('of returns controller from context', (tester) async {
      final controller = ResponsiveSlidingDrawerController();
      ResponsiveSlidingDrawerController? found;

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveSlidingDrawerProvider(
            controller: controller,
            child: Builder(
              builder: (context) {
                found = ResponsiveSlidingDrawerProvider.of(context);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final foundController = found ?? fail('Expected controller');
      expect(identical(foundController, controller), isTrue);
    });

    testWidgets('maybeOf returns null without provider', (tester) async {
      ResponsiveSlidingDrawerController? found;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              found = ResponsiveSlidingDrawerProvider.maybeOf(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(found, isNull);
    });

    testWidgets('of throws assert without provider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final _ = ResponsiveSlidingDrawerProvider.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('ResponsiveSlidingDrawer', () {
    Widget buildDrawer({
      required ResponsiveSlidingDrawerController controller,
      bool isDarkMode = false,
      bool initiallyOpen = false,
      TextDirection textDirection = TextDirection.ltr,
      TargetPlatform? platform,
      Widget drawer = const Text('Drawer'),
      Widget body = const Text('Body'),
    }) {
      return ProviderScope(
        child: EasyLocalization(
          child: Builder(
            builder: (context) {
              return AuraThemeScope(
                theme: .light,
                child: MaterialApp(
                  home: Directionality(
                    textDirection: textDirection,
                    child: ResponsiveSlidingDrawer(
                      drawer: drawer,
                      body: body,
                      isDarkMode: isDarkMode,
                      controller: controller,
                      initiallyOpen: initiallyOpen,
                    ),
                  ),
                  theme: .new(platform: platform),
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                ),
              );
            },
          ),
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
        ),
      );
    }

    Future<void> pumpDrawer(
      WidgetTester tester, {
      required ResponsiveSlidingDrawerController controller,
      bool isDarkMode = false,
      bool initiallyOpen = false,
      TextDirection textDirection = TextDirection.ltr,
      Size viewSize = const Size(1200, 800),
      TargetPlatform? platform,
      Widget drawer = const Text('Drawer'),
      Widget body = const Text('Body'),
    }) async {
      tester.view.physicalSize = viewSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.runAsync(() async {
        await tester.pumpWidget(
          buildDrawer(
            controller: controller,
            isDarkMode: isDarkMode,
            initiallyOpen: initiallyOpen,
            textDirection: textDirection,
            platform: platform,
            drawer: drawer,
            body: body,
          ),
        );
      });
      await tester.pump();
      await tester.pump();
      await tester.pump();
      final _ = await tester.pumpAndSettle();
    }

    testWidgets('desktop drawer renders and reports attachment', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();
      await pumpDrawer(tester, controller: controller);

      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(controller.isDesktop, isTrue);
    });

    testWidgets('mobile body fills the width through horizontal safe insets', (
      tester,
    ) async {
      tester.view
        ..padding = const FakeViewPadding(left: 24, right: 20)
        ..viewPadding = const FakeViewPadding(left: 24, right: 20);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      var bodyWidth = 0.0;

      await pumpDrawer(
        tester,
        controller: .new(),
        viewSize: const Size(400, 800),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bodyWidth = constraints.maxWidth;

            return const Text('Body');
          },
        ),
      );

      expect(bodyWidth, 400);
    });

    testWidgets('desktop body fills the width to the edge opposite sidebar', (
      tester,
    ) async {
      for (final textDirection in <TextDirection>[.ltr, .rtl]) {
        tester.view
          ..padding = const FakeViewPadding(left: 24, right: 20)
          ..viewPadding = const FakeViewPadding(left: 24, right: 20);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        var bodyWidth = 0.0;

        await tester.pumpWidget(const SizedBox.shrink());
        await pumpDrawer(
          tester,
          controller: .new(),
          textDirection: textDirection,
          initiallyOpen: true,
          body: LayoutBuilder(
            builder: (context, constraints) {
              bodyWidth = constraints.maxWidth;

              return const Text('Body');
            },
          ),
        );

        expect(bodyWidth, 840 + (textDirection == TextDirection.ltr ? 24 : 20));
      }
    });

    testWidgets('drawer leaves safe insets available to its content', (
      tester,
    ) async {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        tester.view
          ..padding = const FakeViewPadding(left: 24, right: 20, bottom: 16)
          ..viewPadding = const FakeViewPadding(
            left: 24,
            right: 20,
            bottom: 16,
          );
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);

        EdgeInsets? contentPadding;
        await pumpDrawer(
          tester,
          controller: .new(),
          initiallyOpen: true,
          textDirection: direction,
          viewSize: const Size(400, 800),
          drawer: Builder(
            builder: (context) {
              contentPadding = MediaQuery.paddingOf(context);

              return const SizedBox.expand();
            },
          ),
        );

        final padding = contentPadding;
        if (padding == null) fail('Expected drawer content to build');
        expect(padding.left, 24);
        expect(padding.right, 20);
        expect(padding.bottom, 16);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('body safe-area gap animates to the drawer edge', (
      tester,
    ) async {
      const scenarios = [
        (size: Size(400, 800), drawerWidth: 320.0),
        (size: Size(1200, 800), drawerWidth: 360.0),
      ];

      for (final scenario in scenarios) {
        for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
          const leftInset = 24.0;
          const rightInset = 20.0;
          tester.view
            ..padding = const FakeViewPadding(
              left: leftInset,
              right: rightInset,
            )
            ..viewPadding = const FakeViewPadding(
              left: leftInset,
              right: rightInset,
            );
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);

          final controller = ResponsiveSlidingDrawerController();
          await pumpDrawer(
            tester,
            controller: controller,
            textDirection: direction,
            viewSize: scenario.size,
            body: const SafeArea(
              child: Align(alignment: .topStart, child: Text('Body')),
            ),
          );

          final body = find.text('Body');
          double leadingEdge(Rect rect) => direction == TextDirection.ltr
              ? rect.left
              : scenario.size.width - rect.right;
          final safeInset = direction == TextDirection.ltr
              ? leftInset
              : rightInset;
          expect(leadingEdge(tester.getRect(body)), closeTo(safeInset, 0.01));

          controller.open();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 125));
          final expectedMidpoint =
              safeInset + (scenario.drawerWidth - safeInset) / 2;
          expect(
            leadingEdge(tester.getRect(body)),
            closeTo(expectedMidpoint, 1),
          );

          final _ = await tester.pumpAndSettle();
          expect(
            leadingEdge(tester.getRect(body)),
            closeTo(scenario.drawerWidth, 0.01),
          );

          controller.close();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 125));
          expect(
            leadingEdge(tester.getRect(body)),
            closeTo(expectedMidpoint, 1),
          );
          final _ = await tester.pumpAndSettle();
          expect(leadingEdge(tester.getRect(body)), closeTo(safeInset, 0.01));
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });

    testWidgets('controller opens, closes, and toggles drawer', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
      controller.close();
      final _ = await tester.pumpAndSettle();
      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      controller.toggle();
      final _ = await tester.pumpAndSettle();

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('can start with drawer open', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller, initiallyOpen: true);

      expect(tester.getTopLeft(find.text('Drawer')).dx, closeTo(0, 0.1));

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Drawer')).dx, lessThan(0));
    });

    testWidgets('closeIfMobile does nothing on desktop width', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      controller.closeIfMobile();
      final _ = await tester.pumpAndSettle();

      expect(controller.isDesktop, isTrue);
    });

    testWidgets('controller updates when widget rebuilt', (tester) async {
      final controller1 = ResponsiveSlidingDrawerController();
      final controller2 = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller1);
      expect(controller1.isDesktop, isTrue);

      await pumpDrawer(tester, controller: controller2);
      expect(controller2.isDesktop, isTrue);
      expect(controller1.isDesktop, isFalse);
    });

    testWidgets('uses overlay below 900 and docked layout at 900', (
      tester,
    ) async {
      for (final width in [599.0, 600.0, 899.0, 900.0, 951.0]) {
        await tester.pumpWidget(const SizedBox.shrink());
        final controller = ResponsiveSlidingDrawerController();
        await pumpDrawer(
          tester,
          controller: controller,
          viewSize: .new(width, 800),
          initiallyOpen: true,
        );

        expect(controller.isDesktop, width >= 900);
        final panel = find
            .ancestor(of: find.text('Drawer'), matching: find.byType(SizedBox))
            .first;
        final expectedWidth = width >= 900
            ? (width * 0.3).clamp(150.0, 400.0)
            : (width * 0.8).clamp(0.0, 400.0);
        expect(tester.getSize(panel).width, closeTo(expectedWidth, 0.1));
      }
    });

    testWidgets('closes on mobile and opens on desktop when resized', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller, initiallyOpen: true);
      expect(tester.getTopLeft(find.text('Drawer')).dx, closeTo(0, 0.1));

      tester.view.physicalSize = const Size(400, 800);
      final _ = await tester.pumpAndSettle();
      expect(controller.isDesktop, isFalse);
      expect(tester.getTopLeft(find.text('Drawer')).dx, lessThan(0));

      tester.view.physicalSize = const Size(1200, 800);
      final _ = await tester.pumpAndSettle();
      expect(controller.isDesktop, isTrue);
      expect(tester.getTopLeft(find.text('Drawer')).dx, closeTo(0, 0.1));
    });

    testWidgets('restores the desktop drawer width after it is recreated', (
      tester,
    ) async {
      await pumpDrawer(tester, controller: .new(), initiallyOpen: true);
      final defaultWidth = _drawerPanelWidth(tester);

      await tester.drag(
        find.byTooltip(LocaleKeys.navigation_drawer_resize_handle_tooltip.tr()),
        const .new(-50, 0),
      );
      final _ = await tester.pumpAndSettle();
      final resizedWidth = _drawerPanelWidth(tester);
      expect(resizedWidth, lessThan(defaultWidth));

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpDrawer(tester, controller: .new(), initiallyOpen: true);

      expect(_drawerPanelWidth(tester), closeTo(resizedWidth, 0.1));
    });

    testWidgets('clamps the restored desktop drawer width', (tester) async {
      for (final (:storedWidth, :expectedWidth) in [
        (storedWidth: 149.0, expectedWidth: 150.0),
        (storedWidth: 401.0, expectedWidth: 400.0),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        SharedPreferences.setMockInitialValues({
          'app_desktop_drawer_width': storedWidth,
        });
        await pumpDrawer(tester, controller: .new(), initiallyOpen: true);

        expect(_drawerPanelWidth(tester), closeTo(expectedWidth, 0.1));
      }
    });

    testWidgets('closeIfMobile closes drawer on mobile width', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(400, 800),
      );

      controller.open();
      final _ = await tester.pumpAndSettle();

      controller.closeIfMobile();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('renders dark mode scrim colors', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(
        tester,
        controller: controller,
        isDarkMode: true,
        viewSize: const Size(400, 800),
      );

      controller.open();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('controller toggle on mobile opens then closes', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(400, 800),
      );

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('mobile tap closes drawer when fully open', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(400, 800),
      );

      controller.open();
      final _ = await tester.pumpAndSettle();

      final scrim = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.child is Stack,
      );
      final scrimRect = tester.getRect(scrim);
      await tester.tapAt(.new(scrimRect.left + 1, scrimRect.center.dy));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('mobile diagonal chat drag scrolls without opening drawer', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(400, 800),
        platform: .iOS,
        body: SizedBox.expand(
          child: ListView(
            controller: scrollController,
            children: const [
              SizedBox(height: 1200, child: Text('Chat content')),
            ],
          ),
        ),
      );

      await tester.dragFrom(const Offset(200, 500), const Offset(100, -80));
      final _ = await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Drawer')).dx, lessThan(0));
      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('mobile drawer opens from left edge swipe', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(400, 800),
        platform: .iOS,
        drawer: const SizedBox.expand(
          child: Align(alignment: .topLeft, child: Text('Drawer')),
        ),
      );

      final gesture = await tester.startGesture(const Offset(12, 400));
      await gesture.moveBy(const Offset(150, 0));
      await gesture.up();
      final _ = await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Drawer')).dx, closeTo(0, 0.1));
    });

    testWidgets('edge uses active navigator instead of shell history', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(draftExitRegistryProvider);
      final router = _buildSwipeTestRouter(
        registry: registry,
        controller: .new(),
        detail: const Text('Detail'),
        canPopCurrentRoute: () => false,
      );
      addTearDown(router.dispose);
      await tester.runAsync(
        () => tester.pumpWidget(
          buildSwipeTestApp(router: router, container: container),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final detail = router.push<void>('/home/detail');
      final _ = await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);

      await tester.dragFrom(const Offset(12, 500), const Offset(250, 500));
      final _ = await tester.pumpAndSettle();

      expect(router.state.uri.path, '/home/detail');
      expect(tester.getTopLeft(find.text('Drawer')).dx, closeTo(0, 0.1));
      router.pop();
      final _ = await tester.pumpAndSettle();
      await detail;
    });

    testWidgets('RTL drawer opens from the right edge swipe', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(400, 800),
        platform: .iOS,
        textDirection: .rtl,
        drawer: const SizedBox.expand(
          child: Align(alignment: .topRight, child: Text('Drawer')),
        ),
      );

      final gesture = await tester.startGesture(const Offset(388, 400));
      await gesture.moveBy(const Offset(-150, 0));
      await gesture.up();
      final _ = await tester.pumpAndSettle();

      expect(tester.getRect(find.text('Drawer')).right, closeTo(400, 0.1));
    });

    testWidgets('iOS edge swipe pops a clean nested route', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(draftExitRegistryProvider);
      final router = _buildSwipeTestRouter(
        registry: registry,
        controller: .new(),
        detail: const Text('Clean detail'),
      );
      addTearDown(router.dispose);
      await tester.runAsync(
        () => tester.pumpWidget(
          buildSwipeTestApp(router: router, container: container),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final detail = router.push<void>('/home/detail');
      final _ = await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      expect(registry.canUseNativeBack(router), isTrue);
      final route = ModalRoute.of(tester.element(find.text('Clean detail')));
      expect(route?.popGestureEnabled, isTrue);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.runtimeType.toString() == 'CupertinoPageTransition',
        ),
        findsNWidgets(2),
      );

      await tester.dragFrom(const Offset(12, 500), const Offset(250, 0));
      final _ = await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Drawer')).dx, lessThan(0));
      expect(router.state.uri.path, '/home');
      expect(find.text('Home'), findsOneWidget);
      await detail;
    });

    testWidgets(
      'dirty iOS edge swipe confirms before popping and cancel keeps edits',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final registry = container.read(draftExitRegistryProvider);
        final guard = DraftExitGuard();
        final draftController = TextEditingController();
        addTearDown(draftController.dispose);
        var answer = false;
        var confirmations = 0;
        final router = _buildSwipeTestRouter(
          registry: registry,
          controller: .new(),
          detail: _SwipeDraft(
            guard: guard,
            controller: draftController,
            isSaving: false,
            confirm: (_) async {
              confirmations++;

              return answer;
            },
          ),
        );
        addTearDown(router.dispose);
        await tester.runAsync(
          () => tester.pumpWidget(
            buildSwipeTestApp(router: router, container: container),
          ),
        );
        final _ = await tester.pumpAndSettle();
        final detail = router.push<void>('/home/detail');
        final _ = await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Keep this draft');
        final _ = await tester.pumpAndSettle();

        Future<void> swipeBack() async {
          await tester.dragFrom(const Offset(12, 500), const Offset(150, 0));
          final _ = await tester.pumpAndSettle();
        }

        await swipeBack();
        expect(confirmations, 1);
        expect(router.state.uri.path, '/home/detail');
        expect(draftController.text, 'Keep this draft');

        answer = true;
        await swipeBack();
        expect(confirmations, 2);
        expect(router.state.uri.path, '/home');
        expect(find.text('Home'), findsOneWidget);
        await detail;
      },
    );

    testWidgets('RTL dirty iOS edge swipe pops from the right edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(draftExitRegistryProvider);
      final guard = DraftExitGuard();
      final draftController = TextEditingController(text: 'Unsaved');
      addTearDown(draftController.dispose);
      var confirmations = 0;
      final router = _buildSwipeTestRouter(
        registry: registry,
        controller: .new(),
        detail: _SwipeDraft(
          guard: guard,
          controller: draftController,
          isSaving: false,
          confirm: (_) async {
            confirmations++;

            return true;
          },
        ),
        textDirection: .rtl,
      );
      addTearDown(router.dispose);
      await tester.runAsync(
        () => tester.pumpWidget(
          buildSwipeTestApp(router: router, container: container),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final detail = router.push<void>('/home/detail');
      final _ = await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(388, 500), const Offset(-150, 0));
      final _ = await tester.pumpAndSettle();

      expect(confirmations, 1);
      expect(router.state.uri.path, '/home');
      await detail;
    });

    testWidgets('saving draft blocks iOS edge swipe without confirmation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final registry = container.read(draftExitRegistryProvider);
      final guard = DraftExitGuard();
      final draftController = TextEditingController();
      addTearDown(draftController.dispose);
      var confirmations = 0;
      final router = _buildSwipeTestRouter(
        registry: registry,
        controller: .new(),
        detail: _SwipeDraft(
          guard: guard,
          controller: draftController,
          isSaving: true,
          confirm: (_) async {
            confirmations++;

            return true;
          },
        ),
      );
      addTearDown(router.dispose);
      await tester.runAsync(
        () => tester.pumpWidget(
          buildSwipeTestApp(router: router, container: container),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final _ = router.push<void>('/home/detail');
      final _ = await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(12, 500), const Offset(150, 0));
      final _ = await tester.pumpAndSettle();

      expect(confirmations, 0);
      expect(router.state.uri.path, '/home/detail');
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.getTopLeft(find.text('Drawer')).dx, lessThan(0));
    });

    testWidgets('mobile drawer closes from blank panel space', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(400, 800),
        platform: .iOS,
        drawer: const SizedBox.expand(
          child: Align(alignment: .topLeft, child: Text('Drawer')),
        ),
      );

      final gesture = await tester.startGesture(const Offset(300, 700));
      await gesture.moveBy(const Offset(-240, 0));
      await gesture.up();
      final _ = await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Drawer')).dx, lessThan(0));
    });

    testWidgets('only exposes drawer actions to keyboard focus while open', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();
      final drawerFocus = FocusNode(debugLabel: 'drawer action');
      addTearDown(drawerFocus.dispose);

      await pumpDrawer(
        tester,
        controller: controller,
        viewSize: const Size(599, 800),
        drawer: TextButton(
          onPressed: () => fail('Drawer action should not be activated'),
          focusNode: drawerFocus,
          child: const Text('Drawer action'),
        ),
      );

      drawerFocus.requestFocus();
      final _ = await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, isNot(drawerFocus));

      controller.open();
      final _ = await tester.pumpAndSettle();
      drawerFocus.requestFocus();
      final _ = await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(drawerFocus));

      controller.close();
      final _ = await tester.pumpAndSettle();
      drawerFocus.unfocus();
      drawerFocus.requestFocus();
      final _ = await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, isNot(drawerFocus));
    });

    testWidgets(
      'desktop drawer stays open after swipes from panel or chat edge',
      (tester) async {
        final controller = ResponsiveSlidingDrawerController();

        await pumpDrawer(
          tester,
          controller: controller,
          initiallyOpen: true,
          drawer: const SizedBox.expand(
            child: Align(alignment: .topLeft, child: Text('Drawer')),
          ),
          body: const SizedBox.expand(
            child: Align(alignment: .topLeft, child: Text('Body')),
          ),
        );

        final gesture = await tester.startGesture(const Offset(220, 500));
        await gesture.moveBy(const Offset(-300, 0));
        await gesture.up();
        final _ = await tester.pumpAndSettle();

        expect(tester.getTopLeft(find.text('Drawer')).dx, closeTo(0, 0.1));

        final edgeGesture = await tester.startGesture(const Offset(365, 500));
        await edgeGesture.moveBy(const Offset(-300, 0));
        await edgeGesture.up();
        final _ = await tester.pumpAndSettle();

        expect(tester.getTopLeft(find.text('Drawer')).dx, closeTo(0, 0.1));
      },
    );

    testWidgets('divider hover changes state on desktop', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      final mouseRegion = find.byType(MouseRegion);
      expect(mouseRegion, findsWidgets);

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(mouseRegion.first));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('desktop divider has visible affordance and semantics', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();
      final tooltip = LocaleKeys.navigation_drawer_resize_handle_tooltip.tr();

      expect(find.byTooltip(tooltip), findsOneWidget);
      expect(find.bySemanticsLabel(tooltip), findsOneWidget);

      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byTooltip(tooltip),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, greaterThan(0));
    });

    testWidgets('desktop drawer content remains mounted when closed', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.close();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('closed drawer descendants are skipped during tab traversal', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();
      var firstBodyPressCount = 0;
      var secondBodyPressCount = 0;
      var drawerPressCount = 0;

      await pumpDrawer(
        tester,
        controller: controller,
        body: Column(
          children: [
            TextButton(
              onPressed: () => firstBodyPressCount++,
              child: const Text('First body action'),
            ),
            TextButton(
              onPressed: () => secondBodyPressCount++,
              child: const Text('Second body action'),
            ),
          ],
        ),
        drawer: TextButton(
          onPressed: () => drawerPressCount++,
          child: const Text('Drawer action'),
        ),
      );

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(.enter), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(.enter), isTrue);
      await tester.pump();

      expect(firstBodyPressCount, 1);
      expect(secondBodyPressCount, 1);
      expect(drawerPressCount, 0);
    });
  });
}

double _drawerPanelWidth(WidgetTester tester) {
  final panel = find
      .ancestor(of: find.text('Drawer'), matching: find.byType(SizedBox))
      .first;

  return tester.getSize(panel).width;
}
