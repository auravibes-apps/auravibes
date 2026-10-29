// Drift generates table behavior; schema getters alone have no class weight.
// ignore_for_file: weight-of-class
import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_folders.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceWorkflowRow')
class WorkspaceWorkflows extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get parentId =>
      text().nullable().references(WorkspaceFolders, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get definitionJson => text()();
}
