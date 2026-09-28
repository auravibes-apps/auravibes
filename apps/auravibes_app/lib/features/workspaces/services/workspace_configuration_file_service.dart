import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:file_picker/file_picker.dart';

class const WorkspaceConfigurationFileService() {
  Future<String?> pickArchiveJson() async {
    final file = await _pickJsonFile();
    if (file == null) return null;
    await _validateFileLength(file);
    final bytes = await file.readAsBytes();

    return _decodeArchiveBytes(bytes);
  }

  Future<bool> saveArchiveJson(String json) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    if (bytes.length > WorkspaceConfigurationArchiveCodec.maxArchiveBytes) {
      throw const WorkspaceConfigurationArchiveException(
        'workspace_archive.invalid',
      );
    }
    final saved = await FilePicker.saveFile(
      fileName: 'workspace-configuration.auravibes.json',
      bytes: bytes,
      mimeType: 'application/json',
    );

    return saved != null;
  }

  Future<PlatformFile?> _pickJsonFile() =>
      FilePicker.pickFile(type: .custom, allowedExtensions: const ['json']);

  Future<void> _validateFileLength(PlatformFile file) async {
    final length = await file.length();
    if (length != null) _validateArchiveLength(length);
  }

  String _decodeArchiveBytes(Uint8List bytes) {
    _validateArchiveLength(bytes.length);
    try {
      return utf8.decode(bytes);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(_invalidArchive(), stackTrace);
    }
  }
}

void _validateArchiveLength(int length) {
  if (length > WorkspaceConfigurationArchiveCodec.maxArchiveBytes) {
    throw _invalidArchive();
  }
}

WorkspaceConfigurationArchiveException _invalidArchive() =>
    const WorkspaceConfigurationArchiveException('workspace_archive.invalid');
