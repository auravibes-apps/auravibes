import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceTableRow')
class WorkspaceTables extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get columnsJson => text()();
  TextColumn get labelColumnId => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  IntColumn get schemaRevision => integer().withDefault(const Constant(1))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('WorkspaceTableRecordRow')
class WorkspaceTableRecords extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get tableId =>
      text().references(WorkspaceTables, #id, onDelete: .cascade)();
  TextColumn get valuesJson => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
