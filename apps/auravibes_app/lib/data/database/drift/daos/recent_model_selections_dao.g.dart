// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_model_selections_dao.dart';

// ignore_for_file: type=lint
mixin _$RecentModelSelectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecentModelSelectionsTable get recentModelSelections =>
      attachedDatabase.recentModelSelections;
  RecentModelSelectionsDaoManager get managers =>
      RecentModelSelectionsDaoManager(this);
}

class RecentModelSelectionsDaoManager {
  final _$RecentModelSelectionsDaoMixin _db;
  RecentModelSelectionsDaoManager(this._db);
  $$RecentModelSelectionsTableTableManager get recentModelSelections =>
      $$RecentModelSelectionsTableTableManager(
        _db.attachedDatabase,
        _db.recentModelSelections,
      );
}
