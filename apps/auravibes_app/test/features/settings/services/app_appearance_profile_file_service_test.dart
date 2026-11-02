import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/settings/models/app_appearance_profile.dart';
import 'package:auravibes_app/features/settings/services/app_appearance_profile_file_service.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final previousPicker = fp.FilePickerPlatform.instance;
  tearDownAll(() => fp.FilePickerPlatform.instance = previousPicker);

  group('AppAppearanceProfileFileService', () {
    test('reads selected profile JSON as UTF-8', () async {
      const json = '''
        {
          "format": "auravibes.app-appearance",
          "version": 1,
          "themeMode": "dark",
          "accentHue": 186
        }
      ''';
      final picker = _ProfilePicker(
        file: _ProfileFile(bytes: .fromList(utf8.encode(json))),
      );
      fp.FilePickerPlatform.instance = picker;

      final result = await const AppAppearanceProfileFileService()
          .pickProfileJson();

      expect(result, json);
      expect(picker.pickedType, fp.FileType.custom);
      expect(picker.pickedExtensions, ['json']);
    });

    test('returns null when the native picker is canceled', () async {
      fp.FilePickerPlatform.instance = _ProfilePicker();

      final result = await const AppAppearanceProfileFileService()
          .pickProfileJson();

      expect(result, isNull);
    });

    test('rejects known oversized files before streaming bytes', () async {
      final file = _ProfileFile(
        bytes: .new(AppAppearanceProfileCodec.maxProfileBytes + 1),
        knownLength: AppAppearanceProfileCodec.maxProfileBytes + 1,
      );
      fp.FilePickerPlatform.instance = _ProfilePicker(file: file);

      await expectLater(
        const AppAppearanceProfileFileService().pickProfileJson(),
        throwsA(_invalidProfile()),
      );
      expect(file.streamStarted, isFalse);
    });

    test(
      'stops an unknown-length stream when it exceeds the byte cap',
      () async {
        final file = _ProfileFile(
          bytes: .new(0),
          reportLength: false,
          chunks: [
            Uint8List(AppAppearanceProfileCodec.maxProfileBytes),
            Uint8List(1),
            Uint8List(1),
          ],
        );
        fp.FilePickerPlatform.instance = _ProfilePicker(file: file);

        await expectLater(
          const AppAppearanceProfileFileService().pickProfileJson(),
          throwsA(_invalidProfile()),
        );
        expect(file.streamChunksRead, 2);
      },
    );

    test('rejects invalid UTF-8 bytes', () async {
      fp.FilePickerPlatform.instance = _ProfilePicker(
        file: _ProfileFile(bytes: .fromList([0xff, 0xfe])),
      );

      await expectLater(
        const AppAppearanceProfileFileService().pickProfileJson(),
        throwsA(_invalidProfile()),
      );
    });

    test('saves JSON bytes with the portable profile file name', () async {
      final picker = _ProfilePicker(savedUri: .parse('file:///profile.json'));
      fp.FilePickerPlatform.instance = picker;

      final saved = await const AppAppearanceProfileFileService()
          .saveProfileJson('{"version":1}');

      expect(saved, isTrue);
      expect(picker.savedFileName, 'auravibes-appearance.json');
      expect(picker.savedMimeType, 'application/json');
      expect(picker.savedBytes, orderedEquals(utf8.encode('{"version":1}')));
    });

    test('returns false when the save destination is canceled', () async {
      fp.FilePickerPlatform.instance = _ProfilePicker();

      final saved = await const AppAppearanceProfileFileService()
          .saveProfileJson('{"version":1}');

      expect(saved, isFalse);
    });

    test('rejects oversized JSON before opening the save dialog', () async {
      final picker = _ProfilePicker();
      fp.FilePickerPlatform.instance = picker;
      final json = ' ' * (AppAppearanceProfileCodec.maxProfileBytes + 1);

      await expectLater(
        const AppAppearanceProfileFileService().saveProfileJson(json),
        throwsA(_invalidProfile()),
      );
      expect(picker.saveCount, 0);
    });
  });
}

Matcher _invalidProfile() => isA<AppAppearanceProfileException>().having(
  (error) => error.localizationKey,
  'localizationKey',
  'settings_screen.appearance_profile.invalid_file',
);

class _ProfilePicker({final fp.PlatformFile? file, final Uri? savedUri})
    extends fp.FilePickerPlatform {
  fp.FileType? pickedType;
  List<String>? pickedExtensions;
  String? savedFileName;
  String? savedMimeType;
  Uint8List? savedBytes;
  int saveCount = 0;

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
  }) async {
    pickedType = type;
    pickedExtensions = allowedExtensions;

    return file;
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    void Function(fp.FilePickerStatus)? onFileSaving,
    fp.WindowsOptions windowsOptions = const fp.WindowsOptions(),
    fp.LinuxOptions linuxOptions = const fp.LinuxOptions(),
    fp.WebOptions webOptions = const fp.WebOptions(),
  }) async {
    saveCount++;
    savedFileName = fileName;
    savedMimeType = mimeType;
    savedBytes = bytes;

    return savedUri;
  }
}

base class _ProfileFile extends fp.PlatformFile {
  // ignore: unnecessary_type_name_in_constructor - Required by the `base` modifier syntax.
  _ProfileFile({
    required this.bytes,
    this.knownLength,
    this.reportLength = true,
    List<Uint8List>? chunks,
  }) : chunks = chunks ?? [bytes];

  final Uint8List bytes;
  final int? knownLength;
  final bool reportLength;
  final List<Uint8List> chunks;
  bool streamStarted = false;
  int streamChunksRead = 0;

  @override
  String get name => 'appearance.json';

  @override
  Uri get uri => Uri.parse('file:///appearance.json');

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => reportLength ? knownLength ?? bytes.length : null;

  @override
  Future<int?> length() async => lengthSync();

  @override
  Future<Uint8List> readAsBytes() async => bytes;

  @override
  Stream<Uint8List> readAsByteStream() async* {
    streamStarted = true;
    for (final chunk in chunks) {
      streamChunksRead++;
      yield chunk;
    }
  }
}
