import 'dart:async';

import 'package:auravibes_app/test/helpers/test_app.dart';
import 'package:auravibes_app/widgets/management_list_feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('keeps failures visible when a retry callback throws', (
    tester,
  ) async {
    await tester.pumpWidget(
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
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open failures'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry failed'));
    await tester.pumpAndSettle();

    expect(find.text('Failed item'), findsOneWidget);
    expect(find.text('Retry failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
