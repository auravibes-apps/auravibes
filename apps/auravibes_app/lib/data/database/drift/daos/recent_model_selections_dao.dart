import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/recent_model_selections.dart';
import 'package:drift/drift.dart';

part 'recent_model_selections_dao.g.dart';

@DriftAccessor(tables: [RecentModelSelections])
class RecentModelSelectionsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$RecentModelSelectionsDaoMixin {
  static const maxRecentModels = 5;

  Future<List<String>> getSelectionIds(String workspaceId) async =>
      (await _selectionRows(workspaceId))
          .map((row) => row.selectionId)
          .toList();

  Future<void> recordSelection(String workspaceId, String selectionId) async {
    if (workspaceId.isEmpty || selectionId.isEmpty) return;

    await transaction(
      () => _recordSelectionInTransaction(workspaceId, selectionId),
    );
  }

  Future<List<RecentModelSelectionTable>> _selectionRows(String workspaceId) =>
      (select(recentModelSelections)
            ..where((table) => table.workspaceId.equals(workspaceId))
            ..orderBy([
              (table) => OrderingTerm.desc(table.selectedAtMicros),
              (table) => OrderingTerm.asc(table.selectionId),
            ])
            ..limit(maxRecentModels))
          .get();

  Future<void> _recordSelectionInTransaction(
    String workspaceId,
    String selectionId,
  ) async {
    final latest = await _latestSelection(workspaceId);
    final selectedAtMicros = _nextSelectedAtMicros(latest);
    await _upsertSelection(workspaceId, selectionId, selectedAtMicros);
  }

  Future<RecentModelSelectionTable?> _latestSelection(String workspaceId) =>
      (select(recentModelSelections)
            ..where((table) => table.workspaceId.equals(workspaceId))
            ..orderBy([(table) => OrderingTerm.desc(table.selectedAtMicros)])
            ..limit(1))
          .getSingleOrNull();

  int _nextSelectedAtMicros(RecentModelSelectionTable? latest) {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    if (latest == null || latest.selectedAtMicros < now) return now;

    return latest.selectedAtMicros + 1;
  }

  Future<void> _upsertSelection(
    String workspaceId,
    String selectionId,
    int selectedAtMicros,
  ) async {
    final _ = await into(recentModelSelections).insert(
      RecentModelSelectionsCompanion.insert(
        workspaceId: workspaceId,
        selectionId: selectionId,
        selectedAtMicros: selectedAtMicros,
      ),
      onConflict: DoUpdate(
        (_) => RecentModelSelectionsCompanion(
          selectedAtMicros: .new(selectedAtMicros),
        ),
        target: [
          recentModelSelections.workspaceId,
          recentModelSelections.selectionId,
        ],
      ),
    );
  }
}
