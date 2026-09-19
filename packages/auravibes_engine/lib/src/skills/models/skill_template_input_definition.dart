import 'dart:convert';

class const SkillTemplateInputDefinition({
  required final String description,
  final String type = 'string',
  final bool optional = false,
  final bool additionalProperties = true,
  final Object? defaultValue,
  final List<Object?> enumValues = const [],
  final num? minimum,
  final num? maximum,
  final SkillTemplateInputDefinition? items,
  final Map<String, SkillTemplateInputDefinition> properties = const {},
}) {
  factory fromJson(Map<Object?, Object?> value) {
    final properties = value['properties'];
    final required = value['required'];
    final requiredNames = required is List
        ? required.whereType<String>().toSet()
        : const <String>{};
    final propertyMap = properties is Map
        ? properties.map((key, value) {
            if (value is! Map) {
              throw const FormatException(
                'Nested input definition must be an object.',
              );
            }
            return MapEntry(
              '$key',
              SkillTemplateInputDefinition.fromJson(value),
            );
          })
        : const <String, SkillTemplateInputDefinition>{};
    final enumValue = value['enum'];
    final items = value['items'];

    return SkillTemplateInputDefinition(
      description: '${value['description'] ?? ''}',
      type: '${value['type'] ?? 'string'}',
      optional: value['optional'] == true,
      additionalProperties: value['additionalProperties'] != false,
      defaultValue: value.containsKey('default') ? value['default'] : null,
      enumValues: enumValue is List
          ? List<Object?>.unmodifiable(enumValue)
          : const [],
      minimum: value['minimum'] as num?,
      maximum: value['maximum'] as num?,
      items: items is Map ? SkillTemplateInputDefinition.fromJson(items) : null,
      properties: propertyMap.map(
        (key, value) => MapEntry(
          key,
          value.copyWith(optional: !requiredNames.contains(key)),
        ),
      ),
    );
  }

  static Map<String, SkillTemplateInputDefinition> fromJsonSchema(
    Map<Object?, Object?> value,
  ) {
    final properties = value['properties'];
    if (properties is! Map) return const {};
    final required = value['required'];
    final requiredNames = required is List
        ? required.whereType<String>().toSet()
        : const <String>{};
    return properties.map((key, value) {
      if (value is! Map) {
        throw const FormatException('Input schema property must be an object.');
      }
      return MapEntry(
        '$key',
        SkillTemplateInputDefinition.fromJson(value)
            .copyWith(optional: !requiredNames.contains('$key')),
      );
    });
  }

  static Map<String, SkillTemplateInputDefinition> parseMap(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Inputs must be a JSON object.');
    }

    return decoded.map((key, value) {
      if (value is! Map) {
        throw const FormatException('Input definition must be an object.');
      }

      return MapEntry('$key', SkillTemplateInputDefinition.fromJson(value));
    });
  }

  // ignore: unnecessary-nullable, null means retain the existing field value.
  SkillTemplateInputDefinition copyWith({
    String? description,
    String? type,
    bool? optional,
    bool? additionalProperties,
    Object? defaultValue = _unset,
    List<Object?>? enumValues,
    num? minimum,
    num? maximum,
    SkillTemplateInputDefinition? items,
    Map<String, SkillTemplateInputDefinition>? properties,
  }) => SkillTemplateInputDefinition(
    description: description ?? this.description,
    type: type ?? this.type,
    optional: optional ?? this.optional,
    additionalProperties: additionalProperties ?? this.additionalProperties,
    defaultValue: identical(defaultValue, _unset)
        ? this.defaultValue
        : defaultValue,
    enumValues: enumValues ?? this.enumValues,
    minimum: minimum ?? this.minimum,
    maximum: maximum ?? this.maximum,
    items: items ?? this.items,
    properties: properties ?? this.properties,
  );

  Map<String, Object?> toJson() => {
    'type': type,
    if (description.isNotEmpty) 'description': description,
    if (optional) 'optional': true,
    if (type == 'object' && !additionalProperties)
      'additionalProperties': false,
    if (defaultValue != null) 'default': defaultValue,
    if (enumValues.isNotEmpty) 'enum': enumValues,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (items != null) 'items': items!.toJson(),
    if (properties.isNotEmpty)
      'properties': {
        for (final entry in properties.entries) entry.key: entry.value.toJson(),
      },
  };

  static const _unset = Object();
}
