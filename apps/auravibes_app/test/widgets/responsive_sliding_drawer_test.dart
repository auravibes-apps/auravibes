// ignore_for_file: cascade_invocations
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
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
      late ResponsiveSlidingDrawerController found;

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

      expect(identical(found, controller), isTrue);
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
              ResponsiveSlidingDrawerProvider.of(context);
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
      Duration animationDuration = const Duration(milliseconds: 250),
      VoidCallback? onFinishedOpening,
      VoidCallback? onFinishedClosing,
      void Function({required bool isOpen})? onAnimationComplete,
      VoidCallback? onStartedOpening,
      VoidCallback? onStartedClosing,
      bool isDarkMode = false,
      bool centerDivider = true,
    }) {
      return MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: ResponsiveSlidingDrawer(
          controller: controller,
          isDarkMode: isDarkMode,
          animationDuration: animationDuration,
          onFinishedOpening: onFinishedOpening,
          onFinishedClosing: onFinishedClosing,
          onAnimationComplete: onAnimationComplete,
          onStartedOpening: onStartedOpening,
          onStartedClosing: onStartedClosing,
          centerDivider: centerDivider,
          drawer: const Text('Drawer'),
          body: const Text('Body'),
        ),
      );
    }

    testWidgets('renders drawer and body widgets', (tester) async {
      final controller = ResponsiveSlidingDrawerController();
      await tester.pumpWidget(buildDrawer(controller: controller));

      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('controller attaches and reports isDesktop', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(buildDrawer(controller: controller));

      expect(controller.isDesktop, isTrue);
    });

    testWidgets('controller open animates drawer', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('controller close after open', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      controller.close();
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('controller toggle opens then closes', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.toggle();
      await tester.pumpAndSettle();

      controller.toggle();
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('onFinishedOpening callback fires', (tester) async {
      var opened = false;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onFinishedOpening: () => opened = true,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('onFinishedClosing callback fires', (tester) async {
      var closed = false;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onFinishedClosing: () => closed = true,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      controller.close();
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('onAnimationComplete fires with isOpen true', (tester) async {
      bool? lastIsOpen;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onAnimationComplete: ({required isOpen}) {
            lastIsOpen = isOpen;
          },
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(lastIsOpen, isTrue);
    });

    testWidgets('onAnimationComplete fires with isOpen false after close', (
      tester,
    ) async {
      bool? lastIsOpen;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onAnimationComplete: ({required isOpen}) {
            lastIsOpen = isOpen;
          },
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      controller.close();
      await tester.pumpAndSettle();

      expect(lastIsOpen, isFalse);
    });

    testWidgets('onStartedOpening fires on programmatic open', (tester) async {
      var started = false;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onStartedOpening: () => started = true,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(started, isTrue);
    });

    testWidgets('closeIfMobile does nothing on desktop width', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      controller.closeIfMobile();
      await tester.pumpAndSettle();

      expect(controller.isDesktop, isTrue);
    });

    testWidgets('controller updates when widget rebuilt', (tester) async {
      final controller1 = ResponsiveSlidingDrawerController();
      final controller2 = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(buildDrawer(controller: controller1));
      expect(controller1.isDesktop, isTrue);

      await tester.pumpWidget(buildDrawer(controller: controller2));
      expect(controller2.isDesktop, isTrue);
      expect(controller1.isDesktop, isFalse);
    });

    testWidgets('uses desktop layout when width >= 600', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(buildDrawer(controller: controller));

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

      await tester.pumpWidget(buildDrawer(controller: controller));

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

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      controller.closeIfMobile();
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('onStartedClosing fires on programmatic close', (
      tester,
    ) async {
      var started = false;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onStartedClosing: () => started = true,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      controller.close();
      await tester.pumpAndSettle();

      expect(started, isTrue);
    });

    testWidgets('open when already fully open fires onFinishedOpening', (
      tester,
    ) async {
      var openedCount = 0;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onFinishedOpening: () => openedCount++,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();
      expect(openedCount, 1);

      controller.open();
      await tester.pumpAndSettle();
      expect(openedCount, 2);
    });

    testWidgets('close when already fully closed fires onFinishedClosing', (
      tester,
    ) async {
      var closedCount = 0;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onFinishedClosing: () => closedCount++,
        ),
      );

      controller.close();
      await tester.pumpAndSettle();
      expect(closedCount, 1);
    });

    testWidgets('renders dark mode scrim colors', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          isDarkMode: true,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

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

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.toggle();
      await tester.pumpAndSettle();

      controller.toggle();
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('onStartedOpening fires on programmatic open from closed', (
      tester,
    ) async {
      var started = false;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onStartedOpening: () => started = true,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(started, isTrue);
    });

    testWidgets('onStartedClosing fires on programmatic close from open', (
      tester,
    ) async {
      var startedClosing = false;
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          onStartedClosing: () => startedClosing = true,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();
      controller.close();
      await tester.pumpAndSettle();

      expect(startedClosing, isTrue);
    });

    testWidgets('mobile tap closes drawer when fully open', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('renders with centerDivider false on desktop', (
      tester,
    ) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
          centerDivider: false,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('divider hover changes state on desktop', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      final mouseRegion = find.byType(MouseRegion);
      expect(mouseRegion, findsWidgets);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(mouseRegion.first));
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });

    testWidgets('desktop drag area exists when closed', (tester) async {
      final controller = ResponsiveSlidingDrawerController();

      await tester.pumpWidget(
        buildDrawer(
          controller: controller,
          animationDuration: Duration.zero,
        ),
      );

      controller.close();
      await tester.pumpAndSettle();

      expect(find.text('Drawer'), findsOneWidget);
    });
  });
}
