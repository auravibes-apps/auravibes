import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../workspace_secret_cipher.dart';

/// Validates persisted values against the definition held by the workspace lock.
class CredentialWriteSafety {
  // The record distinguishes a prepared clear from a direct metadata patch,
  // which must load its currently stored workspace secret.
  static Future<void> validate(
    Session session, {
    required WorkspacePatchOperation operation,
    required int workspaceId,
    required Transaction transaction,
    ({String? value})? preparedSecret,
  }) async {
    if (operation.resourceKind != WorkspaceResourceKind.serviceConnection ||
        operation.operation == WorkspacePatchOperationKind.delete) {
      return;
    }
    final data = jsonDecode(operation.data!) as Map<String, dynamic>;
    if (data['kind'] != 'skillCredential') return;
    final fields = await _fields(session, workspaceId, data, transaction);
    final secret = preparedSecret != null
        ? preparedSecret.value
        : await _storedSecret(
            session,
            workspaceId,
            operation.resourceId,
            transaction,
          );
    try {
      _validateValues(
        fields,
        _attributes(data['attributes']),
        _attributes(secret == null ? null : jsonDecode(secret)),
      );
    } on FormatException {
      _invalid();
    }
  }

  static Future<void> validateSecret(
    Session session, {
    required PutWorkspaceSecretRequest request,
    required String? secret,
    required Transaction transaction,
  }) async {
    if (request.secretKind != WorkspaceSecretKind.skillCredential) return;
    final resource = await WorkspaceResource.db.findFirstRow(
      session,
      where: (t) =>
          t.workspaceId.equals(request.workspaceId) &
          t.resourceKind.equals(WorkspaceResourceKind.serviceConnection) &
          t.resourceId.equals(request.resourceId) &
          t.deletedAt.equals(null),
      transaction: transaction,
    );
    if (resource == null) _invalid();
    await validate(
      session,
      operation: WorkspacePatchOperation(
        operation: .update,
        resourceKind: .serviceConnection,
        resourceId: resource.resourceId,
        data: resource.data,
        fieldMask: [],
      ),
      workspaceId: request.workspaceId,
      transaction: transaction,
      preparedSecret: (value: secret),
    );
  }

  static Future<Map<String, SkillCredentialAttributeDefinition>> _fields(
    Session session,
    int workspaceId,
    Map<String, dynamic> data,
    Transaction transaction,
  ) async {
    final id = data['credentialDefinitionId'];
    if (id is! String) _invalid();
    final definition = await WorkspaceResource.db.findFirstRow(
      session,
      where: (t) =>
          t.workspaceId.equals(workspaceId) &
          t.resourceKind.equals(WorkspaceResourceKind.skillDefinition) &
          t.resourceId.equals(id) &
          t.deletedAt.equals(null),
      transaction: transaction,
    );
    if (definition == null) _invalid();
    try {
      final data = jsonDecode(definition.data) as Map<String, dynamic>;
      final schema = data['attributesJson'];
      if (schema is! String) _invalid();
      return SkillCredentialAttributeDefinition.validateDefinitionMap(schema);
    } on FormatException {
      _invalid();
    }
  }

  static Future<String?> _storedSecret(
    Session session,
    int workspaceId,
    String id,
    Transaction transaction,
  ) async {
    final secret = await WorkspaceSecret.db.findFirstRow(
      session,
      where: (t) =>
          t.workspaceId.equals(workspaceId) &
          t.secretKind.equals(WorkspaceSecretKind.skillCredential) &
          t.scope.equals(WorkspaceSecretScope.workspace) &
          t.resourceId.equals(id) &
          t.deletedAt.equals(null),
      transaction: transaction,
    );
    if (secret == null) return null;
    return const WorkspaceSecretCipher().decrypt(session, secret);
  }

  static Map<String, String> _attributes(Object? value) {
    if (value == null) return {};
    if (value is! Map<String, dynamic>) _invalid();
    final result = <String, String>{};
    for (final entry in value.entries) {
      final attribute = entry.value;
      if (attribute is! String) _invalid();
      result[entry.key] = attribute;
    }
    return result;
  }

  static void _validateValues(
    Map<String, SkillCredentialAttributeDefinition> fields,
    Map<String, String> metadata,
    Map<String, String> secret,
  ) {
    if (metadata.keys.any((key) => fields[key]?.secret != false) ||
        secret.keys.any((key) => fields[key]?.secret == false)) {
      _invalid();
    }
    for (final entry in fields.entries) {
      if (entry.value.optional) continue;
      final value = (entry.value.secret ? secret : metadata)[entry.key];
      if (value == null || value.trim().isEmpty) _invalid();
    }
  }

  static Never _invalid() =>
      throw CloudWorkspaceException(code: .validationFailed);
}
