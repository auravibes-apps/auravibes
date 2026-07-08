import 'dart:convert';

class SkillTemplateInputDefinition {
  const SkillTemplateInputDefinition({
    required this.description,
    this.type = 'string',
    this.optional = false,
  });

  final String description;
  final String type;
  final bool optional;

  static Map<String, SkillTemplateInputDefinition> parseMap(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Inputs must be a JSON object.');
    }

    return decoded.map((key, value) {
      if (value is! Map) {
        throw const FormatException('Input definition must be an object.');
      }

      return MapEntry(
        '$key',
        SkillTemplateInputDefinition(
          description: '${value['description'] ?? ''}',
          type: '${value['type'] ?? 'string'}',
          optional: value['optional'] == true,
        ),
      );
    });
  }
}
