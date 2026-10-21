import 'dart:async';

import 'package:auravibes_app/widgets/management_list_feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('keeps failures visible when a retry callback throws', (
    tester,
  ) async {
    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  ManagementListFeedback.showFailuresDialog<int>(
                    context: context,
                    failedItems: const [1],
                    nameOf: (_) => 'Failed item',
                    onRetry: (_) async => throw StateError('Retry failed'),
                  ),
                );
              },
              child: const Text('Open failures'),
            ),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    final _ = await tester.tap(find.text('Open failures'));
    final _ = await tester.pumpAndSettle();
    final _ = await tester.tap(find.text('Retry failed'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Failed item'), findsOneWidget);
    expect(find.text('Retry failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
