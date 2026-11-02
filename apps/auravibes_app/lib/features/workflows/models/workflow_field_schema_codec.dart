import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:uuid/v7.dart';

abstract final class WorkflowFieldSchemaCodec {
  static List<WorkflowField>? parse(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      final properties = decoded['properties'];
      if (properties is! Map) return null;
      final required = (decoded['required'] as List? ?? const [])
          .whereType<String>()
          .toSet();

      return [
        for (final entry in properties.entries)
          if (entry.key is String)
            _parseField(entry.key as String, entry.value, required),
      ];
    } on Object {
      return null;
    }
  }

  static String encode(List<WorkflowField> fields) => jsonEncode({
    'type': 'object',
    'properties': {for (final field in fields) field.name: _encodeField(field)},
    'required': [
      for (final field in fields)
        if (field.isRequired) field.name,
    ],
  });

  static WorkflowField _parseField(
    String name,
    Object? value,
    Set<String> required,
  ) {
    final schema = value is Map ? value : const <Object?, Object?>{};
    final rawType = schema['type'];
    final types = rawType is List ? rawType : [rawType];
    final type = _valueType(types);
    final properties = schema['properties'];
    final nestedRequired = (schema['required'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    final items = schema['items'];

    return WorkflowField(
      id: const UuidV7().generate(),
      name: name,
      type: type,
      isRequired: required.contains(name),
      description: schema['description'] as String? ?? '',
      nullable: schema['nullable'] == true || types.contains('null'),
      hasDefaultValue: schema.containsKey('default'),
      defaultValue: schema['default'],
      properties: type == .object && properties is Map
          ? [
              for (final entry in properties.entries)
                if (entry.key is String)
                  _parseField(entry.key as String, entry.value, nestedRequired),
            ]
          : const [],
      items: type == .array && items is Map
          ? _parseField('item', items, const {})
          : null,
    );
  }

  static WorkflowValueType _valueType(List<Object?> types) {
    for (final value in types) {
      final type = switch (value) {
        'string' => WorkflowValueType.string,
        'integer' => WorkflowValueType.integer,
        'number' => WorkflowValueType.number,
        'boolean' => WorkflowValueType.boolean,
        'object' => WorkflowValueType.object,
        'array' => WorkflowValueType.array,
        _ => null,
      };
      if (type != null) return type;
    }

    return .any;
  }

  static Map<String, Object?> _encodeField(WorkflowField field) => {
    if (field.type != .any)
      'type': field.nullable ? [field.type.name, 'null'] : field.type.name,
    if (field.type == .any && field.nullable) 'nullable': true,
    if (field.description.isNotEmpty) 'description': field.description,
    if (field.hasDefaultValue) 'default': field.defaultValue,
    if (field.type == .object) ...{
      'properties': {
        for (final child in field.properties) child.name: _encodeField(child),
      },
      'required': [
        for (final child in field.properties)
          if (child.isRequired) child.name,
      ],
    },
    if (field.type == .array && field.items != null)
      'items': _encodeField(field.items!),
  };
}
