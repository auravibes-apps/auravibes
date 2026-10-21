import 'dart:ui' as ui show PointerDeviceKind;

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds a horizontal edge mask', (tester) async {
    await _pumpEdgy(
      tester,
      const AuraEdgy(child: Text('content'), axis: .horizontal),
    );

    _expectShaderMask(tester);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('builds a vertical edge mask', (tester) async {
    await _pumpEdgy(tester, const AuraEdgy(child: Text('content')));

    _expectShaderMask(tester);
  });

  testWidgets('fades only edges that hide scrollable content', (tester) async {
    final boundaryKey = GlobalKey();

    Widget content(double width) => MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: 200,
            height: 100,
            child: AuraEdgy(
              child: SingleChildScrollView(
                scrollDirection: .horizontal,
                child: ColoredBox(
                  color: Colors.red,
                  child: SizedBox(width: width, height: 100),
                ),
              ),
              axis: .horizontal,
            ),
          ),
        ),
      ),
    );

    Future<int> edgeAlpha(int x) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final alpha = await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final bytes = await image.toByteData();
          if (bytes == null) throw StateError('Image data is unavailable.');

          return bytes.getUint8((image.width * 50 + x) * 4 + 3);
        } finally {
          image.dispose();
        }
      });

      if (alpha == null) throw StateError('Image capture did not complete.');

      return alpha;
    }

    await tester.pumpWidget(content(200));
    final _ = await tester.pumpAndSettle();
    expect(await edgeAlpha(0), greaterThan(250));
    expect(await edgeAlpha(199), greaterThan(250));

    await tester.pumpWidget(content(400));
    final _ = await tester.pumpAndSettle();
    var horizontal = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(await edgeAlpha(0), greaterThan(250));
    expect(await edgeAlpha(199), lessThan(30));

    horizontal.position.jumpTo(horizontal.position.maxScrollExtent / 2);
    await tester.pump();
    expect(await edgeAlpha(0), lessThan(30));
    expect(await edgeAlpha(199), lessThan(30));

    horizontal.position.jumpTo(horizontal.position.maxScrollExtent);
    await tester.pump();
    expect(await edgeAlpha(0), lessThan(30));
    expect(await edgeAlpha(199), greaterThan(250));

    await tester.pumpWidget(content(200));
    final _ = await tester.pumpAndSettle();
    horizontal = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(horizontal.position.maxScrollExtent, 0);
    expect(await edgeAlpha(0), greaterThan(250));
    expect(await edgeAlpha(199), greaterThan(250));
  });

  testWidgets('supports a one-sided edge mask', (tester) async {
    await _pumpEdgy(
      tester,
      const AuraEdgy(
        child: Text('content'),
        axis: .horizontal,
        fadeStart: false,
      ),
    );

    _expectShaderMask(tester);
  });

  testWidgets('keeps mouse dragging opt-in', (tester) async {
    await _pumpEdgy(
      tester,
      const AuraEdgy(
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          child: SizedBox(width: 400),
        ),
      ),
    );

    final scrollable = tester.element(find.byType(Scrollable));
    final dragDevices = ScrollConfiguration.of(scrollable).dragDevices;

    expect(dragDevices, isNot(contains(ui.PointerDeviceKind.mouse)));
  });

  testWidgets('opts descendants into mouse dragging', (tester) async {
    await _pumpEdgy(
      tester,
      const AuraEdgy(
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          child: SizedBox(width: 400),
        ),
        allowMouseDrag: true,
      ),
    );

    final scrollable = tester.element(find.byType(Scrollable));
    final dragDevices = ScrollConfiguration.of(scrollable).dragDevices;

    expect(dragDevices, contains(ui.PointerDeviceKind.mouse));
    expect(dragDevices, contains(ui.PointerDeviceKind.touch));
  });
}

Future<void> _pumpEdgy(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(child: SizedBox(width: 200, height: 100, child: child)),
    ),
  );
}

void _expectShaderMask(WidgetTester tester) {
  final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));

  expect(mask.blendMode, BlendMode.dstIn);
  expect(
    mask.shaderCallback(const Rect.fromLTWH(0, 0, 200, 100)),
    isA<Shader>(),
  );
}
