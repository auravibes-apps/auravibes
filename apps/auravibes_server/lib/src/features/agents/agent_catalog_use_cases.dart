import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_state/repositories/workspace_state_repository.dart';
import 'agent_catalog_cursor.dart';
import 'agent_catalog_repository.dart';

class AgentCatalogUseCases(
  final AgentCatalogRepository _repository,
  final WorkspaceStateRepository _workspaceRepository, {
  AgentCatalogCursorCodec cursorCodec = const AgentCatalogCursorCodec(),
}) {
  final AgentCatalogCursorCodec _cursorCodec = cursorCodec;
}

final class _AgentCatalogRequest {
  const _AgentCatalogRequest({
    required this.workspaceId,
    required this.search,
    required this.type,
    required this.status,
    required this.limit,
    required this.cursor,
  });

  final int workspaceId;
  final String search;
  final AgentCatalogType? type;
  final AgentCatalogStatus? status;
  final int limit;
  final AgentCatalogCursor? cursor;
}

class _AgentCatalogPageBuilder {
  const _AgentCatalogPageBuilder(this.codec);

  final AgentCatalogCursorCodec codec;

  AgentCatalogPage call(
    _AgentCatalogRequest request,
    List<AgentCatalogRow> rows,
  ) {
    final hasMore = rows.length > request.limit;
    final pageRows = rows.take(request.limit).toList();
    return AgentCatalogPage(
      agents: [for (final row in pageRows) _item(row)],
      nextCursor: hasMore && pageRows.isNotEmpty
          ? codec.encode(_cursor(request, pageRows.last))
          : null,
    );
  }

  AgentCatalogItem _item(AgentCatalogRow row) => AgentCatalogItem(
    id: row.id,
    name: row.name,
    description: row.description,
    isEnabled: row.isEnabled,
    visibility: row.visibility,
    skillCount: row.skillCount,
  );

  AgentCatalogCursor _cursor(
    _AgentCatalogRequest request,
    AgentCatalogRow row,
  ) => AgentCatalogCursor(
    workspaceId: request.workspaceId,
    search: request.search,
    type: request.type?.name,
    status: request.status?.name,
    name: row.name.toLowerCase(),
    id: row.id,
  );
}

extension AgentCatalogUseCasesOperations on AgentCatalogUseCases {
  Future<AgentCatalogPage> list(
    Session session, {
    required String userId,
    required ListAgentsRequest request,
  }) async {
    await _authorize(session, workspaceId: request.workspaceId, userId: userId);
    final validated = _validate(request);
    final rows = await _repository.list(
      session,
      workspaceId: validated.workspaceId,
      search: validated.search,
      type: validated.type,
      status: validated.status,
      limit: validated.limit + 1,
      cursor: validated.cursor,
    );
    return _AgentCatalogPageBuilder(_cursorCodec)(validated, rows);
  }

  Future<List<WorkspaceResource>> getResources(
    Session session, {
    required String userId,
    required GetAgentResourcesRequest request,
  }) async {
    await _authorize(session, workspaceId: request.workspaceId, userId: userId);
    if (request.agentId.trim().isEmpty || request.agentId.length > 200) {
      _validationFailed();
    }
    final agent = await _repository.findAgent(
      session,
      workspaceId: request.workspaceId,
      agentId: request.agentId,
    );
    if (agent == null) return const [];

    return [
      agent,
      ...await _repository.findAssociations(
        session,
        workspaceId: request.workspaceId,
        agentId: request.agentId,
      ),
    ];
  }

  _AgentCatalogRequest _validate(ListAgentsRequest request) {
    final search = request.search.trim().toLowerCase();
    final cursorValue = request.cursor;
    if (request.limit < 1 ||
        request.limit > 100 ||
        search.length > 200 ||
        cursorValue != null && cursorValue.length > 2048) {
      _validationFailed();
    }
    AgentCatalogCursor? cursor;
    if (cursorValue != null) {
      try {
        cursor = _cursorCodec.decode(cursorValue);
      } on FormatException {
        _validationFailed();
      }
      if (cursor.workspaceId != request.workspaceId ||
          cursor.search != search ||
          cursor.type != request.type?.name ||
          cursor.status != request.status?.name ||
          cursor.name.isEmpty ||
          cursor.id.isEmpty) {
        _validationFailed();
      }
    }
    return _AgentCatalogRequest(
      workspaceId: request.workspaceId,
      search: search,
      type: request.type,
      status: request.status,
      limit: request.limit,
      cursor: cursor,
    );
  }

  Future<void> _authorize(
    Session session, {
    required int workspaceId,
    required String userId,
  }) async {
    final member = await _workspaceRepository.findMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
    );
    final workspace = await _workspaceRepository.findWorkspace(
      session,
      workspaceId,
    );
    if (member == null || workspace == null) {
      throw CloudWorkspaceException(
        code: CloudWorkspaceErrorCode.membershipRequired,
      );
    }
  }

  Never _validationFailed() => throw CloudWorkspaceException(
    code: CloudWorkspaceErrorCode.validationFailed,
  );
}
