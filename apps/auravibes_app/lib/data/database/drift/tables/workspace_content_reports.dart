import 'package:drift/drift.dart';

// Drift schema getters are required by generated persistence.
// ignore: weight-of-class
mixin _WorkspaceContentReportColumns on Table {
  TextColumn get workspaceId => text()();
  TextColumn get reportId => text()();
  TextColumn get kind => text()();
  TextColumn get resourceId => text()();
  TextColumn get tableId => text().nullable()();
}

@DataClassName('WorkspaceContentReportRow')
// Drift schema getters are required by generated persistence.
// ignore: weight-of-class
class WorkspaceContentReports extends Table
    with _WorkspaceContentReportColumns {
  IntColumn get revision => integer()();
  TextColumn get conversationId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('submitted'))();
  TextColumn get reporterId =>
      text().withDefault(const Constant('local_user'))();
  TextColumn get reviewerId => text().nullable()();
  DateTimeColumn get submittedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get reviewedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId, reportId};
}
