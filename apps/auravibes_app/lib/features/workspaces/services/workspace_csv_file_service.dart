import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:file_picker/file_picker.dart';

class const WorkspaceCsvFileService() {
  Future<String?> pick() async {
    final file = await FilePicker.pickFile(
      type: .custom,
      allowedExtensions: const ['csv'],
    );
    if (file == null) return null;

    return await _read(file);
  }

  Future<bool> save(String csv) async {
    final result = await FilePicker.saveFile(
      fileName: 'table.csv',
      mimeType: 'text/csv',
      bytes: .fromList(utf8.encode(csv)),
    );

    return result != null;
  }

  Future<String> _read(PlatformFile file) async {
    _validateLength(await file.length());
    final bytes = await file.readAsBytes();
    _validateLength(bytes.length);

    try {
      return utf8.decode(bytes);
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const WorkspaceCsvException('workspace_csv.invalid_file'),
        stackTrace,
      );
    }
  }

  void _validateLength(int? length) {
    if (length != null && length > WorkspaceCsvInput.maxSourceBytes) {
      throw const WorkspaceCsvException('workspace_csv.too_large');
    }
  }
}
