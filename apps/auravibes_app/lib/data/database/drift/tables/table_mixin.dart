// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

mixin TableMixin on Table {
  /// Primary key column as string.
  late final id = text().clientDefault(() => const UuidV7().generate())();

  /// When was created timestamp.
  late final createdAt = dateTime().withDefault(currentDateAndTime)();

  /// When was last updated timestamp.
  late final updatedAt = dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  bool isPrimaryKeyColumn(Column column) => primaryKey.contains(column);
}
