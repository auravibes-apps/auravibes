import 'dart:convert';

/// Fields of a credential definition. A persisted definition must contain at
/// least one secret field; metadata-only definitions cannot back a credential.
class const ConnectorCredentialAttributeDefinition({
  required final String description,
  final bool optional = false,
  final bool secret = true,
}) {
  static Map<String, ConnectorCredentialAttributeDefinition> validateDefinitionMap(
    String value,
  ) {
    final attributes = parseMap(value);
    if (!attributes.values.any((attribute) => attribute.secret)) {
      throw const FormatException(
        'Credential definitions require at least one secret attribute.',
      );
    }
    return attributes;
  }

  static Map<String, ConnectorCredentialAttributeDefinition> parseMap(
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
        ConnectorCredentialAttributeDefinition(
          description: '${value['description'] ?? ''}',
          optional: value['optional'] == true,
          secret: value['secret'] != false,
        ),
      );
    });
  }
}
