import 'dart:convert';

class const SkillTemplateInputDefinition({
  required final String description,
  final String type = 'string',
  final bool optional = false,
}) {
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
