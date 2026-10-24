import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

abstract final class WorkspaceReferenceValue {
  static bool valid(WorkspaceColumn column, Object? value) =>
      column.referenceMultiple
      ? value is List &&
            value.toSet().length == value.length &&
            value.every(_id)
      : _id(value);

  static List<String> ids(Object? value) => switch (value) {
    final String id => [id],
    final List<dynamic> ids => ids.cast<String>(),
    _ => const [],
  };

  static bool _id(Object? value) =>
      value is String && value.isNotEmpty && value.length <= 200;
}
