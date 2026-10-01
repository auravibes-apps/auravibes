import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

/// Called only while holding the workspace mutation lock. Reads metadata only.
class CredentialDefinitionSafety {
  static Future<void> validate(
    Session session, {
    required WorkspacePatchOperation operation,
    required WorkspaceResource? existing,
    required int workspaceId,
    required Transaction transaction,
  }) async {
    if (operation.resourceKind != WorkspaceResourceKind.skillDefinition) return;
    final next = operation.operation == WorkspacePatchOperationKind.delete
        ? null
        : _schema(operation.data!);
    if (existing == null) return;
    final credentials = await _resources(
      session,
      workspaceId,
      WorkspaceResourceKind.serviceConnection,
      transaction,
    );
    final linked = credentials.where((row) {
      final data = _data(row.data);

      return data['kind'] == 'skillCredential' &&
          data['credentialDefinitionId'] == operation.resourceId;
    });
    if (next != null) {
      if (linked.isNotEmpty &&
          _incompatible(_previousSchema(existing.data), next)) {
        _conflict();
      }
      return;
    }
    if (linked.isNotEmpty) _conflict();
    final skills = await _resources(
      session,
      workspaceId,
      WorkspaceResourceKind.skill,
      transaction,
    );
    final parents = {
      for (final row in skills)
        row.resourceId:
            _data(row.data)['credentialDefinitionId'] ??
            _data(row.data)['skillDefinitionId'],
    };
    if (parents.values.contains(operation.resourceId)) _conflict();
    final tools = await _resources(
      session,
      workspaceId,
      WorkspaceResourceKind.skillTemplateTool,
      transaction,
    );
    for (final row in tools) {
      final data = _data(row.data);
      if ((data['credentialDefinitionId'] ?? parents[data['skillId']]) ==
          operation.resourceId) {
        _conflict();
      }
    }
  }

  static Future<List<WorkspaceResource>> _resources(
    Session session,
    int workspaceId,
    WorkspaceResourceKind kind,
    Transaction transaction,
  ) => WorkspaceResource.db.find(
    session,
    where: (t) =>
        t.workspaceId.equals(workspaceId) &
        t.resourceKind.equals(kind) &
        t.deletedAt.equals(null),
    transaction: transaction,
  );

  static Map<String, dynamic> _data(String value) =>
      jsonDecode(value) as Map<String, dynamic>;

  static Map<String, SkillCredentialAttributeDefinition> _schema(String value) {
    final schema = _data(value)['attributesJson'];
    if (schema is! String) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
    try {
      return SkillCredentialAttributeDefinition.validateDefinitionMap(schema);
    } on FormatException {
      throw CloudWorkspaceException(code: .validationFailed);
    }
  }

  static Map<String, SkillCredentialAttributeDefinition> _previousSchema(
    String value,
  ) => SkillCredentialAttributeDefinition.parseMap(
    _data(value)['attributesJson'] as String,
  );

  static bool _incompatible(
    Map<String, SkillCredentialAttributeDefinition> previous,
    Map<String, SkillCredentialAttributeDefinition> next,
  ) =>
      previous.entries.any((entry) {
        final current = next[entry.key];

        return current == null ||
            (entry.value.optional && !current.optional) ||
            entry.value.secret != current.secret;
      }) ||
      next.entries.any(
        (entry) => !previous.containsKey(entry.key) && !entry.value.optional,
      );

  static Never _conflict() => throw CloudWorkspaceException(code: .conflict);
}
