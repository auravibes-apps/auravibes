import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show SkillCredentialAttributeDefinition;
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

final _logger = Logger('repository:skill_credentials');

typedef _CreateCredentialData = ({
  String workspaceId,
  SkillCredentialToCreate credential,
  String? encryptedAttributes,
  String? keySuffix,
  Map<String, String> nonSecretAttributes,
});

typedef _UpdateCredentialData = ({
  SkillCredentialToUpdate credential,
  String? encryptedAttributes,
  String? keySuffix,
  Map<String, String> nonSecretAttributes,
});

typedef _CredentialForEditData = ({
  ServiceConnectionTable row,
  Map<String, String> nonSecretAttributes,
  Map<String, String> secretAttributes,
  Map<String, SkillCredentialAttributeDefinition> definitions,
});

typedef _RequiredCredentialAttributeData = ({
  String key,
  SkillCredentialAttributeDefinition definition,
  Map<String, String> secretAttributes,
  Map<String, String> nonSecretAttributes,
});

class SkillCredentialsRepository({
  required final AppDatabase _database,
  required final EncryptionService _encryptionService,
}) {
  this : super();

  final SkillCredentialsDao _dao = _database.skillCredentialsDao;
  Future<List<SkillCredentialEntity>> getCredentialsForDefinition({
    required String workspaceId,
    required String credentialDefinitionId,
  }) async {
    final rows = await _dao.getCredentialsForDefinition(
      workspaceId: workspaceId,
      credentialDefinitionId: credentialDefinitionId,
    );

    return await Future.wait(rows.map(_tableToEntity));
  }

  Stream<List<SkillCredentialEntity>> watchCredentialsForWorkspace(
    String workspaceId,
  ) {
    return _dao
        .watchCredentialsForWorkspace(workspaceId)
        .asyncMap((rows) => Future.wait(rows.map(_tableToEntity)));
  }

  Future<SkillCredentialEntity?> getCredentialById(String credentialId) async {
    final row = await _dao.getCredentialById(credentialId);
    if (row == null) return null;

    return await _tableToEntity(row);
  }

  Future<Map<String, String>> readCredentialAttributes(
    String credentialId,
  ) async {
    final row = await _dao.getCredentialById(credentialId);
    if (row == null) {
      throw SkillCredentialsException.notFound(credentialId);
    }

    return {..._nonSecretAttributes(row), ...await _secretAttributes(row)};
  }

  Future<SkillCredentialForEdit?> getCredentialForEdit(
    String credentialId,
  ) async {
    final row = await _dao.getCredentialById(credentialId);
    if (row == null) return null;

    return await _buildCredentialForEdit(row);
  }

  Future<SkillCredentialEntity> createCredential(
    String workspaceId,
    SkillCredentialToCreate credential,
  ) async {
    final data = await _prepareCreateCredential(workspaceId, credential);
    final row = await _dao.createCredential(_createCredentialCompanion(data));

    return await _tableToEntity(row);
  }

  Future<SkillCredentialEntity> updateCredential(
    String credentialId,
    SkillCredentialToUpdate credential,
  ) async {
    final data = await _prepareUpdateCredential(credentialId, credential);
    final updated = await _dao.updateCredential(
      credentialId,
      _updateCredentialCompanion(data),
    );
    if (updated == null) {
      throw SkillCredentialsException.notFound(credentialId);
    }

    return await _tableToEntity(updated);
  }

  Future<void> deleteCredential(String credentialId) async {
    _logDeleteStart(credentialId);
    final deletedRows = await _dao.deleteCredential(credentialId);
    _logDeleteResult(credentialId, deletedRows);
  }
}

extension on SkillCredentialsRepository {
  Future<_CreateCredentialData> _prepareCreateCredential(
    String workspaceId,
    SkillCredentialToCreate credential,
  ) async {
    final split = await _validatedCreateAttributes(credential);

    return (
      workspaceId: workspaceId,
      credential: credential,
      encryptedAttributes: await _encryptAttributes(split.secret),
      keySuffix: _keySuffix(split.secret.values),
      nonSecretAttributes: split.nonSecret,
    );
  }

  Future<({Map<String, String> secret, Map<String, String> nonSecret})>
  _validatedCreateAttributes(SkillCredentialToCreate credential) async {
    final definitions = await _attributeDefinitions(
      credential.credentialDefinitionId,
    );
    final split = _splitAttributes(credential.attributes, definitions);
    _validateRequiredAttributes(
      definitions: definitions,
      secretAttributes: split.secret,
      nonSecretAttributes: split.nonSecret,
    );

    return split;
  }

  Future<_UpdateCredentialData> _prepareUpdateCredential(
    String credentialId,
    SkillCredentialToUpdate credential,
  ) async {
    final row = await _requireCredential(credentialId);
    final next = await _validatedUpdateAttributes(row, credential);

    return (
      credential: credential,
      encryptedAttributes: await _encryptAttributes(next.secret),
      keySuffix: _keySuffix(next.secret.values),
      nonSecretAttributes: next.nonSecret,
    );
  }

  Future<({Map<String, String> secret, Map<String, String> nonSecret})>
  _validatedUpdateAttributes(
    ServiceConnectionTable row,
    SkillCredentialToUpdate credential,
  ) async {
    final definitions = await _attributeDefinitions(row.serviceId);
    final existingSecrets = await _secretAttributes(row);
    final nextSecrets = _nextSecretAttributes(
      existingSecrets,
      credential,
      definitions,
    );
    final nextNonSecrets = _nextNonSecretAttributes(
      row,
      credential,
      definitions,
    );
    _validateRequiredAttributes(
      definitions: definitions,
      secretAttributes: nextSecrets,
      nonSecretAttributes: nextNonSecrets,
    );

    return (secret: nextSecrets, nonSecret: nextNonSecrets);
  }
}

extension SkillCredentialsRepositoryMapping on SkillCredentialsRepository {
  Future<SkillCredentialEntity> _tableToEntity(
    ServiceConnectionTable table,
  ) async {
    return SkillCredentialEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      credentialDefinitionId: table.serviceId,
      name: table.name,
      attributes: _nonSecretAttributes(table),
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
    if (definition == null) {
      throw SkillCredentialsException.definitionNotFound(
        credentialDefinitionId,
      );
    }

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }

  Future<ServiceConnectionTable> _requireCredential(String credentialId) async {
    return await _dao.getCredentialById(credentialId) ??
        (throw SkillCredentialsException.notFound(credentialId));
  }

  Future<SkillCredentialForEdit> _buildCredentialForEdit(
    ServiceConnectionTable row,
  ) async {
    final secretAttributes = await _secretAttributes(row);
    final nonSecretAttributes = _nonSecretAttributes(row);
    final definitions = await _attributeDefinitions(row.serviceId);

    return _credentialForEdit((
      row: row,
      nonSecretAttributes: nonSecretAttributes,
      secretAttributes: secretAttributes,
      definitions: definitions,
    ));
  }

  SkillCredentialForEdit _credentialForEdit(_CredentialForEditData data) {
    final row = data.row;
    final definitions = data.definitions;

    return SkillCredentialForEdit(
      id: row.id,
      workspaceId: row.workspaceId,
      credentialDefinitionId: row.serviceId,
      name: row.name,
      nonSecretAttributes: data.nonSecretAttributes,
      secretAttributes: _secretStates(definitions, data.secretAttributes),
      isEnabled: row.isEnabled,
      keySuffix: row.keySuffix,
    );
  }

  ServiceConnectionsCompanion _createCredentialCompanion(
    _CreateCredentialData data,
  ) => _createCredentialBase(data).copyWith(
    encryptedAuthValue: .new(data.encryptedAttributes),
    keySuffix: .new(data.keySuffix),
    metadataJson: .new(_metadataJson(data.nonSecretAttributes)),
  );

  ServiceConnectionsCompanion _createCredentialBase(
    _CreateCredentialData data,
  ) => ServiceConnectionsCompanion(
    name: .new(data.credential.name),
    serviceId: .new(data.credential.credentialDefinitionId),
    kind: const Value(ServiceConnectionKindTable.skillCredential),
    authenticationType: const Value(ServiceAuthenticationTypeTable.apiKey),
    workspaceId: .new(data.workspaceId),
  );
}

extension SkillCredentialsEncryption on SkillCredentialsRepository {
  Future<String?> _encryptAttributes(Map<String, String> attributes) async {
    if (attributes.isEmpty) return null;

    return await _encryptionService.encrypt(jsonEncode(attributes));
  }
}

extension SkillCredentialsUpdateMapping on SkillCredentialsRepository {
  ServiceConnectionsCompanion _updateCredentialCompanion(
    _UpdateCredentialData data,
  ) => ServiceConnectionsCompanion(
    name: .absentIfNull(data.credential.name),
    encryptedAuthValue: .new(data.encryptedAttributes),
    keySuffix: .new(data.keySuffix),
    metadataJson: .new(_metadataJson(data.nonSecretAttributes)),
  );
}

extension SkillCredentialsAttributeOperations on SkillCredentialsRepository {
  ({Map<String, String> secret, Map<String, String> nonSecret})
  _splitAttributes(
    Map<String, String> attributes,
    Map<String, SkillCredentialAttributeDefinition> definitions,
  ) {
    final secret = <String, String>{};
    final nonSecret = <String, String>{};
    for (final entry in attributes.entries) {
      final target = definitions[entry.key]?.secret == false
          ? nonSecret
          : secret;
      target[entry.key] = entry.value;
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
      _validateRequiredAttribute((
        key: entry.key,
        definition: definition,
        secretAttributes: secretAttributes,
        nonSecretAttributes: nonSecretAttributes,
      ));
    }
  }

  void _validateRequiredAttribute(_RequiredCredentialAttributeData data) {
    final attributes = data.definition.secret
        ? data.secretAttributes
        : data.nonSecretAttributes;
    final value = attributes[data.key];
    if (value == null || value.trim().isEmpty) {
      throw FormatException('Credential attribute is required: ${data.key}.');
    }
  }

  Map<String, SkillCredentialSecretState> _secretStates(
    Map<String, SkillCredentialAttributeDefinition> definitions,
    Map<String, String> secretAttributes,
  ) {
    final states = <String, SkillCredentialSecretState>{};
    for (final entry in definitions.entries) {
      if (!entry.value.secret) continue;
      final value = secretAttributes[entry.key];
      states[entry.key] = SkillCredentialSecretState(
        hasValue: value?.isNotEmpty == true,
        keySuffix: _keySuffix([value ?? '']),
      );
    }

    return states;
  }

  Map<String, String> _nextSecretAttributes(
    Map<String, String> existingSecrets,
    SkillCredentialToUpdate credential,
    Map<String, SkillCredentialAttributeDefinition> definitions,
  ) {
    final nextSecrets = {...existingSecrets};
    credential.clearSecretAttributeNames.forEach(nextSecrets.remove);
    nextSecrets
      ..addAll(credential.secretAttributes)
      ..removeWhere((key, _) => definitions[key]?.secret != true);

    return nextSecrets;
  }

  Map<String, String> _nextNonSecretAttributes(
    ServiceConnectionTable row,
    SkillCredentialToUpdate credential,
    Map<String, SkillCredentialAttributeDefinition> definitions,
  ) => {
    ..._nonSecretAttributes(row),
    for (final entry in credential.nonSecretAttributes.entries)
      if (definitions[entry.key]?.secret == false) entry.key: entry.value,
  };
}

extension SkillCredentialsAttributeDecoding on SkillCredentialsRepository {
  Future<Map<String, String>> _secretAttributes(
    ServiceConnectionTable table,
  ) async {
    final encryptedValue = table.encryptedAuthValue;
    if (encryptedValue == null || encryptedValue.isEmpty) return {};

    return _decodeSecretAttributes(
      await _encryptionService.decrypt(encryptedValue),
    );
  }

  Map<String, String> _decodeSecretAttributes(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) return {};

    return decoded.map((key, value) => MapEntry('$key', '$value'));
  }

  Map<String, String> _nonSecretAttributes(ServiceConnectionTable table) {
    final metadata = table.metadataJson;
    if (metadata == null || metadata.isEmpty) return {};

    return _decodeNonSecretAttributes(metadata);
  }

  Map<String, String> _decodeNonSecretAttributes(String metadata) {
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

class const SkillCredentialsException(final String message)
    implements Exception {
  factory notFound(String credentialId) {
    return SkillCredentialsException(
      'Skill credential not found: $credentialId',
    );
  }

  factory definitionNotFound(String definitionId) {
    return SkillCredentialsException(
      'Skill credential definition not found: $definitionId',
    );
  }

  @override
  String toString() => 'SkillCredentialsException: $message';

  bool isNotFound() => message.contains('not found');
}

void _logDeleteStart(String credentialId) {
  _logger.info(
    'debug:skill credential delete start credentialId=$credentialId',
  );
}

void _logDeleteResult(String credentialId, int deletedRows) {
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
