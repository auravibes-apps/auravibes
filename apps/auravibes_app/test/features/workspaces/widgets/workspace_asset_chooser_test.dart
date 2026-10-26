import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_chooser.dart';
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
  for (final width in [400.0, 1200.0]) {
    testWidgets('Directory asset selection recovers at $width and 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = .new(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var fail = true;
      WorkspaceAsset? selected;
      Future<void> choose(BuildContext context) async {
        selected = await showDialog<WorkspaceAsset>(
          context: context,
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: const WorkspaceAssetChooser(workspaceId: 'one'),
          ),
        );
      }

      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => unawaited(choose(context)),
                  child: const Text('Open'),
                ),
              ),
            ),
            overrides: [
              workspaceFoldersProvider('one', null).overrideWith(
                (ref) async => const [
                  WorkspaceFolder(id: 'docs', name: 'Documents', revision: 1),
                ],
              ),
              workspaceFoldersProvider(
                'one',
                'docs',
              ).overrideWith((ref) async => []),
              workspaceFilesProvider('one', null).overrideWith((ref) async {
                if (fail) throw const WorkspaceAssetException(.unavailable);

                return const [
                  WorkspaceFile(
                    id: 'denied',
                    name: 'Unavailable file',
                    assetId: 'hidden',
                    revision: 1,
                  ),
                ];
              }),
              workspaceFilesProvider('one', 'docs').overrideWith(
                (ref) async => const [
                  WorkspaceFile(
                    id: 'file',
                    name: 'Stored notes',
                    assetId: 'asset',
                    revision: 1,
                    asset: _asset,
                  ),
                ],
              ),
            ],
            workspaceId: 'one',
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      final _ = await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      fail = false;
      await tester.tap(find.byIcon(Icons.refresh));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Unavailable file'));
      final _ = await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.tap(find.text('Documents'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Stored notes'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Unavailable file'), findsOneWidget);
      await tester.tap(find.text('Documents'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Stored notes'));
      final _ = await tester.pumpAndSettle();
      expect(selected?.id, 'asset');
      expect(tester.takeException(), isNull);
    });
  }
}

const _asset = WorkspaceAsset(
  id: 'asset',
  name: 'notes.txt',
  mimeType: 'text/plain',
  sizeBytes: 5,
  checksum: 'unused',
);
