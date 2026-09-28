import 'package:auravibes_app/features/skills/usecases/credential_schema_change.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

export 'package:auravibes_app/features/skills/usecases/credential_schema_change.dart';
export 'package:auravibes_app/features/skills/usecases/credential_schema_change_kind.dart';

class CredentialDefinitionSchema {
  static Map<String, SkillCredentialAttributeDefinition> validate(
    String attributesJson,
  ) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      attributesJson,
    );
    if (!attributes.values.any((attribute) => attribute.secret)) {
      throw const CredentialDefinitionValidationException();
    }

    return attributes;
  }

  static List<CredentialSchemaChange> diff(
    Map<String, SkillCredentialAttributeDefinition> previous,
    Map<String, SkillCredentialAttributeDefinition> next,
  ) => [
    for (final entry in previous.entries)
      if (next[entry.key] case final current?) ...[
        if (entry.value.optional && !current.optional)
          CredentialSchemaChange(entry.key, .required),
        if (entry.value.secret != current.secret)
          CredentialSchemaChange(entry.key, .secretChanged),
      ] else
        CredentialSchemaChange(entry.key, .removed),
  ];

  static List<CredentialSchemaChange> diffJson(
    String previousJson,
    Map<String, SkillCredentialAttributeDefinition> next,
  ) => diff(SkillCredentialAttributeDefinition.parseMap(previousJson), next);
}

enum CredentialDefinitionConflictReason { schemaChange, deletion }

class const CredentialDefinitionConflictException({
  required final CredentialDefinitionConflictReason reason,
  required final int credentialCount,
  final int skillCount = 0,
  final int toolCount = 0,
  final List<CredentialSchemaChange> changes = const [],
}) implements Exception {
  String get localizationKey => switch (reason) {
    .schemaChange => LocaleKeys.skill_credentials_definitions_schema_conflict,
    .deletion => LocaleKeys.skill_credentials_definitions_delete_conflict,
  };

  Map<String, String> localizationArguments() => {
    'credentials': '$credentialCount',
    'skills': '$skillCount',
    'tools': '$toolCount',
    'fields': changes.map((change) => change.variable).toSet().join(', '),
  };

  Map<String, Object> toManagerResult() => {
    'status': 'conflict',
    'reason': reason.name,
    'affectedCredentialCount': credentialCount,
    'affectedSkillCount': skillCount,
    'affectedTemplateToolCount': toolCount,
    'destructiveFields': [
      for (final change in changes)
        {'variable': change.variable, 'change': change.kind.name},
    ],
  };

  @override
  String toString() =>
      'Credential definition $reason conflicts with '
      '$credentialCount linked credentials.';
}

class const CredentialDefinitionValidationException() implements Exception {
  String get localizationKey =>
      LocaleKeys.skill_credentials_definitions_secret_required;

  @override
  String toString() => 'Credential definition requires a secret attribute.';
}
