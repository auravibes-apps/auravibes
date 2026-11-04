import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  for (final scenario in [
    (
      error: StateError('Local failure'),
      expected: 'Could not load tools. Try again.',
    ),
    (
      error: const WorkspaceTableException(denied: true),
      expected: 'You do not have permission for this cloud action.',
    ),
    (
      error: const CloudAppException(
        localizationKey: LocaleKeys.cloud_errors_authentication_required,
        context: .workspace,
      ),
      expected: 'Sign in again to continue.',
    ),
  ]) {
    testWidgets('shows appropriate recovery context for ${scenario.error}', (
      tester,
    ) async {
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: Scaffold(
              body: WorkspaceItemFailure(
                error: scenario.error,
                fallbackKey: LocaleKeys.connection_setup_tools_load_error,
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text(scenario.expected), findsOneWidget);
    });
  }
}
