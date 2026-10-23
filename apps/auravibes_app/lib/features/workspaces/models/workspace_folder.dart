import 'package:auravibes_app/i18n/locale_keys.dart';

class const WorkspaceFolder({
  required final String id,
  required final String name,
  required final int revision,
  final String? parentId,
  final bool canManage = true,
});

class const WorkspaceFolderException({final bool conflict = false})
    implements Exception {
  String get localizationKey => conflict
      ? LocaleKeys.cloud_errors_conflict
      : LocaleKeys.workspace_items_invalid_folder;

  @override
  String toString() => 'WorkspaceFolderException';
}

abstract interface class WorkspaceFolderRepository {
  Future<List<WorkspaceFolder>> list({String? parentId});
  Future<WorkspaceFolder> create({required String name, String? parentId});
  Future<WorkspaceFolder> updateMetadata({
    required WorkspaceFolder folder,
    required String name,
    required String? parentId,
  });
}
