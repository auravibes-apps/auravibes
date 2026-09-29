import 'package:auravibes_app/widgets/sheets/spring_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _sheetBodyKey = ValueKey<String>('sheet_body');
const _sheetRootKey = ValueKey<String>('sheet_root');
const _returnButtonKey = ValueKey<String>('return_result');
const _surfaceSize = Size(400, 800);
const _belowClosePosition = 0.4;
const _aboveClosePosition = 0.6;
const _smallDragRatio = 0.15;
const _flingDragRatio = 0.4;
const _overdragStepRatio = 0.15;
const _fastFlingHeightsPerSecond = 4.0;

class const _Subject() extends StatefulWidget {
  @override
  State<_Subject> createState() => _SubjectState();
}

class _SubjectState extends State<_Subject> {
  String? _result;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisSize: .min,
            children: [
              Text(_result ?? 'not dismissed', key: const ValueKey('result')),
              TextButton(
                onPressed: () => _openSheet(context),
                child: const Text('Open sheet'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _openSheet(BuildContext context) async {
    final result = await SpringBottomSheet.show<String>(
      context: context,
      builder: (context) => const _Sheet(),
    );
    if (!mounted) return;
    setState(() => _result = result ?? 'dismissed');
  }
}

class const _Sheet() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    key: _sheetRootKey,
    mainAxisSize: .min,
    children: [
      const SizedBox(
        key: _sheetBodyKey,
        height: 180,
        child: Center(child: Text('Sheet body')),
      ),
      TextButton(
        key: _returnButtonKey,
        onPressed: () => Navigator.of(context).pop('selected'),
        child: const Text('Return result'),
      ),
    ],
  );
}

Future<void> _pumpSubject(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const _Subject());
}

Future<Rect> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open sheet'));
  final _ = await tester.pumpAndSettle();

  return tester.getRect(find.byKey(_sheetRootKey));
}

Future<void> _drag(
  WidgetTester tester, {
  required double verticalDistance,
  bool cancel = false,
}) async {
  final rect = tester.getRect(find.byKey(_sheetRootKey));
  final gesture = await tester.startGesture(rect.center);
  await gesture.moveBy(.new(0, verticalDistance));
  if (cancel) {
    await gesture.cancel();
  } else {
    await gesture.up();
  }
  final _ = await tester.pumpAndSettle();
}

Future<void> _fling(
  WidgetTester tester,
  Rect rect, {
  required bool downward,
}) async {
  await tester.flingFrom(
    rect.center,
    .new(0, rect.height * _flingDragRatio * (downward ? 1 : -1)),
    rect.height * _fastFlingHeightsPerSecond,
  );
  final _ = await tester.pumpAndSettle();
}

void main() {
  testWidgets('returns the value passed to Navigator.pop', (tester) async {
    await _pumpSubject(tester);
    final _ = await _openSheet(tester);

    await tester.tap(find.byKey(_returnButtonKey));
    final _ = await tester.pumpAndSettle();

    expect(find.byKey(_sheetRootKey), findsNothing);
    expect(find.text('selected'), findsOneWidget);
  });

  testWidgets('slow drag below half height settles open', (tester) async {
    await _pumpSubject(tester);
    final rect = await _openSheet(tester);

    await _drag(tester, verticalDistance: rect.height * _belowClosePosition);

    expect(find.byKey(_sheetRootKey), findsOneWidget);
  });

  testWidgets('slow drag past half height closes', (tester) async {
    await _pumpSubject(tester);
    final rect = await _openSheet(tester);

    await _drag(tester, verticalDistance: rect.height * _aboveClosePosition);

    expect(find.byKey(_sheetRootKey), findsNothing);
    expect(find.text('dismissed'), findsOneWidget);
  });

  testWidgets('fast downward fling closes before half height', (tester) async {
    await _pumpSubject(tester);
    final rect = await _openSheet(tester);

    await _fling(tester, rect, downward: true);

    expect(find.byKey(_sheetRootKey), findsNothing);
  });

  testWidgets('fast upward fling keeps sheet open', (tester) async {
    await _pumpSubject(tester);
    final rect = await _openSheet(tester);

    await _fling(tester, rect, downward: false);

    expect(find.byKey(_sheetRootKey), findsOneWidget);
  });

  testWidgets('cancelled drag settles back open', (tester) async {
    await _pumpSubject(tester);
    final rect = await _openSheet(tester);

    await _drag(
      tester,
      verticalDistance: rect.height * _smallDragRatio,
      cancel: true,
    );

    expect(find.byKey(_sheetRootKey), findsOneWidget);
  });

  testWidgets('overdrag settles back to the open position', (tester) async {
    await _pumpSubject(tester);
    final initialRect = await _openSheet(tester);
    final gesture = await tester.startGesture(initialRect.center);
    final step = initialRect.height * _overdragStepRatio;

    await gesture.moveBy(.new(0, -step));
    final _ = await tester.pump();
    await gesture.moveBy(.new(0, -step));
    final _ = await tester.pump();
    await gesture.up();
    final _ = await tester.pumpAndSettle();

    expect(find.byKey(_sheetRootKey), findsOneWidget);
    expect(
      tester.getRect(find.byKey(_sheetRootKey)).top,
      closeTo(initialRect.top, 1),
    );
  });

  testWidgets('barrier tap dismisses sheet', (tester) async {
    await _pumpSubject(tester);
    final _ = await _openSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    final _ = await tester.pumpAndSettle();

    expect(find.byKey(_sheetRootKey), findsNothing);
  });

  testWidgets('system back dismisses sheet', (tester) async {
    await _pumpSubject(tester);
    final _ = await _openSheet(tester);

    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();

    expect(find.byKey(_sheetRootKey), findsNothing);
  });
}
