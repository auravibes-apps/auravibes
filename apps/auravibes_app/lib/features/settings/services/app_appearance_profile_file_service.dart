import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/settings/models/app_appearance_profile.dart';
import 'package:file_picker/file_picker.dart';

class const AppAppearanceProfileFileService() {
  Future<String?> pickProfileJson() async {
    final file = await FilePicker.pickFile(
      type: .custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;

    final knownLength = file.lengthSync();
    if (knownLength != null) _validateLength(knownLength);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (bytes.length + chunk.length >
          AppAppearanceProfileCodec.maxProfileBytes) {
        _invalidProfile();
      }
      bytes.add(chunk);
    }

    final profileBytes = bytes.takeBytes();
    _validateLength(profileBytes.length);
    try {
      return utf8.decode(profileBytes);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(_invalidProfileError(), stackTrace);
    }
  }

  Future<bool> saveProfileJson(String json) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    _validateLength(bytes.length);
    final saved = await FilePicker.saveFile(
      fileName: 'auravibes-appearance.json',
      bytes: bytes,
      mimeType: 'application/json',
    );

    return saved != null;
  }
}

void _validateLength(int length) {
  if (length < 0 || length > AppAppearanceProfileCodec.maxProfileBytes) {
    _invalidProfile();
  }
}

Never _invalidProfile() => throw _invalidProfileError();

AppAppearanceProfileException _invalidProfileError() =>
    const AppAppearanceProfileException(
      'settings_screen.appearance_profile.invalid_file',
    );
