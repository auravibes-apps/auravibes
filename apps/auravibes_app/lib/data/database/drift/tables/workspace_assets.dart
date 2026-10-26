// Drift table declarations expose getters required by the schema DSL.
// ignore_for_file: weight-of-class

import 'package:auravibes_app/data/database/drift/tables/table_mixin.dart';
import 'package:auravibes_app/data/database/drift/tables/workspaces.dart';
import 'package:drift/drift.dart';

@DataClassName('WorkspaceAssetRow')
class WorkspaceAssets extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get name => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get checksum => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}

@DataClassName('WorkspaceFileRow')
class WorkspaceFiles extends Table with TableMixin {
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: .cascade)();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get assetId => text().references(WorkspaceAssets, #id)();
  TextColumn get creationHash => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Survives workspace cascades so explicit byte erasure can retry safely.
@DataClassName('WorkspaceAssetDeletionRow')
class WorkspaceAssetDeletions extends Table {
  TextColumn get assetId => text()();

  @override
  Set<Column> get primaryKey => {assetId};
}
