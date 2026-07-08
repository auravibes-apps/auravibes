import 'dart:convert';

class SkillCredentialAttributeDefinition {
  const SkillCredentialAttributeDefinition({
    required this.description,
    this.optional = false,
    this.secret = true,
  });

  final String description;
  final bool optional;
  final bool secret;

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
