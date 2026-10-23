import 'package:auravibes_app/i18n/locale_keys.dart';

class const WorkspaceFolder({
  required final String id,
  required final String name,
  required final int revision,
  final String? parentId,
});

class const WorkspaceFolderException() implements Exception {
  String get localizationKey => LocaleKeys.workspace_items_invalid_folder;
}

abstract interface class WorkspaceFolderRepository {
  Future<List<WorkspaceFolder>> list({String? parentId});
  Future<WorkspaceFolder> create({required String name, String? parentId});
}
