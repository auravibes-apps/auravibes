import 'package:drift/drift.dart';

@DataClassName('WorkspaceContentReportRow')
class WorkspaceContentReports extends Table {
  TextColumn get workspaceId => text()();
  TextColumn get reportId => text()();
  TextColumn get kind => text()();
  TextColumn get resourceId => text()();
  TextColumn get tableId => text().nullable()();
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
