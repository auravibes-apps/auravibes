import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'agent_catalog_cursor.dart';

class const AgentCatalogRow({
  required this.id,
  required this.name,
  required this.description,
  required this.isEnabled,
  required this.visibility,
  required this.skillCount,
}) {
  final String id;
  final String name;
  final String description;
  final bool isEnabled;
  final AgentCatalogVisibility visibility;
  final int skillCount;
}

class AgentCatalogRepository {
  Future<List<AgentCatalogRow>> list(
    Session session, {
    required int workspaceId,
    required String search,
    required AgentCatalogType? type,
    required AgentCatalogStatus? status,
    required int limit,
    required AgentCatalogCursor? cursor,
  }) async {
    final rows = await session.db.unsafeQuery(
      _listSql,
      parameters: QueryParameters.named({
        'workspaceId': workspaceId,
        'search': search,
        'type': type?.name ?? '',
        'status': status?.name ?? '',
        'hasCursor': cursor != null,
        'afterName': cursor?.name ?? '',
        'afterId': cursor?.id ?? '',
        'limit': limit,
      }),
    );

    return [
      for (final row in rows) _rowFromColumns(row.toColumnMap()),
    ];
  }

  Future<WorkspaceResource?> findAgent(
    Session session, {
    required int workspaceId,
    required String agentId,
  }) => WorkspaceResource.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.resourceKind.equals(WorkspaceResourceKind.agent) &
        table.resourceId.equals(agentId) &
        table.deletedAt.equals(null),
  );

  Future<List<WorkspaceResource>> findAssociations(
    Session session, {
    required int workspaceId,
    required String agentId,
  }) async {
    final rows = await session.db.unsafeQuery(
      _associationsSql,
      parameters: QueryParameters.named({
        'workspaceId': workspaceId,
        'agentId': agentId,
      }),
    );
    return [
      for (final row in rows) _resourceFromColumns(row.toColumnMap()),
    ];
  }
}

AgentCatalogRow _rowFromColumns(Map<String, dynamic> columns) =>
    AgentCatalogRow(
      id: columns['id']! as String,
      name: columns['name']! as String,
      description: columns['description']! as String,
      isEnabled: columns['isEnabled']! as bool,
      visibility: AgentCatalogVisibility.fromJson(
        columns['visibility']! as String,
      ),
      skillCount: columns['skillCount']! as int,
    );

WorkspaceResource _resourceFromColumns(Map<String, dynamic> columns) =>
    WorkspaceResource(
      id: columns['id']! as int,
      workspaceId: columns['workspaceId']! as int,
      resourceKind: WorkspaceResourceKind.fromJson(
        columns['resourceKind']! as String,
      ),
      resourceId: columns['resourceId']! as String,
      data: columns['data']! as String,
      revision: columns['revision']! as int,
      createdAt: columns['createdAt']! as DateTime,
      updatedAt: columns['updatedAt']! as DateTime,
      deletedAt: columns['deletedAt'] as DateTime?,
    );

const _listSql = r'''
WITH decoded AS (
  SELECT
    resource."resourceId" AS id,
    resource."data"::jsonb AS payload,
    lower((resource."data"::jsonb ->> 'name') COLLATE "C") AS normalized_name
  FROM workspace_resource AS resource
  WHERE resource."workspaceId" = @workspaceId
    AND resource."resourceKind" = 'agent'
    AND resource."deletedAt" IS NULL
), filtered AS (
  SELECT
    decoded.*,
    COALESCE(decoded.payload ->> 'name', '') AS name,
    COALESCE(decoded.payload ->> 'description', '') AS description,
    COALESCE((decoded.payload ->> 'isEnabled')::boolean, TRUE) AS is_enabled,
    COALESCE(decoded.payload ->> 'visibility', 'both') AS visibility
  FROM decoded
)
SELECT
  agent.id AS id,
  agent.name AS name,
  agent.description AS description,
  agent.is_enabled AS "isEnabled",
  agent.visibility AS visibility,
  (
    SELECT count(*)::bigint
    FROM workspace_resource AS association
    WHERE association."workspaceId" = @workspaceId
      AND association."resourceKind" = 'agentAssociation'
      AND association."deletedAt" IS NULL
      AND association."data"::jsonb ->> 'agentId' = agent.id
      AND association."data"::jsonb ? 'skillId'
  ) AS "skillCount"
FROM filtered AS agent
WHERE (
    @search = ''
    OR strpos(agent.normalized_name, @search) > 0
    OR strpos(lower(agent.description COLLATE "C"), @search) > 0
  )
  AND (
    @type = ''
    OR @type = 'chatSelector'
      AND agent.visibility IN ('chatSelector', 'both')
    OR @type = 'subAgentList'
      AND agent.visibility IN ('subAgentList', 'both')
  )
  AND (
    @status = ''
    OR @status = 'enabled' AND agent.is_enabled
    OR @status = 'disabled' AND NOT agent.is_enabled
  )
  AND (
    NOT @hasCursor
    OR agent.normalized_name > @afterName
    OR agent.normalized_name = @afterName AND agent.id > @afterId
  )
ORDER BY agent.normalized_name, agent.id
LIMIT @limit
''';

const _associationsSql = r'''
SELECT
  association.id,
  association."workspaceId",
  association."resourceKind",
  association."resourceId",
  association."data",
  association.revision,
  association."createdAt",
  association."updatedAt",
  association."deletedAt"
FROM workspace_resource AS association
WHERE association."workspaceId" = @workspaceId
  AND association."resourceKind" = 'agentAssociation'
  AND association."deletedAt" IS NULL
  AND association."data"::jsonb ->> 'agentId' = @agentId
ORDER BY association."resourceId"
''';
