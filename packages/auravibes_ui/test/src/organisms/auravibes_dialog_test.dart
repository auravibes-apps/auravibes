import 'dart:async';

import 'package:auravibes_ui/src/molecules/aura_button.dart';
import 'package:auravibes_ui/src/organisms/aura_confirm_dialog.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper to create a widget with Aura theme.
class AuraThemeWrapper extends StatelessWidget {
  /// Creates an [AuraThemeWrapper].
  const AuraThemeWrapper({required this.child, super.key});

  /// The widget under test.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
      theme: ThemeData(
        extensions: [AuraTheme.light],
      ),
    );
  }
}

/// Finds an [AuraButton] whose child is a [Text] widget with [label].
Finder findAuraButtonByLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is AuraButton &&
        widget.child is Text &&
        (widget.child as Text).data == label,
  );
}

/// Finds an [AuraButton] with the given [AuraColorVariant].
Finder findAuraButtonByColorVariant(AuraColorVariant variant) {
  return find.byWidgetPredicate(
    (widget) => widget is AuraButton && widget.colorVariant == variant,
  );
}

VoidCallback runDialogAction(Future<void> Function() action) {
  return () => unawaited(action());
}

void main() {
  group('AuraConfirmDialog', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        const AuraThemeWrapper(
          child: AuraConfirmDialog(
            title: Text('Confirm Action'),
            message: Text('Are you sure you want to proceed?'),
            confirmLabel: Text('Confirm'),
            cancelLabel: Text('Cancel'),
          ),
        ),
      );

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
    });

    testWidgets('displays confirm and cancel buttons', (tester) async {
      await tester.pumpWidget(
        const AuraThemeWrapper(
          child: AuraConfirmDialog(
            title: Text('Delete Item'),
            message: Text('This action cannot be undone.'),
            confirmLabel: Text('Confirm'),
            cancelLabel: Text('Cancel'),
          ),
        ),
      );

      // Find the action buttons (default labels).
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('applies destructive styling when isDestructive is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const AuraThemeWrapper(
          child: AuraConfirmDialog(
            title: Text('Delete'),
            message: Text('Are you sure?'),
            confirmLabel: Text('Confirm'),
            cancelLabel: Text('Cancel'),
            isDestructive: true,
          ),
        ),
      );

      // The confirm button should have error styling.
      final confirmButton = findAuraButtonByColorVariant(
        AuraColorVariant.error,
      );

      expect(confirmButton, findsOneWidget);
    });

    testWidgets('uses custom labels when provided', (tester) async {
      await tester.pumpWidget(
        const AuraThemeWrapper(
          child: AuraConfirmDialog(
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

    testWidgets('applies custom colorVariant when provided', (tester) async {
      await tester.pumpWidget(
        const AuraThemeWrapper(
          child: AuraConfirmDialog(
            title: Text('Warning'),
            message: Text('Proceed with caution'),
            confirmLabel: Text('Confirm'),
            cancelLabel: Text('Cancel'),
            colorVariant: AuraColorVariant.error,
          ),
        ),
      );

      final confirmButtonFinder = findAuraButtonByLabel('Confirm');
      final confirmButton = tester.widget<AuraButton>(confirmButtonFinder);
      expect(confirmButton.colorVariant, AuraColorVariant.error);
    });

    testWidgets('calls onConfirm when confirm button tapped', (tester) async {
      var confirmCalled = false;

      await tester.pumpWidget(
        AuraThemeWrapper(
          child: AuraConfirmDialog(
            title: const Text('Dialog Title'),
            message: const Text('Message'),
            confirmLabel: const Text('Confirm'),
            cancelLabel: const Text('Cancel'),
            onConfirm: () {
              confirmCalled = true;
            },
          ),
        ),
      );

      // Use widget type finder to avoid matching title text.
      final confirmButton = findAuraButtonByLabel('Confirm');
      await tester.tap(confirmButton);
      await tester.pump();

      expect(confirmCalled, isTrue);
    });

    testWidgets('calls onCancel when cancel button tapped', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        AuraThemeWrapper(
          child: AuraConfirmDialog(
            title: const Text('Dialog Title'),
            message: const Text('Message'),
            confirmLabel: const Text('Confirm'),
            cancelLabel: const Text('Cancel'),
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
        const AuraThemeWrapper(
          child: AuraAlertDialog(
            title: Text('Alert'),
            message: Text('Something happened.'),
            dismissLabel: Text('OK'),
          ),
        ),
      );

      expect(find.text('Alert'), findsOneWidget);
      expect(find.text('Something happened.'), findsOneWidget);
    });

    testWidgets('displays dismiss button with default label', (tester) async {
      await tester.pumpWidget(
        const AuraThemeWrapper(
          child: AuraAlertDialog(
            title: Text('Alert'),
            message: Text('Message'),
            dismissLabel: Text('OK'),
          ),
        ),
      );

      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('uses custom dismiss label when provided', (tester) async {
      await tester.pumpWidget(
        const AuraThemeWrapper(
          child: AuraAlertDialog(
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
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                dialogResult = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Dialog Title'),
                  message: const Text('Are you sure?'),
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      // Dialog should be visible (custom Container dialog).
      expect(find.byType(AuraConfirmDialog), findsOneWidget);

      // Use widget type finder to avoid matching title.
      final confirmButton = findAuraButtonByLabel('Confirm');
      await tester.tap(confirmButton);
      final _ = await tester.pumpAndSettle();

      // Dialog should be dismissed.
      expect(find.byType(AuraConfirmDialog), findsNothing);
      expect(dialogResult, isTrue);
    });

    testWidgets('shows dialog and returns false when cancelled', (
      tester,
    ) async {
      bool? dialogResult;

      await tester.pumpWidget(
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                dialogResult = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Dialog Title'),
                  message: const Text('Are you sure?'),
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      // Dialog should be visible.
      expect(find.byType(AuraConfirmDialog), findsOneWidget);

      // Tap cancel.
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      // Dialog should be dismissed.
      expect(find.byType(AuraConfirmDialog), findsNothing);
      expect(dialogResult, isFalse);
    });
  });

  group('showAuraAlertDialog', () {
    testWidgets('shows dialog and dismisses on button tap', (tester) async {
      await tester.pumpWidget(
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                await showAuraAlertDialog(
                  context: context,
                  title: const Text('Alert'),
                  message: const Text('This is an alert.'),
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      expect(find.byType(AuraAlertDialog), findsOneWidget);

      // Tap dismiss.
      await tester.tap(find.text('OK'));
      final _ = await tester.pumpAndSettle();

      // Dialog should be dismissed.
      expect(find.byType(AuraAlertDialog), findsNothing);
    });

    testWidgets('does not dismiss when tapping outside dialog', (tester) async {
      await tester.pumpWidget(
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                await showAuraAlertDialog(
                  context: context,
                  title: const Text('Alert'),
                  message: const Text('This is an alert.'),
                  barrierDismissible: false,
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      expect(find.byType(AuraAlertDialog), findsOneWidget);

      // Tap outside the dialog (modal barrier area).
      await tester.tapAt(const Offset(1, 1));
      final _ = await tester.pumpAndSettle();

      // Alert dialog should still be visible (non-barrier-dismissible).
      expect(find.byType(AuraAlertDialog), findsOneWidget);

      // Close explicitly.
      await tester.tap(find.text('OK'));
      final _ = await tester.pumpAndSettle();
      expect(find.byType(AuraAlertDialog), findsNothing);
    });
  });

  group('Custom Dialog Implementation', () {
    testWidgets('showAuraConfirmDialog does NOT use AlertDialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                final _ = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Title'),
                  message: const Text('Message'),
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      // The dialog should NOT use Material's AlertDialog.
      expect(find.byType(AlertDialog), findsNothing);

      // Instead, it should use a custom Container.
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('showAuraAlertDialog does NOT use AlertDialog', (tester) async {
      await tester.pumpWidget(
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                await showAuraAlertDialog(
                  context: context,
                  title: const Text('Alert'),
                  message: const Text('Message'),
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      // The dialog should NOT use Material's AlertDialog.
      expect(find.byType(AlertDialog), findsNothing);

      // Instead, it should use a custom Container.
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('showAuraConfirmDialog returns false on cancel', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                result = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Title'),
                  message: const Text('Message'),
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      // Tap cancel button.
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('showAuraConfirmDialog supports barrierDismissible', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        AuraThemeWrapper(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: runDialogAction(() async {
                result = await showAuraConfirmDialog(
                  context: context,
                  title: const Text('Title'),
                  message: const Text('Message'),
                );
              }),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();

      // Tap outside the dialog (barrier).
      await tester.tapAt(const Offset(1, 1));
      final _ = await tester.pumpAndSettle();

      // Dialog should be dismissed and result should be null.
      expect(find.byType(AuraConfirmDialog), findsNothing);
      expect(result, isNull);
    });

    testWidgets(
      'showAuraConfirmDialog does not dismiss when barrierDismissible is false',
      (tester) async {
        bool? result;

        await tester.pumpWidget(
          AuraThemeWrapper(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: runDialogAction(() async {
                  result = await showAuraConfirmDialog(
                    context: context,
                    title: const Text('Title'),
                    message: const Text('Message'),
                    barrierDismissible: false,
                  );
                }),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        final _ = await tester.pumpAndSettle();

        // Tap outside the dialog (barrier).
        await tester.tapAt(const Offset(1, 1));
        final _ = await tester.pumpAndSettle();

        // Dialog should remain visible and unresolved.
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Message'), findsOneWidget);
        expect(result, isNull);

        // Close explicitly.
        await tester.tap(find.text('Cancel'));
        final _ = await tester.pumpAndSettle();
        expect(result, isFalse);
      },
    );
  });
}
