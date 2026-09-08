import 'dart:convert';

class const SkillCredentialAttributeDefinition({
  required final String description,
  final bool optional = false,
  final bool secret = true,
}) {
  static Map<String, SkillCredentialAttributeDefinition> parseMap(
    String value,
  ) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException(
        'Credential attributes must be a JSON object.',
      );
    }

    return decoded.map((key, value) {
      if (value is! Map) {
        throw const FormatException(
          'Credential attribute definition must be an object.',
        );
      }

      return MapEntry(
        '$key',
        SkillCredentialAttributeDefinition(
          description: '${value['description'] ?? ''}',
          optional: value['optional'] == true,
          secret: value['secret'] != false,
        ),
      );
    });
  }
}
