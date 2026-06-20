import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_credentials_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

final _logger = Logger('repository:skill_credentials');

class SkillCredentialsRepository {
  SkillCredentialsRepository({
    required AppDatabase database,
    required this._encryptionService,
  }) : _database = database,
       _dao = database.skillCredentialsDao,
       super();

  final AppDatabase _database;
  final SkillCredentialsDao _dao;
  final EncryptionService _encryptionService;

  Future<List<SkillCredentialEntity>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
  }) async {
    final rows = await _dao.getCredentialsForDefinition(
      workspaceId: workspaceId,
      credentialDefinitionId: credentialDefinitionId,
    );

    return Future.wait(rows.map(_tableToEntity));
  }

  Stream<List<SkillCredentialEntity>> watchCredentialsForWorkspace(
    String workspaceId,
  ) {
    return _dao
        .watchCredentialsForWorkspace(workspaceId)
        .asyncMap(
          (rows) => Future.wait(rows.map(_tableToEntity)),
        );
  }

  Future<SkillCredentialEntity?> getCredentialById(String credentialId) async {
    final row = await _dao.getCredentialById(credentialId);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  Future<SkillCredentialForEdit?> getCredentialForEdit(
    String credentialId,
  ) async {
    final row = await _dao.getCredentialById(credentialId);
    if (row == null) return null;
    final secretAttributes = await _secretAttributes(row);
    final nonSecretAttributes = _nonSecretAttributes(row);
    final definitions = await _attributeDefinitions(row.serviceId);
    final secretDefinitions = definitions.entries.where(
      (entry) => entry.value.secret,
    );

    return SkillCredentialForEdit(
      id: row.id,
      workspaceId: row.workspaceId,
      credentialDefinitionId: row.serviceId,
      name: row.name,
      nonSecretAttributes: nonSecretAttributes,
      secretAttributes: {
        for (final entry in secretDefinitions)
          entry.key: SkillCredentialSecretState(
            hasValue: secretAttributes[entry.key]?.isNotEmpty == true,
            keySuffix: _keySuffix([secretAttributes[entry.key] ?? '']),
          ),
      },
      isEnabled: row.isEnabled,
      keySuffix: row.keySuffix,
    );
  }

  Future<SkillCredentialEntity> createCredential(
    String workspaceId,
    SkillCredentialToCreate credential,
  ) async {
    final definitions = await _attributeDefinitions(
      credential.credentialDefinitionId,
    );
    final split = _splitAttributes(credential.attributes, definitions);
    _validateRequiredAttributes(
      definitions: definitions,
      secretAttributes: split.secret,
      nonSecretAttributes: split.nonSecret,
    );
    final encryptedAttributes = split.secret.isEmpty
        ? null
        : await _encryptionService.encrypt(jsonEncode(split.secret));
    final keySuffix = _keySuffix(split.secret.values);
    final row = await _dao.createCredential(
      ServiceConnectionsCompanion(
        name: Value(credential.name),
        serviceId: Value(credential.credentialDefinitionId),
        kind: const Value(ServiceConnectionKindTable.skillCredential),
        authenticationType: const Value(ServiceAuthenticationTypeTable.apiKey),
        encryptedAuthValue: Value(encryptedAttributes),
        keySuffix: Value(keySuffix),
        metadataJson: Value(_metadataJson(split.nonSecret)),
        workspaceId: Value(workspaceId),
      ),
    );

    return _tableToEntity(row);
  }

  Future<SkillCredentialEntity> updateCredential(
    String credentialId,
    SkillCredentialToUpdate credential,
  ) async {
    final row = await _dao.getCredentialById(credentialId);
    if (row == null) {
      throw StateError('Skill credential not found: $credentialId');
    }
    final definitions = await _attributeDefinitions(row.serviceId);
    final existingSecrets = await _secretAttributes(row);
    final nextSecrets = {...existingSecrets};
    credential.clearSecretAttributeNames.forEach(nextSecrets.remove);
    for (final entry in credential.secretAttributes.entries) {
      nextSecrets[entry.key] = entry.value;
    }
    nextSecrets.removeWhere((key, _) => definitions[key]?.secret != true);

    final nextNonSecrets = {
      ..._nonSecretAttributes(row),
      for (final entry in credential.nonSecretAttributes.entries)
        if (definitions[entry.key]?.secret == false) entry.key: entry.value,
    };
    _validateRequiredAttributes(
      definitions: definitions,
      secretAttributes: nextSecrets,
      nonSecretAttributes: nextNonSecrets,
    );
    final encryptedAttributes = nextSecrets.isEmpty
        ? null
        : await _encryptionService.encrypt(jsonEncode(nextSecrets));
    final updated = await _dao.updateCredential(
      credentialId,
      ServiceConnectionsCompanion(
        name: Value.absentIfNull(credential.name),
        encryptedAuthValue: Value(encryptedAttributes),
        keySuffix: Value(_keySuffix(nextSecrets.values)),
        metadataJson: Value(_metadataJson(nextNonSecrets)),
      ),
    );
    if (updated == null) {
      throw StateError('Skill credential not found: $credentialId');
    }

    return _tableToEntity(updated);
  }

  Future<void> deleteCredential(String credentialId) async {
    _logger.info(
      'debug:skill credential delete start credentialId=$credentialId',
    );
    final deletedRows = await _dao.deleteCredential(credentialId);
    if (deletedRows == 0) {
      _logger.warning(
        'debug:skill credential delete no rows matched '
        'credentialId=$credentialId',
      );

      return;
    }
    _logger.info(
      'debug:skill credential delete success credentialId=$credentialId '
      'deletedRows=$deletedRows',
    );
  }

  Future<SkillCredentialEntity> _tableToEntity(
    ServiceConnectionTable table,
  ) async {
    final attributes = {
      ..._nonSecretAttributes(table),
      ...await _secretAttributes(table),
    };

    return SkillCredentialEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      credentialDefinitionId: table.serviceId,
      name: table.name,
      attributes: attributes,
      isEnabled: table.isEnabled,
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      keySuffix: table.keySuffix,
    );
  }

  String? _keySuffix(Iterable<String> values) {
    final firstSecret = values.where((value) => value.isNotEmpty).firstOrNull;
    if (firstSecret == null) return null;

    return firstSecret.lastCharacters(6);
  }

  Future<Map<String, SkillCredentialAttributeDefinition>> _attributeDefinitions(
    String credentialDefinitionId,
  ) async {
    final definition = await _database.skillCredentialDefinitionsDao
        .getDefinitionById(credentialDefinitionId);
    if (definition == null) return const {};

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }

  ({Map<String, String> secret, Map<String, String> nonSecret})
  _splitAttributes(
    Map<String, String> attributes,
    Map<String, SkillCredentialAttributeDefinition> definitions,
  ) {
    final secret = <String, String>{};
    final nonSecret = <String, String>{};
    for (final entry in attributes.entries) {
      if (definitions[entry.key]?.secret == false) {
        nonSecret[entry.key] = entry.value;
      } else {
        secret[entry.key] = entry.value;
      }
    }

    return (secret: secret, nonSecret: nonSecret);
  }

  void _validateRequiredAttributes({
    required Map<String, SkillCredentialAttributeDefinition> definitions,
    required Map<String, String> secretAttributes,
    required Map<String, String> nonSecretAttributes,
  }) {
    for (final entry in definitions.entries) {
      final definition = entry.value;
      if (definition.optional) continue;
      final value = definition.secret
          ? secretAttributes[entry.key]
          : nonSecretAttributes[entry.key];
      if (value == null || value.trim().isEmpty) {
        throw FormatException(
          'Credential attribute is required: ${entry.key}.',
        );
      }
    }
  }

  Future<Map<String, String>> _secretAttributes(
    ServiceConnectionTable table,
  ) async {
    final encryptedValue = table.encryptedAuthValue;
    if (encryptedValue == null || encryptedValue.isEmpty) return {};
    final decryptedValue = await _encryptionService.decrypt(encryptedValue);
    final decoded = jsonDecode(decryptedValue);

    return decoded is Map
        ? decoded.map((key, value) => MapEntry('$key', '$value'))
        : <String, String>{};
  }

  Map<String, String> _nonSecretAttributes(ServiceConnectionTable table) {
    final metadata = table.metadataJson;
    if (metadata == null || metadata.isEmpty) return {};
    final decoded = jsonDecode(metadata);
    if (decoded is! Map) return {};
    final attributes = decoded['attributes'];
    if (attributes is! Map) return {};

    return attributes.map((key, value) => MapEntry('$key', '$value'));
  }

  String _metadataJson(Map<String, String> attributes) {
    return jsonEncode({'attributes': attributes});
  }
}
