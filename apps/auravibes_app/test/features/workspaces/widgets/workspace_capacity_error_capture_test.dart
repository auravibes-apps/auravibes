import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_asset_file_service.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/ux_validation_fixture.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  tearDownAll(UxValidationFixture.closeDatabase);

  test(
    'picker classifies an oversized workspace file before reading bytes',
    () async {
      final file = _OversizedFile(
        size: ChatAttachmentModality.maxChatAttachmentBytes + 1,
      );
      final previousPicker = fp.FilePickerPlatform.instance;
      addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
      fp.FilePickerPlatform.instance = _OversizedFilePicker(file);

      await expectLater(
        const WorkspaceAssetFileService().pick(),
        throwsA(
          isA<WorkspaceAssetException>().having(
            (error) => error.failure.name,
            'failure.name',
            'sizeLimitExceeded',
          ),
        ),
      );
      expect(file.bytesRead, isFalse);
    },
  );

  testWidgets('workspace File size-limit copy on the production route', (
    tester,
  ) async {
    const workspaceId = '019a1e91-0000-7000-8000-000000001692';
    const size = Size(960, 900);
    const sizeLimitFailure = WorkspaceAssetException(.sizeLimitExceeded);
    final file = _OversizedFile(
      size: ChatAttachmentModality.maxChatAttachmentBytes + 1,
    );
    final previousPicker = fp.FilePickerPlatform.instance;
    addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
    fp.FilePickerPlatform.instance = _OversizedFilePicker(file);

    final fixture = await UxValidationFixture.create(
      localWorkspaceId: workspaceId,
    );
    final router = await fixture.pump(
      tester,
      WorkspaceItemsRoute(workspaceId: fixture.workspaceId).location,
      size: size,
    );
    expect(find.byKey(const ValueKey('directory_create')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('directory_create')));
    await fixture.settle(tester);
    await tester.tap(find.text(LocaleKeys.workspace_assets_file.tr()));
    await fixture.settle(tester);
    await tester.tap(find.text(LocaleKeys.workspace_assets_choose.tr()));
    await fixture.settle(tester);

    const captureStage = String.fromEnvironment('UX_CAPTURE_STAGE');
    if (captureStage == 'before') {
      expect(
        find.text(LocaleKeys.workspace_assets_invalid.tr()),
        findsOneWidget,
      );
    } else if (captureStage == 'after') {
      expect(find.text(sizeLimitFailure.localizationKey.tr()), findsOneWidget);
    } else {
      expect(find.byType(WorkspaceItemFailure), findsOneWidget);
      expect(find.text(sizeLimitFailure.localizationKey.tr()), findsOneWidget);
    }
    expect(file.bytesRead, isFalse);
    expect(tester.takeException(), isNull);

    await _capture(
      tester,
      router.routeInformationProvider.value.uri.toString(),
      size: size,
      sourceRevision: const String.fromEnvironment('UX_SOURCE_FINGERPRINT'),
      stage: captureStage.isEmpty ? 'after' : captureStage,
    );
    await fixture.close(tester);
  });
}

Future<void> _capture(
  WidgetTester tester,
  String route, {
  required Size size,
  required String sourceRevision,
  required String stage,
}) async {
  const output = String.fromEnvironment('UX_CAPTURE_DIR');
  if (output.isEmpty) return;

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('ux-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(output);
    final _ = await directory.create(recursive: true);
    final filename = 'workspace-file-size-limit-$stage';
    final _ = await File('$output/$filename.png').writeAsBytes(
      (bytes ?? (throw StateError('PNG encoding failed'))).buffer.asUint8List(),
    );
    final _ = await File('$output/$filename.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'name': 'workspace-file-size-limit-$stage',
        'route': route,
        'fixture':
            'Production WorkspaceItemsRoute with a synthetic local workspace; '
            'the native file picker returns a synthetic file of 25 MiB plus '
            'one byte; no file bytes are read or persisted.',
        'sourceRevision': sourceRevision,
        'stage': stage,
        'renderer': 'Flutter widget-test Skia, ${Platform.operatingSystem}',
        'viewport': [size.width, size.height],
        'locale': 'en',
        'textScale': 1.0,
        'theme': 'light',
        'accentHue': 186.0,
        'flavor': 'prod route under controlled widget fixture',
        'disableAnimations': true,
        'flutterVersion': const String.fromEnvironment('UX_FLUTTER_VERSION'),
        'fontLimitations':
            'Flutter widget-test text only; native system typography and '
            'assistive technology are not represented.',
      }),
    );
  });
}

class _OversizedFilePicker(final _OversizedFile file)
    extends fp.FilePickerPlatform {
  @override
  Future<fp.PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    void Function(fp.FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    fp.AndroidOptions androidOptions = const fp.AndroidOptions(),
    fp.DarwinOptions darwinOptions = const fp.DarwinOptions(),
    fp.WindowsOptions windowsOptions = const fp.WindowsOptions(),
    fp.LinuxOptions linuxOptions = const fp.LinuxOptions(),
    fp.WebOptions webOptions = const fp.WebOptions(),
  }) async => file;
}

base class _OversizedFile({required final int size}) extends fp.PlatformFile {
  @override
  final String name = 'synthetic-oversized.txt';
  @override
  final Uri uri = .file('/tmp/synthetic-oversized.txt');
  bool bytesRead = false;

  @override
  Never get xFile => throw UnsupportedError('xFile is not used');

  @override
  int? lengthSync() => size;

  @override
  Future<int?> length() async => size;

  @override
  Future<Uint8List> readAsBytes() async {
    bytesRead = true;
    throw UnsupportedError('Oversized bytes must not be read');
  }

  @override
  Stream<Uint8List> readAsByteStream() =>
      throw UnsupportedError('Oversized bytes must not be read');
}
