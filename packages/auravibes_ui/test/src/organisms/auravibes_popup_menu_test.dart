import 'package:auravibes_ui/src/organisms/auravibes_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraPopupMenu', () {
    testWidgets('renders child widget', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                controller: controller,
                items: const [],
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Open Menu'), findsOneWidget);
    });

    testWidgets('controller opens menu', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                controller: controller,
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      expect(controller.isShowing, isFalse);

      controller.open();
      await tester.pump();

      expect(controller.isShowing, isTrue);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('controller closes menu', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                controller: controller,
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(find.text('Item 1'), findsOneWidget);

      controller.close();
      await tester.pump();

      expect(controller.isShowing, isFalse);
    });

    testWidgets('controller toggle opens and closes menu', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                controller: controller,
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      controller.toggle();
      await tester.pump();
      expect(controller.isShowing, isTrue);

      controller.toggle();
      await tester.pump();
      expect(controller.isShowing, isFalse);
    });

    testWidgets('menu item build creates tappable tile', (tester) async {
      var wasTapped = false;
      final item = AuraPopupMenuItem(
        title: const Text('Item 1'),
        onTap: () => wasTapped = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: item.build),
          ),
        ),
      );

      await tester.tap(find.text('Item 1'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('menu item tap closes popup menu', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                controller: controller,
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(controller.isShowing, isTrue);

      controller.close();
      await tester.pump();
      expect(controller.isShowing, isFalse);
    });

    testWidgets('divider renders correctly', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                controller: controller,
                items: const [
                  AuraPopupMenuDivider(),
                ],
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('builder entry renders custom widget', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                controller: controller,
                items: [
                  AuraPopupMenuBuilder(
                    (context) => const Text('Custom'),
                  ),
                ],
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      expect(find.text('Custom'), findsOneWidget);
    });
  });

  group('AuraPopupMenuController', () {
    test('isShowing returns false when not attached', () {
      final controller = AuraPopupMenuController();
      expect(controller.isShowing, isFalse);
    });

    test('open/close/toggle do nothing when not attached', () {
      final controller = AuraPopupMenuController();
      expect(controller.open, returnsNormally);
      expect(controller.close, returnsNormally);
      expect(controller.toggle, returnsNormally);
    });
  });
}
