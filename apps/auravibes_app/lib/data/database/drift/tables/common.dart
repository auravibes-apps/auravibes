// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime
// (see api_model_table.dart).
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

mixin TableMixin on Table {
  ///Primary key column as string
  late final Column<String> id = text().clientDefault(
    () => const UuidV7().generate(),
  )();

  /// when was created timestamp
  late final Column<DateTime> createdAt = dateTime().withDefault(
    currentDateAndTime,
  )();

  /// when was last updated timestamp
  late final Column<DateTime> updatedAt = dateTime().withDefault(
    currentDateAndTime,
  )();
}
