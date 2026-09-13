import 'dart:ui' as ui;

import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/molecules/aura_card.dart';
import 'package:auravibes_ui/src/organisms/aura_popup_menu_controller.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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
                items: const [AuraPopupMenuItem(title: Text('Item 1'))],
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
                items: const [AuraPopupMenuItem(title: Text('Item 1'))],
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
                items: const [AuraPopupMenuItem(title: Text('Item 1'))],
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

    testWidgets('menu item build creates tappable row', (tester) async {
      var wasTapped = false;
      final item = AuraPopupMenuItem(
        title: const Text('Item 1'),
        onTap: () => wasTapped = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: item.build)),
        ),
      );

      await tester.tap(find.text('Item 1'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('menu item with no callback renders disabled', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: const AuraPopupMenuItem(title: Text('Item 1')).build,
            ),
          ),
        ),
      );

      expect(find.byType(AuraPressable), findsOneWidget);
      final itemSemantics = tester
          .getSemantics(find.text('Item 1'))
          .getSemanticsData();
      expect(itemSemantics.flagsCollection.isButton, isTrue);
      expect(itemSemantics.flagsCollection.isEnabled, ui.Tristate.isFalse);
      semantics.dispose();
    });

    testWidgets('disabled menu item does not invoke or close menu', (
      tester,
    ) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: Center(
                child: AuraPopupMenu(
                  child: const Text('Open Menu'),
                  items: const [AuraPopupMenuItem(title: Text('Disabled'))],
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(controller.isShowing, isTrue);
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('disabled rows keep full width without a background', (
      tester,
    ) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuItem(title: Text('Enabled'), onTap: _noop),
                  AuraPopupMenuItem(title: Text('Disabled 1')),
                  AuraPopupMenuItem(title: Text('Disabled 2')),
                ],
                controller: controller,
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      final menuRect = tester.getRect(find.byType(AuraCard));
      final enabledRect = _menuItemRect(tester, 'Enabled');
      final disabledOneRect = _menuItemRect(tester, 'Disabled 1');
      final disabledTwoRect = _menuItemRect(tester, 'Disabled 2');

      expect(enabledRect.width, closeTo(menuRect.width - 2, 1));
      expect(disabledOneRect.width, closeTo(enabledRect.width, 1));
      expect(disabledOneRect.left, closeTo(enabledRect.left, 1));
      expect(disabledTwoRect.left, closeTo(enabledRect.left, 1));
      expect(disabledTwoRect.top, closeTo(disabledOneRect.bottom, 1));
      final disabledPressable = tester.widget<AuraPressable>(
        find
            .ancestor(
              of: find.text('Disabled 1'),
              matching: find.byType(AuraPressable),
            )
            .first,
      );
      expect(disabledPressable.decoration, isNull);
    });

    testWidgets('disabled rows use readable disabled colors for content', (
      tester,
    ) async {
      const leadingKey = ValueKey<String>('disabled-leading');
      const trailingKey = ValueKey<String>('disabled-trailing');
      final disabledColor = AuraTheme.light.colors.onSurfaceVariant.withValues(
        alpha: 0.6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: const AuraPopupMenuItem(
                title: Text('Disabled'),
                leading: Icon(Icons.info_outline, key: leadingKey),
                trailing: Icon(Icons.chevron_right, key: trailingKey),
              ).build,
            ),
          ),
        ),
      );

      final defaultTextStyle = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Disabled'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      final iconTheme = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byKey(leadingKey),
              matching: find.byType(IconTheme),
            )
            .first,
      );

      expect(defaultTextStyle.style.color, disabledColor);
      expect(iconTheme.data.color, disabledColor);
      expect(find.byKey(trailingKey), findsOneWidget);
    });

    testWidgets('trailing content is aligned to the row end', (tester) async {
      final controller = AuraPopupMenuController();
      const trailingKey = ValueKey<String>('trailing');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuItem(
                    title: Text('Item'),
                    onTap: _noop,
                    trailing: SizedBox(key: trailingKey, width: 20, height: 20),
                  ),
                ],
                controller: controller,
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      final rowRect = _menuItemRect(tester, 'Item');
      final trailingRect = tester.getRect(find.byKey(trailingKey));

      expect(trailingRect.right, closeTo(rowRect.right - 16, 1));
    });

    testWidgets('menu width grows beyond the old fixed width', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                child: const Text('Open Menu'),
                items: const [
                  AuraPopupMenuItem(
                    title: Text(
                      'A label that needs more than two hundred pixels',
                    ),
                    onTap: _noop,
                  ),
                ],
                controller: controller,
              ),
            ),
          ),
        ),
      );

      controller.open();
      await tester.pump();

      final menuWidth = tester.getRect(find.byType(AuraCard)).width;
      expect(menuWidth, greaterThan(200));
      expect(menuWidth, lessThanOrEqualTo(320));
    });

    testWidgets('popup menu items hide when controller closes', (tester) async {
      final controller = AuraPopupMenuController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Portal(
              child: AuraPopupMenu(
                child: const Text('Open Menu'),
                items: const [AuraPopupMenuItem(title: Text('Item 1'))],
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
                  items: const [AuraPopupMenuItem(title: Text('Item 1'))],
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
                items: const [AuraPopupMenuDivider()],
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
                items: [AuraPopupMenuItem(title: Text('Edit'))],
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
                    items: const [AuraPopupMenuItem(title: Text('Item 1'))],
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

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();
      expect(controller.isShowing, isFalse);

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(.enter), isTrue);
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

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(.enter), isTrue);
      await tester.pump();
      await tester.pump();
      expect(controller.isShowing, isTrue);

      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();
      expect(await tester.sendKeyEvent(.tab), isTrue);
      await tester.pump();

      expect(await tester.sendKeyEvent(.enter), isTrue);
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

Rect _menuItemRect(WidgetTester tester, String title) => tester.getRect(
  find
      .ancestor(of: find.text(title), matching: find.byType(AuraPressable))
      .first,
);

void _noop() => Object();
