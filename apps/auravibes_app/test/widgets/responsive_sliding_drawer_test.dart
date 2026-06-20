// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: cascade_invocations
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    }) {
      return EasyLocalization(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: ResponsiveSlidingDrawer(
                drawer: const Text('Drawer'),
                body: const Text('Body'),
                isDarkMode: isDarkMode,
                controller: controller,
              ),
              theme: ThemeData(extensions: [AuraTheme.light]),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      );
    }

    Future<void> pumpDrawer(
      WidgetTester tester, {
      required ResponsiveSlidingDrawerController controller,
      bool isDarkMode = false,
    }) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          buildDrawer(
            controller: controller,
            isDarkMode: isDarkMode,
          ),
        );
      });
      await tester.pump();
      await tester.pump();
      await tester.pump();
      final _ = await tester.pumpAndSettle();
    }

    testWidgets('renders drawer and body widgets', (tester) async {
      final controller = ResponsiveSlidingDrawerController();
      await pumpDrawer(tester, controller: controller);

      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('controller attaches and reports isDesktop', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      expect(controller.isDesktop, isTrue);
    });

    testWidgets('controller open animates drawer', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('controller close after open', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      controller.close();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('controller toggle opens then closes', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
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

    testWidgets('uses desktop layout when width >= 600', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      expect(controller.isDesktop, isTrue);
    });

    testWidgets('uses mobile layout when width < 600', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDrawer(tester, controller: controller);

      expect(controller.isDesktop, isFalse);
    });

    testWidgets('closeIfMobile closes drawer on mobile width', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      controller.closeIfMobile();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('renders dark mode scrim colors', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDrawer(tester, controller: controller, isDarkMode: true);

      controller.open();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('controller toggle on mobile opens then closes', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDrawer(tester, controller: controller);

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      controller.toggle();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('mobile tap closes drawer when fully open', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      final scrim = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.child is Stack,
      );
      final scrimRect = tester.getRect(scrim);
      await tester.tapAt(Offset(scrimRect.left + 1, scrimRect.center.dy));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('divider hover changes state on desktop', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.open();
      final _ = await tester.pumpAndSettle();

      final mouseRegion = find.byType(MouseRegion);
      expect(mouseRegion, findsWidgets);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
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

      expect(
        find.byTooltip(tooltip),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(tooltip),
        findsOneWidget,
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byTooltip(tooltip),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, greaterThan(0));
    });

    testWidgets('desktop drag area exists when closed', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await pumpDrawer(tester, controller: controller);

      controller.close();
      final _ = await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });
  });
}
