import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
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
