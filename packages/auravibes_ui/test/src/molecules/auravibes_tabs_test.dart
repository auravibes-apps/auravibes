import 'dart:ui' show SemanticsRole, Tristate;

import 'package:auravibes_ui/src/atoms/aura_corner_radius_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_container.dart';
import 'package:auravibes_ui/src/molecules/aura_tabs.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTabs', () {
    testWidgets('uses scoped radius for tab surfaces', (tester) async {
      await tester.pumpWidget(
        _host(
          AuraCornerRadiusScope.select(
            level: .xl,
            child: const AuraTabs<void>(items: _items),
          ),
        ),
      );

      final pressable = tester.widget<AuraPressable>(
        find.byType(AuraPressable).first,
      );
      expect(
        pressable.decoration,
        isA<BoxDecoration>().having(
          (decoration) => decoration.borderRadius,
          'borderRadius',
          BorderRadius.circular(AuraTheme.light.fromBorderRadius(.xl)),
        ),
      );
    });

    testWidgets('reveals an initially selected edge tab after route uncover', (
      tester,
    ) async {
      var covered = true;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Navigator(
              pages: [
                const MaterialPage<void>(
                  child: Align(
                    alignment: .centerLeft,
                    child: SizedBox(
                      width: 160,
                      height: 200,
                      child: AuraTabs<void>(items: _wideItems, initialIndex: 4),
                    ),
                  ),
                  key: ValueKey('tabs'),
                ),
                if (covered)
                  MaterialPage<void>(
                    child: Center(
                      child: TextButton(
                        onPressed: () => setState(() => covered = false),
                        child: const Text('Setup'),
                      ),
                    ),
                    key: const ValueKey('setup'),
                  ),
              ],
              onDidRemovePage: (page) {
                if (page.key == const ValueKey('setup')) covered = false;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Setup'), findsOneWidget);

      await tester.tap(find.text('Setup'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Setup'), findsNothing);
      await tester.pump();
      final _ = await tester.pumpAndSettle();

      final tabs = find.byType(AuraTabs<void>);
      final horizontal = tester.state<ScrollableState>(
        find.descendant(of: tabs, matching: find.byType(Scrollable)),
      );
      final viewport = tester.getRect(
        find.descendant(of: tabs, matching: find.byType(SingleChildScrollView)),
      );
      final selectedTab = tester.getRect(
        find.descendant(of: tabs, matching: find.byType(AuraPressable)).last,
      );
      expect(horizontal.position.pixels, greaterThan(0));
      expect(selectedTab.left, greaterThanOrEqualTo(viewport.left));
      expect(selectedTab.right, lessThanOrEqualTo(viewport.right));
    });

    testWidgets('renders tab labels and selected content', (tester) async {
      await tester.pumpWidget(_host(const AuraTabs<void>(items: _items)));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First content'), findsOneWidget);
      expect(find.text('Second content'), findsNothing);
    });

    testWidgets('supports widget titles with custom semantic labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AuraTabs<void>(
            items: [
              AuraTabItem(
                title: Icon(Icons.info),
                child: Text('Information content'),
                semanticLabel: 'Information',
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Information')).role,
        SemanticsRole.tab,
      );
      semantics.dispose();
    });

    testWidgets('uses initial selection', (tester) async {
      await tester.pumpWidget(
        _host(const AuraTabs<void>(items: _items, initialIndex: 1)),
      );

      expect(find.text('First content'), findsNothing);
      expect(find.text('Second content'), findsOneWidget);
    });

    testWidgets('selector emits generic values without rendering children', (
      tester,
    ) async {
      String? selectedValue;
      await tester.pumpWidget(
        _host(
          AuraTabs<String>.selector(
            options: const [
              AuraTabOption(value: 'first', title: Text('First')),
              AuraTabOption(value: 'second', title: Text('Second')),
            ],
            initialValue: 'second',
            onChanged: (value) => selectedValue = value,
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(AuraContainer), findsNothing);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Second').first)
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      await tester.tap(find.text('First'));
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, 'first');
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('First').first)
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
    });

    testWidgets('selector renders no tabs for an empty option list', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AuraTabs<String>.selector(options: [])),
      );

      expect(find.byType(AuraPressable), findsNothing);
      expect(find.byType(AuraText), findsNothing);
    });

    testWidgets('calls onChanged and shows selected content after a tap', (
      tester,
    ) async {
      int? selectedIndex;
      await tester.pumpWidget(
        _host(
          AuraTabs<void>(
            items: _items,
            onChanged: (index) => selectedIndex = index,
          ),
        ),
      );

      await tester.tap(find.text('Second'));
      final _ = await tester.pumpAndSettle();

      expect(selectedIndex, 1);
      expect(find.text('Second content'), findsOneWidget);
    });

    testWidgets('syncs controlled selection without a callback', (
      tester,
    ) async {
      var selectedIndex = 0;
      var callbackCount = 0;

      await tester.pumpWidget(
        _host(
          AuraTabs<void>(
            items: _items,
            selectedIndex: selectedIndex,
            onChanged: (_) => callbackCount++,
          ),
        ),
      );

      selectedIndex = 1;
      await tester.pumpWidget(
        _host(
          AuraTabs<void>(
            items: _items,
            selectedIndex: selectedIndex,
            onChanged: (_) => callbackCount++,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Second content'), findsOneWidget);
      expect(callbackCount, 0);
    });

    testWidgets('uses rendered selection for controlled taps', (tester) async {
      var callbackCount = 0;
      await tester.pumpWidget(
        _host(
          AuraTabs<void>(
            items: _items,
            selectedIndex: 0,
            onChanged: (_) => callbackCount++,
          ),
        ),
      );

      await tester.tap(find.text('Second'));
      await tester.pump();
      await tester.tap(find.text('Second'));

      expect(callbackCount, 2);
      expect(find.text('First content'), findsOneWidget);
      expect(find.text('Second content'), findsNothing);
    });

    testWidgets('clamps invalid selection indexes', (tester) async {
      await tester.pumpWidget(
        _host(const AuraTabs<void>(items: _items, initialIndex: 99)),
      );
      expect(find.text('Second content'), findsOneWidget);

      await tester.pumpWidget(
        _host(const AuraTabs<void>(items: _items, selectedIndex: -1)),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('First content'), findsOneWidget);
    });

    testWidgets('renders no tabs for an empty item list', (tester) async {
      await tester.pumpWidget(_host(const AuraTabs<void>(items: [])));

      expect(find.byType(AuraPressable), findsNothing);
      expect(find.byType(AuraText), findsNothing);
    });

    testWidgets('supports shrink-wrapped layouts', (tester) async {
      await tester.pumpWidget(
        _host(
          const SingleChildScrollView(child: AuraTabs<void>(items: _items)),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('First content'), findsOneWidget);
    });

    testWidgets('reveals an initially selected edge tab without moving page', (
      tester,
    ) async {
      final pageController = ScrollController();
      addTearDown(pageController.dispose);
      await tester.pumpWidget(
        _host(
          ListView(
            controller: pageController,
            children: const [
              SizedBox(height: 120),
              Align(
                alignment: .centerLeft,
                child: SizedBox(
                  width: 160,
                  height: 200,
                  child: AuraTabs<void>(items: _wideItems, initialIndex: 4),
                ),
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final horizontal = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(AuraTabs<void>),
          matching: find.byType(Scrollable),
        ),
      );
      expect(horizontal.position.pixels, greaterThan(0));
      expect(pageController.offset, 0);
    });

    testWidgets('reveals a controlled selection after it changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 160,
            child: AuraTabs<void>(items: _wideItems, selectedIndex: 0),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 160,
            child: AuraTabs<void>(items: _wideItems, selectedIndex: 4),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final horizontal = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(AuraTabs<void>),
          matching: find.byType(Scrollable),
        ),
      );
      expect(horizontal.position.pixels, greaterThan(0));
      expect(find.text('Fifth content'), findsOneWidget);
    });

    testWidgets('reveals a partially visible tab after a tap', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(width: 160, child: AuraTabs<void>(items: _wideItems)),
        ),
      );
      final horizontal = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(AuraTabs<void>),
          matching: find.byType(Scrollable),
        ),
      );
      horizontal.position.jumpTo(horizontal.position.maxScrollExtent - 40);
      await tester.pump();
      final before = horizontal.position.pixels;
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      final lastTab = tester.getRect(find.byType(AuraPressable).last);
      final visiblePart = lastTab.intersect(viewport);
      expect(visiblePart.width, greaterThan(0));
      expect(visiblePart.width, lessThan(lastTab.width));

      await tester.tapAt(visiblePart.center);
      final _ = await tester.pumpAndSettle();

      expect(find.text('Fifth content'), findsOneWidget);
      expect(horizontal.position.pixels, greaterThan(before));
    });

    testWidgets('does not move a tab strip that already fits', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 800,
            child: AuraTabs<void>(items: _wideItems, initialIndex: 4),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final horizontal = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(AuraTabs<void>),
          matching: find.byType(Scrollable),
        ),
      );
      expect(horizontal.position.pixels, 0);
      expect(horizontal.position.maxScrollExtent, 0);
    });

    testWidgets('scrolls an overflowing tab strip with a horizontal drag', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(width: 160, child: AuraTabs<void>(items: _wideItems)),
        ),
      );

      final tabs = find.byType(AuraTabs<void>);
      final horizontal = tester.state<ScrollableState>(
        find.descendant(of: tabs, matching: find.byType(Scrollable)),
      );
      expect(horizontal.position.maxScrollExtent, greaterThan(0));

      final scrollView = find.descendant(
        of: tabs,
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(scrollView, const Offset(-120, 0), kind: .mouse);
      final _ = await tester.pumpAndSettle();

      expect(horizontal.position.pixels, greaterThan(0));
    });

    testWidgets('keeps a selected tab visible when items shrink in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Directionality(
            textDirection: .rtl,
            child: SizedBox(
              width: 160,
              child: AuraTabs<void>(items: _wideItems, selectedIndex: 4),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.pumpWidget(
        _host(
          const Directionality(
            textDirection: .rtl,
            child: SizedBox(
              width: 160,
              child: AuraTabs<void>(items: _items, selectedIndex: 1),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Second content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses initial selection when items become available', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AuraTabs<void>(items: [])));
      await tester.pumpWidget(
        _host(const AuraTabs<void>(items: _items, initialIndex: 1)),
      );

      expect(find.text('Second content'), findsOneWidget);
    });

    testWidgets('supports keyboard activation and tab semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      int? selectedIndex;
      await tester.pumpWidget(
        _host(
          AuraTabs<void>(
            items: _items,
            onChanged: (index) => selectedIndex = index,
          ),
        ),
      );

      final firstTab = tester.getSemantics(
        find.bySemanticsLabel('First').first,
      );
      expect(firstTab.role, SemanticsRole.tab);
      expect(firstTab.flagsCollection.isSelected, Tristate.isTrue);

      expect(await tester.sendKeyEvent(.tab), isTrue);
      expect(await tester.sendKeyEvent(.tab), isTrue);
      expect(await tester.sendKeyEvent(.enter), isTrue);
      final _ = await tester.pumpAndSettle();

      expect(selectedIndex, 1);
      semantics.dispose();
    });

    testWidgets('uses Aura theme colors for tab styling', (tester) async {
      await tester.pumpWidget(_host(const AuraTabs<void>(items: _items)));

      final pressables = tester.widgetList<AuraPressable>(
        find.byType(AuraPressable),
      );
      expect(
        pressables.every((tab) => tab.color == AuraTheme.light.colors.primary),
        isTrue,
      );
      expect(
        pressables.every((tab) {
          final decoration = tab.decoration;

          return decoration is BoxDecoration &&
              decoration.borderRadius ==
                  BorderRadius.circular(AuraTheme.light.fromBorderRadius(.md));
        }),
        isTrue,
      );

      final labels = tester.widgetList<AuraText>(find.byType(AuraText));
      expect(labels.firstOrNull?.tint, AuraTint.primary);
      expect(labels.lastOrNull?.tint, isNull);
    });

    testWidgets('keeps tab targets and indicators sized to each tab', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AuraTabs<void>(items: _items)));

      final firstTab = find.byType(AuraPressable).first;
      final firstStateLayer = find.descendant(
        of: firstTab,
        matching: find.byType(AnimatedContainer),
      );
      final firstIndicator = find.byKey(
        const ValueKey('aura-tabs-indicator-0'),
      );

      expect(tester.getSize(firstTab).height, 48);
      final tabs = find.byType(AuraPressable);
      for (var index = 0; index < tabs.evaluate().length; index++) {
        expect(tester.getSize(tabs.at(index)).width, greaterThanOrEqualTo(48));
      }
      expect(tester.getSize(firstIndicator).height, 2);
      expect(
        tester.getSize(firstIndicator).width,
        tester.getSize(firstTab).width,
      );
      expect(
        tester.getSize(firstStateLayer).width,
        tester.getSize(firstIndicator).width,
      );
      expect(
        _indicatorColor(tester, firstIndicator),
        AuraTheme.light.colors.primary,
      );
      expect(
        _indicatorColor(
          tester,
          find.byKey(const ValueKey('aura-tabs-indicator-1')),
        ).a,
        0,
      );
    });

    testWidgets('keeps selection when another tab is hovered', (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy = .alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );

      await tester.pumpWidget(
        _host(const AuraTabs<void>(items: _items, initialIndex: 1)),
      );

      final gesture = await tester.createGesture(kind: .mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.text('First')));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Second content'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('First').first)
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Second').first)
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
    });

    testWidgets('updates the indicator when ticker mode is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const TickerMode(
            enabled: false,
            child: AuraTabs<void>(items: _items),
          ),
        ),
      );

      await tester.tap(find.text('Second'));
      await tester.pump();

      expect(
        _indicatorColor(
          tester,
          find.byKey(const ValueKey('aura-tabs-indicator-0')),
        ).a,
        0,
      );
      expect(
        _indicatorColor(
          tester,
          find.byKey(const ValueKey('aura-tabs-indicator-1')),
        ),
        AuraTheme.light.colors.primary,
      );
    });
  });
}

const _items = [
  AuraTabItem(title: Text('First'), child: Text('First content')),
  AuraTabItem(title: Text('Second'), child: Text('Second content')),
];

const _wideItems = [
  AuraTabItem(title: Text('First'), child: Text('First content')),
  AuraTabItem(title: Text('Second'), child: Text('Second content')),
  AuraTabItem(title: Text('Third'), child: Text('Third content')),
  AuraTabItem(title: Text('Fourth'), child: Text('Fourth content')),
  AuraTabItem(title: Text('Fifth'), child: Text('Fifth content')),
];

Widget _host(Widget child) {
  return AuraThemeScope(
    theme: .light,
    child: MaterialApp(
      home: Scaffold(body: SizedBox(height: 240, child: child)),
      theme: .new(),
    ),
  );
}

Color _indicatorColor(WidgetTester tester, Finder finder) {
  final layer = tester.widget<AnimatedContainer>(finder);
  // AnimatedContainer's color shorthand is normalized into decoration.
  final decoration = layer.decoration;
  if (decoration is BoxDecoration) {
    final color = decoration.color;
    if (color != null) return color;
  }

  fail('Expected a colored tab indicator.');
}
