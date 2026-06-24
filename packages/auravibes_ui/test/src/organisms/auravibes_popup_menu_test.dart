import 'package:auravibes_ui/src/organisms/aura_popup_menu_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                child: const Text('Open Menu'),
                items: const [],
                controller: controller,
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
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                controller: controller,
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
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                controller: controller,
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
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                controller: controller,
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

    testWidgets('popup menu items hide when controller closes', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuItem(title: Text('Item 1')),
                ],
                controller: controller,
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(controller.isShowing, isTrue);
      expect(find.text('Item 1'), findsOneWidget);

      controller.close();
      await tester.pump();

      expect(controller.isShowing, isFalse);
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('closes when tapping outside menu', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Center(
                child: AuraPopupMenu(
                  child: const Text('Open Menu'),
                  items: const [
                    AuraPopupMenuItem(title: Text('Item 1')),
                  ],
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      expect(controller.isShowing, isTrue);
      expect(find.text('Item 1'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(controller.isShowing, isFalse);
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('menu item tap works while outside dismissal is active', (
      tester,
    ) async {
      var wasTapped = false;
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Center(
                child: AuraPopupMenu(
                  child: const Text('Open Menu'),
                  items: [
                    AuraPopupMenuItem(
                      title: const Text('Item 1'),
                      onTap: () => wasTapped = true,
                    ),
                  ],
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      await tester.tap(find.text('Item 1'));
      await tester.pump();

      expect(wasTapped, isTrue);
      expect(controller.isShowing, isFalse);
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('divider renders correctly', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuDivider(),
                ],
                controller: controller,
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('button opens popup menu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenuButton(
                items: [
                  AuraPopupMenuItem(title: Text('Edit')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraPopupMenuButton));
      await tester.pump();

      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('tab from popup trigger moves to next visible button', (
      tester,
    ) async {
      var nextPressed = false;
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => fail('Before should not be pressed'),
                    child: const Text('Before'),
                  ),
                  AuraPopupMenu(
                    child: TextButton(
                      onPressed: controller.toggle,
                      child: const Text('Menu'),
                    ),
                    items: const [
                      AuraPopupMenuItem(title: Text('Item 1')),
                    ],
                    controller: controller,
                  ),
                  TextButton(
                    onPressed: () => nextPressed = true,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(controller.isShowing, isFalse);

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      await tester.pump();

      expect(nextPressed, isTrue);
    });

    testWidgets('tab loops inside open popup menu', (tester) async {
      String? selectedItem;
      var nextPressed = false;
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => fail('Before should not be pressed'),
                    child: const Text('Before'),
                  ),
                  AuraPopupMenu(
                    child: TextButton(
                      onPressed: controller.toggle,
                      child: const Text('Menu'),
                    ),
                    items: [
                      AuraPopupMenuItem(
                        title: const Text('Item 1'),
                        onTap: () => selectedItem = 'Item 1',
                      ),
                      AuraPopupMenuItem(
                        title: const Text('Item 2'),
                        onTap: () => selectedItem = 'Item 2',
                      ),
                    ],
                    controller: controller,
                  ),
                  TextButton(
                    onPressed: () => nextPressed = true,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      await tester.pump();
      await tester.pump();
      expect(controller.isShowing, isTrue);

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      await tester.pump();

      expect(selectedItem, isNotNull);
      expect(nextPressed, isFalse);
    });
  });

  group('AuraPopupMenuController', () {
    test('isShowing returns false when not attached', () {
      final controller = AuraPopupMenuController();
      expect(controller.isShowing, isFalse);
    });

    test('open/close/toggle do nothing when not attached', () {
      final controller = AuraPopupMenuController();
      expect(controller.isShowing, isFalse);
      controller.open();
      expect(controller.isShowing, isFalse);
      controller.close();
      expect(controller.isShowing, isFalse);
      controller.toggle();
      expect(controller.isShowing, isFalse);
    });
  });
}
