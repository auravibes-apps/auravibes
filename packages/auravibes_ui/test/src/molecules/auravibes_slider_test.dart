import 'package:auravibes_ui/ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _minValue = 2.0;
const _maxValue = 10.0;
const _sliderWidth = 320.0;
const _narrowSliderWidth = 20.0;

Widget _host(Widget child, {double width = _sliderWidth}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: child),
  ),
);

Widget _app(Widget child) => WidgetsApp(
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  ),
  home: _host(child),
  color: const Color(0xFF000000),
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
    expect(tester.getSemantics(find.byType(AuraSlider)).value, '6.0');
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

  testWidgets('preserves the current value when the layout is too narrow', (
    tester,
  ) async {
    double? changedValue;
    await tester.pumpWidget(
      _host(
        AuraSlider(
          value: 6,
          onChanged: (value) => changedValue = value,
          min: _minValue,
          max: _maxValue,
        ),
        width: _narrowSliderWidth,
      ),
    );

    final gestureDetector = tester.widget<GestureDetector>(
      find.byType(GestureDetector),
    );
    expect(
      tester.getSize(find.byType(GestureDetector)).width,
      _narrowSliderWidth,
    );
    gestureDetector.onTapDown?.call(TapDownDetails(localPosition: Offset.zero));

    expect(changedValue, 6);
  });

  testWidgets('changes value with focused keyboard arrows', (tester) async {
    double? changedValue;
    var currentValue = 6.0;

    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => AuraSlider(
            value: currentValue,
            onChanged: (value) {
              changedValue = value;
              setState(() => currentValue = value);
            },
            min: _minValue,
            max: _maxValue,
          ),
        ),
      ),
    );

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
    await tester.pump();
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight), isTrue);
    expect(changedValue, closeTo(6.4, 0.000001));

    for (var index = 0; index < 20; index++) {
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight), isTrue);
      await tester.pump();
    }
    expect(changedValue, _maxValue);
    expect(currentValue, _maxValue);
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
