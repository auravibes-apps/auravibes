import 'package:auravibes_app/features/workspaces/models/workspace_exact_value_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:uuid/v7.dart';

const _maximumColumns = 100;
const _maximumNameLength = 200;
const _maximumTextLength = 16384;
const _minimumPhoneDigits = 3;

abstract final class WorkspaceColumnValidation {
  static WorkspaceColumn normalized(WorkspaceColumn column) =>
      WorkspaceColumn.fromJson({
        ...column.toJson(),
        'id': _ColumnConfiguration.id(column),
        'name': _ColumnConfiguration.name(column),
        'options': _ColumnConfiguration.options(column),
      });

  static void columns(List<WorkspaceColumn> columns, String labelColumnId) {
    _require(columns.isNotEmpty && columns.length <= _maximumColumns);
    _require(_uniqueIds(columns));
    _require(_validLabel(columns, labelColumnId));
    columns.forEach(_column);
    for (final column in columns) {
      _dependency(columns, column);
    }
  }

  static void values(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) {
    _require(accepts(columns, values));
  }

  static bool accepts(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) =>
      columns.every(
        (column) => !column.isRequired || values.containsKey(column.id),
      ) &&
      values.entries.every((entry) => _entryValid(columns, entry));

  static bool _entryValid(
    List<WorkspaceColumn> columns,
    MapEntry<String, Object?> entry,
  ) {
    final column = columns
        .where((column) => column.id == entry.key)
        .firstOrNull;

    return column != null && _ValueValidation.valid(column, entry.value);
  }

  static bool _uniqueIds(List<WorkspaceColumn> columns) =>
      columns.map((column) => column.id).toSet().length == columns.length;

  static void _column(WorkspaceColumn column) {
    _require(column.id.isNotEmpty && _name(column.name));
    _require(_ColumnConfiguration.valid(column));

    if (column.type != .singleSelect && column.type != .multiSelect) {
      _require(column.options.isEmpty);

      return;
    }
    _selection(column.options);
  }

  static void _selection(List<String> options) {
    _require(options.isNotEmpty && options.length <= _maximumColumns);
    _require(options.toSet().length == options.length);
    _require(options.every(_name));
  }

  static bool _name(String value) =>
      value.trim().isNotEmpty && value.length <= _maximumNameLength;

  static void _require(bool valid) {
    if (!valid) {
      throw const WorkspaceTableException();
    }
  }
}

abstract final class _ColumnConfiguration {
  static String id(WorkspaceColumn column) =>
      column.id.isEmpty ? const UuidV7().generate() : column.id;

  static String name(WorkspaceColumn column) => column.name.trim();
  static List<String> options(WorkspaceColumn column) =>
      column.options.map((name) => name.trim()).toList();
  static bool reference(WorkspaceColumn column) => column.type == .reference
      ? column.targetTableId?.isNotEmpty == true
      : column.targetTableId == null && !column.referenceMultiple;
  static bool valid(WorkspaceColumn column) =>
      reference(column) &&
      WorkspaceTimeZones.valid(column.timeZone) &&
      (column.defaultValue == null ||
          _ValueValidation.valid(column, column.defaultValue));
}

abstract final class _ValueValidation {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phonePattern = RegExp(
    r'^\+?[0-9 ()-]+(?:\s*(?:x|ext\.?)\s*[0-9]+)?$',
    caseSensitive: false,
  );

  static bool valid(WorkspaceColumn column, Object? value) =>
      switch (column.type) {
        .text ||
        .number ||
        .checkbox ||
        .singleSelect ||
        .multiSelect => _basic(column, value),
        .url => _formatted(value, _url),
        .email => _formatted(value, _email.hasMatch),
        .phone => _formatted(value, _phone),
        _ => _extra(column, value),
      };

  static bool _exact(WorkspaceColumnType type, Object? value) => switch (type) {
    .dateOnly => WorkspaceExactValueValidation.date(value),
    .timestamp => WorkspaceExactValueValidation.timestamp(value),
    .money => WorkspaceExactValueValidation.money(value),
    _ => false,
  };

  static bool _basic(WorkspaceColumn column, Object? value) =>
      switch (column.type) {
        .text => _text(value),
        .number => value is num && value.isFinite,
        .checkbox => value is bool,
        .singleSelect => _single(column.options, value),
        .multiSelect => _multiple(column.options, value),
        _ => false,
      };

  static bool _single(List<String> options, Object? value) =>
      value is String && options.contains(value);

  static bool _formatted(Object? value, bool Function(String) matches) =>
      value is String && _text(value) && matches(value);

  static bool _text(Object? value) =>
      value is String && value.length <= _maximumTextLength;

  static bool _multiple(List<String> options, Object? value) =>
      value is List &&
      value.toSet().length == value.length &&
      value.every((entry) => entry is String && options.contains(entry));

  static bool _phone(String value) =>
      _phonePattern.hasMatch(value) &&
      RegExp('[0-9]').allMatches(value).length >= _minimumPhoneDigits;

  static bool _url(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        _webScheme(uri.scheme) &&
        uri.host.isNotEmpty &&
        !value.contains(RegExp(r'\s'));
  }

  static bool _webScheme(String scheme) =>
      scheme == 'https' || scheme == 'http';
}

bool _extra(WorkspaceColumn column, Object? value) => switch (column.type) {
  .reference => WorkspaceReferenceValue.valid(column, value),
  .attachment => _AttachmentValidation.valid(value),
  _ => _ValueValidation._exact(column.type, value),
};

abstract final class _AttachmentValidation {
  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static bool valid(Object? value) =>
      value is List &&
      value.length <= _maximumColumns &&
      value.toSet().length == value.length &&
      value.every(_validId);

  static bool _validId(Object? id) => id is String && _id.hasMatch(id);
}

bool _validParent(WorkspaceColumn? parent, String id) =>
    parent != null &&
    parent.id != id &&
    parent.type == .reference &&
    !parent.referenceMultiple &&
    parent.dependsOnColumnId == null;

void _dependency(List<WorkspaceColumn> columns, WorkspaceColumn column) {
  if (column.dependsOnColumnId == null && column.targetMatchColumnId == null) {
    return;
  }
  final parent = _findParent(columns, column.dependsOnColumnId);
  WorkspaceColumnValidation._require(
    column.type == .reference && column.targetMatchColumnId?.isNotEmpty == true,
  );
  WorkspaceColumnValidation._require(_validParent(parent, column.id));
}

bool _validLabel(List<WorkspaceColumn> columns, String id) =>
    columns.any((column) => column.id == id && column.type == .text);

WorkspaceColumn? _findParent(List<WorkspaceColumn> columns, String? id) =>
    columns.where((column) => column.id == id).firstOrNull;
