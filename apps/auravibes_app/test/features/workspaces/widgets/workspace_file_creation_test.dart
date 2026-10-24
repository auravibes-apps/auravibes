import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_file_creation.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'creation recovers from unavailable workspace without unhandled futures',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Scaffold(
              body: SingleChildScrollView(
                child: WorkspaceFileCreation(
                  workspaceId: 'one',
                  parentId: null,
                  onOpenFile: (_) => fail('Must not create a File'),
                ),
              ),
            ),
            overrides: [
              createWorkspaceFileUsecaseProvider('one').overrideWith(
                (ref) async =>
                    throw const WorkspaceAssetException(.unavailable),
              ),
            ],
            workspaceId: 'one',
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('unavailable', findRichText: true),
        findsWidgets,
      );
      final button = tester.widget<AuraButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraButton &&
              widget.identifier == 'workspace_file_create',
        ),
      );
      expect(button.disabled, isTrue);
      expect(find.text('Reload'), findsOneWidget);
    },
  );
}
