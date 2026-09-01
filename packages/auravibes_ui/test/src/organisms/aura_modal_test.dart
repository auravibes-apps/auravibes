import 'package:auravibes_ui/ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraModal', () {
    testWidgets('opens and renders arbitrary content', (tester) async {
      await tester.pumpWidget(
        const _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: Text('Open modal'),
            contentChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Modal heading'),
                Text('Arbitrary modal content'),
              ],
            ),
            barrierLabel: 'Dismiss modal',
          ),
        ),
      );

      expect(find.text('Arbitrary modal content'), findsNothing);

      await tester.tap(find.text('Open modal'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Modal heading'), findsOneWidget);
      expect(find.text('Arbitrary modal content'), findsOneWidget);
    });

    testWidgets('opens when the entry point is an interactive child', (
      tester,
    ) async {
      var entryPointPressed = false;

      await tester.pumpWidget(
        _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: AuraButton(
              onPressed: () => entryPointPressed = true,
              child: const Text('Open modal'),
            ),
            contentChild: const Text('Modal content'),
            barrierLabel: 'Dismiss modal',
          ),
        ),
      );

      expect(tester.getSize(find.byType(AuraButton)).width, lessThan(200));

      await tester.tap(find.text('Open modal'));
      final _ = await tester.pumpAndSettle();

      expect(entryPointPressed, isTrue);
      expect(find.text('Modal content'), findsOneWidget);
    });

    testWidgets('ignores drags and non-primary pointers', (tester) async {
      await tester.pumpWidget(
        const _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: Text('Open modal'),
            contentChild: Text('Modal content'),
            barrierLabel: 'Dismiss modal',
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Open modal')),
      );
      await gesture.moveBy(const Offset(40, 0));
      await gesture.up();
      final _ = await tester.pumpAndSettle();
      expect(find.text('Modal content'), findsNothing);

      await tester.tap(find.text('Open modal'), buttons: kSecondaryButton);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Modal content'), findsNothing);
    });

    testWidgets('does not stack routes on repeated activation', (tester) async {
      await tester.pumpWidget(
        const _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: Text('Open modal'),
            contentChild: Text('Modal content'),
            barrierLabel: 'Dismiss modal',
          ),
        ),
      );

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      final _ = await tester.pumpAndSettle();

      expect(find.text('Modal content'), findsOneWidget);
    });

    testWidgets('preserves the caller theme in the modal route', (
      tester,
    ) async {
      await tester.pumpWidget(
        _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: const Text('Open modal'),
            contentChild: Builder(
              builder: (context) => ColoredBox(
                color: context.auraColors.surface,
                child: const SizedBox(width: 100, height: 100),
                key: const Key('themed-modal-content'),
              ),
            ),
            barrierLabel: 'Dismiss modal',
          ),
          auraTheme: AuraTheme.dark,
        ),
      );

      await tester.tap(find.text('Open modal'));
      final _ = await tester.pumpAndSettle();

      final content = tester.widget<ColoredBox>(
        find.byKey(const Key('themed-modal-content')),
      );
      expect(content.color, AuraTheme.dark.colors.surface);
    });

    testWidgets('dismisses from the barrier', (tester) async {
      await tester.pumpWidget(
        const _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: Text('Open modal'),
            contentChild: Text('Modal content'),
            barrierLabel: 'Dismiss modal',
          ),
        ),
      );

      await tester.tap(find.text('Open modal'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Modal content'), findsOneWidget);

      await tester.tapAt(const Offset(1, 1));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Modal content'), findsNothing);
    });

    testWidgets('supports keyboard activation and Escape dismissal', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: Text('Open modal'),
            contentChild: Text('Modal content'),
            barrierLabel: 'Dismiss modal',
          ),
        ),
      );

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.tab), isTrue);
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.enter), isTrue);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Modal content'), findsOneWidget);

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isTrue);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Modal content'), findsNothing);
    });

    testWidgets('allows content to close the modal route', (tester) async {
      await tester.pumpWidget(
        _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: const Text('Open modal'),
            contentChild: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close modal'),
              ),
            ),
            barrierLabel: 'Dismiss modal',
          ),
        ),
      );

      await tester.tap(find.text('Open modal'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Close modal'), findsOneWidget);

      await tester.tap(find.text('Close modal'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Close modal'), findsNothing);
    });

    testWidgets('exposes entry point and barrier semantics', (tester) async {
      await tester.pumpWidget(
        const _AuraModalTestApp(
          child: AuraModal(
            entryPointChild: Text('Open modal'),
            contentChild: Text('Modal content'),
            barrierLabel: 'Dismiss modal',
            semanticLabel: 'Modal dialog',
          ),
        ),
      );

      final entryPoint = tester
          .getSemantics(find.text('Open modal'))
          .getSemanticsData();
      expect(entryPoint.flagsCollection.isButton, isTrue);
      expect(entryPoint.hasAction(SemanticsAction.tap), isTrue);

      await tester.tap(find.text('Open modal'));
      final _ = await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Dismiss modal'), findsOneWidget);
      expect(find.bySemanticsLabel('Modal dialog'), findsOneWidget);
    });
  });
}

class const _AuraModalTestApp({
  required final Widget child,
  final AuraTheme? auraTheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Theme(
          data: ThemeData(extensions: [auraTheme ?? AuraTheme.light]),
          child: child,
        ),
      ),
    );
  }
}
