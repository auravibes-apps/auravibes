import 'package:auravibes_app/features/chats/widgets/responsive_conversation_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget testApp({
    required bool sidePanelVisible,
    required bool sidePanelMounted,
    double sidePanelWidthPercent = 0.4,
    ValueChanged<double> onWidthChanged = _ignoreWidth,
    VoidCallback onClose = _ignoreClose,
    bool isRightToLeft = false,
  }) => EasyLocalization(
    child: Builder(
      builder: (context) => MaterialApp(
        home: Directionality(
          textDirection: isRightToLeft ? .rtl : .ltr,
          child: Scaffold(
            body: ResponsiveConversationLayout(
              mainContent: const SizedBox.expand(
                key: ValueKey('chat_panel'),
                child: Center(child: Text('chat')),
              ),
              sidePanel: .new(
                visible: sidePanelVisible,
                mounted: sidePanelMounted,
                widthPercent: sidePanelWidthPercent,
                onWidthChanged: onWidthChanged,
                onClose: onClose,
                builder: () => const SizedBox.expand(
                  key: ValueKey('sidebar_panel'),
                  child: Center(child: Text('sidebar')),
                ),
              ),
            ),
          ),
        ),
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'unused',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
    assetLoader: const _TestTranslations(),
  );

  testWidgets('shows chat and panel together only when content is wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpTestApp(
      tester,
      testApp(sidePanelVisible: false, sidePanelMounted: false),
    );
    expect(find.text('sidebar', skipOffstage: false), findsNothing);

    await _pumpTestApp(
      tester,
      testApp(sidePanelVisible: true, sidePanelMounted: true),
    );

    final chatRect = tester.getRect(find.text('chat'));
    final sidebarRect = tester.getRect(find.text('sidebar'));
    expect(chatRect.right, lessThan(sidebarRect.left));

    tester.view.physicalSize = const Size(900, 800);
    await tester.pump();

    expect(find.text('sidebar'), findsOneWidget);
    expect(find.text('chat'), findsNothing);

    await _pumpTestApp(
      tester,
      testApp(sidePanelVisible: false, sidePanelMounted: true),
    );

    expect(find.text('chat'), findsOneWidget);
    expect(find.text('sidebar'), findsNothing);
    expect(find.text('sidebar', skipOffstage: false), findsOneWidget);
  });

  testWidgets('resizes panel in logical direction and stores percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    double? savedWidthPercent;

    await _pumpTestApp(
      tester,
      testApp(
        sidePanelVisible: true,
        sidePanelMounted: true,
        onWidthChanged: (value) => savedWidthPercent = value,
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('chat_side_panel_resize_handle')),
      const Offset(120, 0),
    );
    await tester.pump();

    expect(savedWidthPercent, closeTo(380 / 1200, 0.001));
    expect(
      tester.getSize(find.byKey(const ValueKey('sidebar_panel'))).width,
      closeTo(380, 0.1),
    );
  });

  testWidgets(
    'keeps chat at minimum width and closes after dragging past threshold',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var closed = false;
      double? savedWidthPercent;

      await _pumpTestApp(
        tester,
        testApp(
          sidePanelVisible: true,
          sidePanelMounted: true,
          sidePanelWidthPercent: 0.8,
          onWidthChanged: (value) => savedWidthPercent = value,
          onClose: () => closed = true,
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('sidebar_panel'))).width,
        719,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('chat_panel'))).width,
        480,
      );

      await tester.drag(
        find.byKey(const ValueKey('chat_side_panel_resize_handle')),
        const Offset(400, 0),
      );
      await tester.pump();

      expect(closed, isTrue);
      expect(savedWidthPercent, isNull);
    },
  );

  testWidgets('keeps browser at minimum width while resizing', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    double? savedWidthPercent;

    await _pumpTestApp(
      tester,
      testApp(
        sidePanelVisible: true,
        sidePanelMounted: true,
        sidePanelWidthPercent: 0.5,
        onWidthChanged: (value) => savedWidthPercent = value,
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('chat_side_panel_resize_handle')),
      const Offset(320, 0),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const ValueKey('sidebar_panel'))).width,
      320,
    );
    expect(savedWidthPercent, closeTo(320 / 1200, 0.001));
  });

  testWidgets('resizes from the panel edge in right-to-left layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    double? savedWidthPercent;

    await _pumpTestApp(
      tester,
      testApp(
        sidePanelVisible: true,
        sidePanelMounted: true,
        isRightToLeft: true,
        onWidthChanged: (value) => savedWidthPercent = value,
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('chat_side_panel_resize_handle')),
      const Offset(-120, 0),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const ValueKey('sidebar_panel'))).width,
      closeTo(380, 0.1),
    );
    expect(savedWidthPercent, closeTo(380 / 1200, 0.001));
  });
}

void _ignoreWidth(double _) => fail('Unexpected panel resize.');

void _ignoreClose() => fail('Unexpected panel close.');

Future<void> _pumpTestApp(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  final _ = await tester.pumpAndSettle();
}

class const _TestTranslations() extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'browser': {
      'resize_handle_tooltip': 'Resize browser side panel',
      'resize_handle_hint': 'Drag horizontally to change the panel width',
    },
  };
}
