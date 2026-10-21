import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

abstract final class ConnectorToolReferenceReadiness {
  static Future<bool> areReady({
    required Iterable<String> connectorToolIds,
    required String workspaceId,
    required ListConnectorConnectionCandidatesUsecase credentialCandidates,
  }) async {
    for (final toolId in connectorToolIds) {
      final match = _findConnectorTool(toolId);
      if (match == null) return false;

      final connector = match.connector;
      final tool = match.tool;
      if (tool.requiresConnection &&
          (await credentialCandidates.forConnector(
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
