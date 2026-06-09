// coverage:ignore-file
// Required: Drift table DSL is unreachable at runtime.
// (See api_models.dart).
import 'package:drift/drift.dart';
import 'package:uuid/v7.dart';

mixin TableMixin on Table {
  /// Primary key column as string.
  TextColumn get id => text().clientDefault(
    () => const UuidV7().generate(),
  )();

  /// When was created timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(
    currentDateAndTime,
  )();

  /// When was last updated timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(
    currentDateAndTime,
  )();
}
