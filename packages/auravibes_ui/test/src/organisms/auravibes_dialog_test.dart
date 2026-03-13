import 'package:auravibes_ui/src/molecules/auravibes_button.dart';
import 'package:auravibes_ui/src/organisms/auravibes_dialog.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper to create a widget with Aura theme
Widget wrapWithAuraTheme(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [AuraTheme.light],
    ),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('AuraConfirmDialog', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          const AuraConfirmDialog(
            title: Text('Confirm Action'),
            message: Text('Are you sure you want to proceed?'),
          ),
        ),
      );

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
    });

    testWidgets('displays confirm and cancel buttons', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          const AuraConfirmDialog(
            title: Text('Delete Item'),
            message: Text('This action cannot be undone.'),
          ),
        ),
      );

      // Find the action buttons (default labels)
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('applies destructive styling when isDestructive is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          const AuraConfirmDialog(
            title: Text('Delete'),
            message: Text('Are you sure?'),
            isDestructive: true,
          ),
        ),
      );

      // The confirm button should have error styling
      final confirmButton = find.byWidgetPredicate(
        (widget) {
          if (widget is AuraButton) {
            final button = widget;
            return button.colorVariant == AuraColorVariant.error;
          }
          return false;
        },
      );

      expect(confirmButton, findsOneWidget);
    });

    testWidgets('uses custom labels when provided', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          const AuraConfirmDialog(
            title: Text('Custom Title'),
            message: Text('Custom message'),
            confirmLabel: Text('Yes'),
            cancelLabel: Text('No'),
          ),
        ),
      );

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('calls onConfirm when confirm button tapped', (tester) async {
      var confirmCalled = false;

      await tester.pumpWidget(
        wrapWithAuraTheme(
          AuraConfirmDialog(
            title: const Text('Dialog Title'),
            message: const Text('Message'),
            onConfirm: () {
              confirmCalled = true;
            },
          ),
        ),
      );

      // Use widget type finder to avoid matching title text
      final confirmButtons = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'Confirm',
      );
      await tester.tap(confirmButtons);
      await tester.pump();

      expect(confirmCalled, isTrue);
    });

    testWidgets('calls onCancel when cancel button tapped', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        wrapWithAuraTheme(
          AuraConfirmDialog(
            title: const Text('Dialog Title'),
            message: const Text('Message'),
            onCancel: () {
              cancelCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelCalled, isTrue);
    });
  });

  group('AuraAlertDialog', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          const AuraAlertDialog(
            title: Text('Alert'),
            message: Text('Something happened.'),
          ),
        ),
      );

      expect(find.text('Alert'), findsOneWidget);
      expect(find.text('Something happened.'), findsOneWidget);
    });

    testWidgets('displays dismiss button with default label', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          const AuraAlertDialog(
            title: Text('Alert'),
            message: Text('Message'),
          ),
        ),
      );

      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('uses custom dismiss label when provided', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          const AuraAlertDialog(
            title: Text('Alert'),
            message: Text('Message'),
            dismissLabel: Text('Got it'),
          ),
        ),
      );

      expect(find.text('Got it'), findsOneWidget);
    });
  });

  group('showAuraConfirmDialog', () {
    testWidgets('shows dialog and returns true when confirmed', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                dialogResult = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Dialog Title'),
                  message: const Text('Are you sure?'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog should be visible (custom Container dialog)
      expect(find.byType(AuraConfirmDialog), findsOneWidget);

      // Use widget type finder to avoid matching title
      final confirmButtons = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'Confirm',
      );
      await tester.tap(confirmButtons);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AuraConfirmDialog), findsNothing);
      expect(dialogResult, isTrue);
    });

    testWidgets('shows dialog and returns false when cancelled', (
      tester,
    ) async {
      bool? dialogResult;

      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                dialogResult = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Dialog Title'),
                  message: const Text('Are you sure?'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.byType(AuraConfirmDialog), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AuraConfirmDialog), findsNothing);
      expect(dialogResult, isFalse);
    });
  });

  group('showAuraAlertDialog', () {
    testWidgets('shows dialog and dismisses on button tap', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showAuraAlertDialog(
                  context: context,
                  title: const Text('Alert'),
                  message: const Text('This is an alert.'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AuraAlertDialog), findsOneWidget);

      // Tap dismiss
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AuraAlertDialog), findsNothing);
    });
  });

  group('Custom Dialog Implementation', () {
    testWidgets('showAuraConfirmDialog does NOT use AlertDialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Title'),
                  message: const Text('Message'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The dialog should NOT use Material's AlertDialog
      expect(find.byType(AlertDialog), findsNothing);

      // Instead, it should use a custom Container
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('showAuraAlertDialog does NOT use AlertDialog', (tester) async {
      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showAuraAlertDialog(
                  context: context,
                  title: const Text('Alert'),
                  message: const Text('Message'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The dialog should NOT use Material's AlertDialog
      expect(find.byType(AlertDialog), findsNothing);

      // Instead, it should use a custom Container
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('showAuraConfirmDialog returns true on confirm', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Title'),
                  message: const Text('Message'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('showAuraConfirmDialog returns false on cancel', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Title'),
                  message: const Text('Message'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('showAuraConfirmDialog supports barrierDismissible', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        wrapWithAuraTheme(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Title'),
                  message: const Text('Message'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap outside the dialog (barrier)
      await tester.tap(find.byType(ModalBarrier).last);
      await tester.pumpAndSettle();

      // Dialog should be dismissed and result should be null
      expect(result, isNull);
    });
  });
}
