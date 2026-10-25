import 'dart:typed_data';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_asset_file_service.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_file_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_file_creation.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets('File retry keeps its upload at $width and 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = .new(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final assets = _Assets();
      final files = _Files();
      final source = WorkspaceAssetDraft(
        name: 'notes.txt',
        bytes: .fromList('hello'.codeUnits),
      );
      String? opened;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: WorkspaceFileCreation(
                      workspaceId: 'one',
                      parentId: null,
                      onOpenFile: (id) => opened = id,
                    ),
                  ),
                ),
              ),
            ),
            overrides: [
              workspaceAssetFileServiceProvider.overrideWithValue(
                _Picker(source),
              ),
              createWorkspaceFileUsecaseProvider('one').overrideWith(
                (ref) async =>
                    CreateWorkspaceFileUsecase(.new(assets), .new(files)),
              ),
            ],
            workspaceId: 'one',
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text(LocaleKeys.workspace_assets_choose.tr()));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text(LocaleKeys.workspace_assets_create.tr()));
      final _ = await tester.pumpAndSettle();
      expect(opened, isNull);
      expect(
        find.text(LocaleKeys.workspace_assets_uploaded_retry.tr()),
        findsOneWidget,
      );
      final name = tester.widget<AuraInput>(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraInput && widget.identifier == 'workspace_file_name',
        ),
      );
      expect(name.enabled, isFalse);
      await tester.tap(find.text(LocaleKeys.workspace_assets_create.tr()));
      final _ = await tester.pumpAndSettle();
      expect(opened, files.ids.first);
      expect(files.ids, [opened, opened]);
      expect(assets.uploads, 1);
      expect(tester.takeException(), isNull);
    });
  }

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

class _Picker extends WorkspaceAssetFileService {
  const new(this.draft);
  final WorkspaceAssetDraft draft;
  @override
  Future<WorkspaceAssetDraft?> pick() async => draft;
}

class _Assets extends Mock implements WorkspaceAssetRepository {
  int uploads = 0;
  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) async {
    uploads++;

    return WorkspaceAsset(
      id: 'asset',
      name: name,
      mimeType: 'text/plain',
      sizeBytes: bytes.length,
      checksum: 'unused',
    );
  }
}

class _Files extends Mock implements WorkspaceFileRepository {
  final ids = <String>[];
  @override
  Future<WorkspaceFile> create(
    WorkspaceFileDraft draft, {
    bool sharingApproved = false,
  }) async {
    ids.add(draft.id);
    if (ids.length == 1) throw const WorkspaceAssetException(.unavailable);

    return WorkspaceFile(
      id: draft.id,
      name: draft.name,
      assetId: draft.assetId,
      revision: 1,
    );
  }
}
