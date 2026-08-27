import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _minValue = 2.0;
const _maxValue = 10.0;
const _sliderWidth = 320.0;

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: SizedBox(width: _sliderWidth, child: child),
);

void main() {
  testWidgets('renders custom painted slider with Aura tint', (tester) async {
    await tester.pumpWidget(
      _host(
        AuraSlider(
          value: 6,
          onChanged: (value) => expect(value, isA<double>()),
          min: _minValue,
          max: _maxValue,
          tint: AuraTint.error,
        ),
      ),
    );

    expect(find.byType(AuraSlider), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
    expect(
      tester.widget<AuraSlider>(find.byType(AuraSlider)).tint,
      AuraTint.error,
    );
  });

  testWidgets('forwards values from pointer changes', (tester) async {
    double? changedValue;
    await tester.pumpWidget(
      _host(
        AuraSlider(
          value: 6,
          onChanged: (value) => changedValue = value,
          min: _minValue,
          max: _maxValue,
        ),
      ),
    );

    final gestureDetector = tester.widget<GestureDetector>(
      find.byType(GestureDetector),
    );
    final width = tester.getSize(find.byType(GestureDetector)).width;
    gestureDetector.onTapDown?.call(
      TapDownDetails(localPosition: Offset(width, 24)),
    );

    expect(changedValue, _maxValue);
  });

  testWidgets('exposes semantic label and disabled state', (tester) async {
    await tester.pumpWidget(
      _host(
        AuraSlider(
          value: 6,
          onChanged: (value) => expect(value, isA<double>()),
          min: _minValue,
          max: _maxValue,
          enabled: false,
          semanticLabel: 'Volume',
        ),
      ),
    );

    final focusable = tester.widget<FocusableActionDetector>(
      find.byType(FocusableActionDetector),
    );
    final gestureDetector = tester.widget<GestureDetector>(
      find.byType(GestureDetector),
    );

    expect(
      tester.getSemantics(find.byType(AuraSlider)),
      matchesSemantics(label: 'Volume', isSlider: true, hasEnabledState: true),
    );
    expect(focusable.enabled, isFalse);
    expect(gestureDetector.onTapDown, isNull);
    expect(gestureDetector.onHorizontalDragUpdate, isNull);
  });

  testWidgets('shows a focus ring when focused', (tester) async {
    await tester.pumpWidget(
      _host(
        AuraSlider(
          value: 6,
          onChanged: (value) => expect(value, isA<double>()),
          min: _minValue,
          max: _maxValue,
        ),
      ),
    );

    final focusable = tester.widget<FocusableActionDetector>(
      find.byType(FocusableActionDetector),
    );
    expect(
      tester.widget<CustomPaint>(find.byType(CustomPaint)).foregroundPainter,
      isNull,
    );

    focusable.onShowFocusHighlight?.call(true);
    await tester.pump();

    expect(
      tester.widget<CustomPaint>(find.byType(CustomPaint)).foregroundPainter,
      isNotNull,
    );

    focusable.onShowFocusHighlight?.call(false);
    await tester.pump();

    expect(
      tester.widget<CustomPaint>(find.byType(CustomPaint)).foregroundPainter,
      isNull,
    );
  });

  testWidgets('clamps invalid values and pointer boundaries', (tester) async {
    double? changedValue;
    await tester.pumpWidget(
      _host(
        AuraSlider(
          value: 1,
          onChanged: (value) => changedValue = value,
          min: _minValue,
          max: _maxValue,
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
    expect(tester.getSemantics(find.byType(AuraSlider)).value, '2.0');

    final gestureDetector = tester.widget<GestureDetector>(
      find.byType(GestureDetector),
    );
    gestureDetector.onTapDown?.call(
      TapDownDetails(localPosition: const Offset(0, 24)),
    );
    expect(changedValue, _minValue);

    gestureDetector.onTapDown?.call(
      TapDownDetails(
        localPosition: Offset(
          tester.getSize(find.byType(GestureDetector)).width,
          24,
        ),
      ),
    );
    expect(changedValue, _maxValue);
  });

  test('rejects inverted bounds', () {
    expect(
      () => AuraSlider(value: 0, onChanged: null, min: 1, max: 0),
      throwsA(isA<AssertionError>()),
    );
  });
}
