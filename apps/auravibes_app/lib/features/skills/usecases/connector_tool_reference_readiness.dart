import 'dart:collection';

import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class ConnectorToolReferenceReadiness {
  /// Returns one status per input tool ID, preserving order and duplicates.
  static Future<List<SkillToolAccessStatus>> readinessForTools({
    required Iterable<String> connectorToolIds,
    required String workspaceId,
    required ListConnectorConnectionCandidatesUsecase credentialCandidates,
  }) async {
    final toolIds = connectorToolIds.toList(growable: false);
    final results = List<SkillToolAccessStatus>.filled(
      toolIds.length,
      SkillToolAccessStatus.available,
    );
    final connectorGroups = LinkedHashMap<
      String,
      ({ConnectorDefinition connector, List<int> toolIndexes})
    >();

    for (var index = 0; index < toolIds.length; index++) {
      final match = _findConnectorTool(toolIds[index]);
      if (match == null) {
        results[index] = .missing;
        continue;
      }

      final connector = match.connector;
      if (!match.tool.requiresConnection) continue;

      // The candidate repository scopes reads by connector ID and compatible
      // providers. Credential schema equality alone does not imply a shared pool.
      // Tools under one connector share the same candidate pool.
      final group = connectorGroups.putIfAbsent(
        connector.identifier,
        () => (connector: connector, toolIndexes: <int>[]),
      );
      group.toolIndexes.add(index);
    }

    for (final group in connectorGroups.values) {
      var status = SkillToolAccessStatus.unknown;
      try {
        final candidates = await credentialCandidates.forConnector(
          workspaceId: workspaceId,
          connector: group.connector,
        );
        status = candidates.isEmpty ? .missing : .available;
      } on Object {
        // A read failure affects this connector's tools only.
      }

      for (final index in group.toolIndexes) {
        results[index] = status;
      }
    }

    return results;
  }

  static Future<bool> areReady({
    required Iterable<String> connectorToolIds,
    required String workspaceId,
    required ListConnectorConnectionCandidatesUsecase credentialCandidates,
  }) async {
    final checkedConnectorIds = <String>{};
    for (final toolId in connectorToolIds) {
      final match = _findConnectorTool(toolId);
      if (match == null) return false;

      final connector = match.connector;
      if (!match.tool.requiresConnection ||
          !checkedConnectorIds.add(connector.identifier)) {
        continue;
      }

      if ((await credentialCandidates.forConnector(
        workspaceId: workspaceId,
        connector: connector,
      )).isEmpty) {
        return false;
      }
    }

    return true;
  }

  static ({ConnectorDefinition connector, ConnectorToolDefinition tool})?
  _findConnectorTool(String toolId) {
    for (final connector in connectorDefinitions) {
      final tool = connector.tools
          .where(
            (tool) =>
                tool.urlTemplate != null &&
                connectorToolId(connector, tool) == toolId,
          )
          .firstOrNull;
      if (tool != null) return (connector: connector, tool: tool);
    }

    return null;
  }
}
