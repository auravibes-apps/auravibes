// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
// DCL cannot score Drift's generated table behavior from schema declarations.
// ignore_for_file: number-of-methods, weight-of-class
import 'package:drift/drift.dart';

@DataClassName('RecentModelSelectionTable')
class RecentModelSelections extends Table {
  TextColumn get workspaceId => text()();

  TextColumn get selectionId => text()();

  IntColumn get selectedAtMicros => integer()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId, selectionId};
}
