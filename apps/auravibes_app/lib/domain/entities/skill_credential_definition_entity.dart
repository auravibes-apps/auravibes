import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_credential_definition_entity.freezed.dart';

@freezed
abstract class SkillCredentialDefinitionEntity
    with _$SkillCredentialDefinitionEntity {
  const factory SkillCredentialDefinitionEntity({
    required String id,
    required String workspaceId,
    required String title,
    required String slug,
    required String attributesJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SkillCredentialDefinitionEntity;
  const SkillCredentialDefinitionEntity._();
}

@freezed
abstract class SkillCredentialDefinitionToCreate
    with _$SkillCredentialDefinitionToCreate {
  const factory SkillCredentialDefinitionToCreate({
    required String title,
    required String attributesJson,
  }) = _SkillCredentialDefinitionToCreate;
  const SkillCredentialDefinitionToCreate._();
}

@freezed
abstract class SkillCredentialDefinitionToUpdate
    with _$SkillCredentialDefinitionToUpdate {
  const factory SkillCredentialDefinitionToUpdate({
    String? title,
    String? attributesJson,
  }) = _SkillCredentialDefinitionToUpdate;
  const SkillCredentialDefinitionToUpdate._();
}

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
