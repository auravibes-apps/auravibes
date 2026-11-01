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

    final bytes = await _readProfileBytes(file);

    return _decodeProfileBytes(bytes);
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

  Future<Uint8List> _readProfileBytes(PlatformFile file) async {
    final knownLength = file.lengthSync();
    if (knownLength != null) _validateKnownLength(knownLength);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      _appendProfileChunk(bytes, chunk);
    }

    final profileBytes = bytes.takeBytes();
    _validateBufferedLength(profileBytes.length);

    return profileBytes;
  }

  String _decodeProfileBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(_invalidProfileError(), stackTrace);
    }
  }
}

void _validateLength(int length) {
  if (length < 0 || length > AppAppearanceProfileCodec.maxProfileBytes) {
    _invalidProfile();
  }
}

void _validateKnownLength(int length) {
  if (length > AppAppearanceProfileCodec.maxProfileBytes) _invalidProfile();
}

void _appendProfileChunk(BytesBuilder bytes, Uint8List chunk) {
  final nextLength = bytes.length + chunk.length;
  if (nextLength > AppAppearanceProfileCodec.maxProfileBytes) {
    _invalidProfile();
  }
  bytes.add(chunk);
}

void _validateBufferedLength(int length) {
  if (length > AppAppearanceProfileCodec.maxProfileBytes) _invalidProfile();
}

Never _invalidProfile() => throw _invalidProfileError();

AppAppearanceProfileException _invalidProfileError() =>
    const AppAppearanceProfileException(
      'settings_screen.appearance_profile.invalid_file',
    );
