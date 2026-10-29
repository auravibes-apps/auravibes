import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_file_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_preview_panel.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:crypto/crypto.dart';
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

  testWidgets('compact file shows preview without page controls', (
    tester,
  ) async {
    final repository = _Assets();
    const file = WorkspaceFile(
      id: 'file',
      name: 'Stored notes',
      assetId: 'asset',
      revision: 1,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkspaceFileScreen(
              workspaceId: 'one',
              fileId: 'file',
              onBack: () {
                return;
              },
              compact: true,
            ),
          ),
          overrides: [
            workspaceFileProvider(
              'one',
              'file',
            ).overrideWith((ref) async => file),
            workspaceAssetsUsecaseProvider('one').overrideWith(
              (ref) async => ManageWorkspaceAssetsUsecase(repository),
            ),
          ],
          workspaceId: 'one',
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('Private notes'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('Stored notes'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('File reload hides stale preview while reauthorizing metadata', (
    tester,
  ) async {
    final repository = _Assets();
    Completer<WorkspaceFile>? metadata;
    const file = WorkspaceFile(
      id: 'file',
      name: 'Stored notes',
      assetId: 'asset',
      revision: 1,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: WorkspaceFileScreen(
              workspaceId: 'one',
              fileId: 'file',
              onBack: () => fail('Back should not be invoked'),
            ),
          ),
          overrides: [
            workspaceFileProvider('one', 'file').overrideWith(
              (ref) => metadata?.future ?? Future<WorkspaceFile>.value(file),
            ),
            workspaceAssetsUsecaseProvider('one').overrideWith(
              (ref) async => ManageWorkspaceAssetsUsecase(repository),
            ),
          ],
          workspaceId: 'one',
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('Private notes'), findsOneWidget);
    final pending = Completer<WorkspaceFile>();
    metadata = pending;
    repository.denied = true;
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_file_reload',
      ),
    );
    final _ = await tester.pump();
    expect(find.text('Private notes'), findsNothing);
    pending.complete(file);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Private notes'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preview clears old content while current authorization is checked',
    (tester) async {
      final repository = _Assets();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: const Scaffold(
              body: SingleChildScrollView(
                child: WorkspaceAssetPreviewPanel(
                  workspaceId: 'one',
                  assetId: 'asset',
                ),
              ),
            ),
            overrides: [
              workspaceAssetsUsecaseProvider('one').overrideWith(
                (ref) async => ManageWorkspaceAssetsUsecase(repository),
              ),
            ],
            workspaceId: 'one',
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(find.text('Private notes'), findsOneWidget);
      final pending = Completer<WorkspaceAsset>();
      repository.pending = pending;
      await tester.tap(find.text('Reload'));
      final _ = await tester.pump();
      expect(find.text('Private notes'), findsNothing);
      pending.completeError(const WorkspaceAssetException(.denied));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Private notes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Assets implements WorkspaceAssetRepository {
  Completer<WorkspaceAsset>? pending;
  bool denied = false;
  final bytesValue = Uint8List.fromList(utf8.encode('Private notes'));
  @override
  Future<WorkspaceAsset> asset(String id) async {
    if (denied) throw const WorkspaceAssetException(.denied);
    if (pending case final pending?) return await pending.future;

    return WorkspaceAsset(
      id: id,
      name: 'notes.txt',
      mimeType: 'text/plain',
      sizeBytes: bytesValue.length,
      checksum: sha256.convert(bytesValue).toString(),
    );
  }

  @override
  Future<Uint8List> bytes(String id) async => bytesValue;
  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) =>
      throw UnimplementedError();
}
