import 'dart:convert';

import 'package:auravibes_engine/src/agent_iteration_context.dart';
import 'package:auravibes_engine/src/agent_iteration_decision.dart';

const maxSubAgentTitleLength = 160;
const maxSubAgentPromptLength = 20000;

typedef ContinueSubAgentTurn = Future<AgentIterationDecision> Function({
  required String conversationId,
  required AgentIterationContext context,
});

typedef SubAgentChildStarted = void Function({
  required String parentId,
  required String childId,
});

class const SubAgentRunner({
  required final SubAgentCatalog agentCatalog,
  required final SubAgentConversationStore conversationStore,
  required final SubAgentMessageStore messageStore,
  required final StartSubAgentRequest startRequest,
  required final ContinueSubAgentTurn continueAgentTurn,
  final SubAgentChildStarted? onChildStarted,
}) {
  Future<String> listAgents(
    String workspaceId, {
    Map<String, dynamic> arguments = const {},
  }) async {
    late final SubAgentCatalogQuery query;
    try {
      query = SubAgentCatalogQuery.fromArguments(workspaceId, arguments);
    } on FormatException catch (error) {
      return _error(error.message);
    }
    final page = await agentCatalog.listSubAgents(query);

    return jsonEncode({
      'agents': [
        for (final agent in page.agents)
          {
            'id': agent.id,
            'name': agent.name,
            'description': agent.description,
            'types': agent.types,
          },
      ],
      'nextCursor': page.nextCursor,
    });
  }

  Future<String> run({
    required String parentConversationId,
    required String workspaceId,
    required Map<String, dynamic> arguments,
  }) async {
    final request = _SubAgentRunRequest.from(arguments);
    if (request.error != null) return _error(request.error!);

    final parent = await conversationStore.getConversation(
      parentConversationId,
    );
    final parentError = _parentError(parent, workspaceId);
    if (parentError != null) return _error(parentError);

    final agentError = await _agentError(request.agentId, workspaceId);
    if (agentError != null) return agentError;

    final child = await conversationStore.createChildConversation((
      parentConversationId: parentConversationId,
      workspaceId: workspaceId,
      modelId: parent!.modelId,
      agentId: request.agentId,
      title: request.title,
    ));
    final requestHandle = startRequest(
      parentId: parentConversationId,
      childId: child.id,
    );
    onChildStarted?.call(parentId: parentConversationId, childId: child.id);
    var completionStatus = SubAgentCompletionStatus.done;
    try {
      final message = await messageStore.createUserPrompt(
        conversationId: child.id,
        prompt: request.prompt,
      );
      final decision = await continueAgentTurn(
        conversationId: child.id,
        context: AgentIterationContext(
          origin: .userMessage,
          ackMessageIds: [message.id],
        ),
      );
      if (requestHandle.isStopped) {
        completionStatus = SubAgentCompletionStatus.stopped;

        return await _result(child.id, 'stopped', agentId: request.agentId);
      }
      if (decision == AgentIterationDecision.waitForToolApproval) {
        final waitResult = await _waitForToolApproval(
          requestHandle,
          child.id,
          request.agentId,
        );
        if (waitResult != null) {
          completionStatus = waitResult.status;

          return waitResult.content;
        }
      }

      return await _result(child.id, 'done', agentId: request.agentId);
    } on Object {
      completionStatus = SubAgentCompletionStatus.error;

      return _failedResult(child.id, request.agentId);
    } finally {
      requestHandle.finish(completionStatus);
    }
  }

  String? _parentError(SubAgentConversationRecord? parent, String workspaceId) {
    if (parent == null || parent.workspaceId != workspaceId) {
      return 'Parent conversation not found.';
    }
    if (parent.parentConversationId != null) {
      return 'Sub-agents cannot start sub-agents.';
    }

    return null;
  }

  Future<String?> _agentError(String? agentId, String workspaceId) async {
    if (agentId == null) return null;

    final agent = await agentCatalog.getSubAgent(agentId);
    if (agent == null || agent.workspaceId != workspaceId) {
      return _error('Unknown agent.', agentId: agentId);
    }

    return null;
  }

  Future<_SubAgentWaitResult?> _waitForToolApproval(
    SubAgentRequestHandle requestHandle,
    String conversationId,
    String? agentId,
  ) async {
    final status = await requestHandle.completion;
    if (status == SubAgentCompletionStatus.stopped) {
      return _SubAgentWaitResult(
        .stopped,
        await _result(conversationId, 'stopped', agentId: agentId),
      );
    }
    if (status == SubAgentCompletionStatus.error) {
      return _SubAgentWaitResult(
        .error,
        _failedResult(conversationId, agentId),
      );
    }

    return null;
  }

  Future<String> _result(
    String conversationId,
    String status, {
    String? agentId,
  }) async {
    final assistant = await messageStore.latestAssistantContent(conversationId);

    return jsonEncode({
      'conversationId': conversationId,
      'status': status,
      'content': assistant,
      'agentId': ?agentId,
    });
  }

  String _failedResult(String conversationId, String? agentId) {
    return jsonEncode({
      'conversationId': conversationId,
      'status': 'error',
      'content': 'Sub-agent failed.',
      'agentId': ?agentId,
    });
  }
}

final class const _SubAgentWaitResult(
  final SubAgentCompletionStatus status,
  final String content,
);

final class _SubAgentRunRequest {
  const new({required this.title, required this.prompt, required this.agentId})
    : error = null;

  factory from(Map<String, dynamic> arguments) {
    final title = arguments['title'];
    if (title is! String || title.trim().isEmpty) {
      return const _SubAgentRunRequest.error('Missing title.');
    }

    final prompt = arguments['prompt'];
    if (prompt is! String || prompt.trim().isEmpty) {
      return const _SubAgentRunRequest.error('Missing prompt.');
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.length > maxSubAgentTitleLength) {
      return const _SubAgentRunRequest.error('Title is too long.');
    }

    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.length > maxSubAgentPromptLength) {
      return const _SubAgentRunRequest.error('Prompt is too long.');
    }

    final rawAgentId = arguments['agentId'];
    final agentId = rawAgentId is String && rawAgentId.trim().isNotEmpty
        ? rawAgentId.trim()
        : null;

    return _SubAgentRunRequest(
      title: trimmedTitle,
      prompt: trimmedPrompt,
      agentId: agentId,
    );
  }

  const new error(String this.error) : title = '', prompt = '', agentId = null;

  final String title;
  final String prompt;
  final String? agentId;
  final String? error;
}

abstract interface class SubAgentCatalog {
  Future<SubAgentCatalogPage> listSubAgents(SubAgentCatalogQuery query);

  Future<SubAgentCatalogEntry?> getSubAgent(String agentId);
}

class const SubAgentCatalogQuery({
  required final String workspaceId,
  final String query = '',
  final String? type,
  final int limit = 20,
  final String? cursor,
}) {
  factory fromArguments(String workspaceId, Map<String, dynamic> arguments) {
    final rawQuery = arguments['query'];
    if (rawQuery != null && rawQuery is! String) {
      throw const FormatException('Invalid query.');
    }
    final query = (rawQuery as String? ?? '').trim();
    if (query.length > 200) throw const FormatException('Query is too long.');

    final type = arguments['type'];
    if (type != null && type != 'main' && type != 'sub_agent') {
      throw const FormatException('Unknown agent type.');
    }
    final limit = arguments['limit'] ?? 20;
    if (limit is! int || limit < 1 || limit > 100) {
      throw const FormatException('Invalid limit.');
    }
    final cursor = arguments['cursor'];
    if (cursor != null &&
        (cursor is! String || cursor.isEmpty || cursor.length > 2048)) {
      throw const FormatException('Invalid cursor.');
    }

    return SubAgentCatalogQuery(
      workspaceId: workspaceId,
      query: query,
      type: type as String?,
      limit: limit,
      cursor: cursor as String?,
    );
  }
}

class const SubAgentCatalogPage({
  required final List<SubAgentCatalogEntry> agents,
  final String? nextCursor,
});

abstract interface class SubAgentConversationStore {
  Future<SubAgentConversationRecord?> getConversation(String conversationId);

  Future<SubAgentConversationRecord> createChildConversation(
    SubAgentChildConversationRequest request,
  );
}

typedef SubAgentChildConversationRequest = ({
  String parentConversationId,
  String workspaceId,
  String? modelId,
  String? agentId,
  String title,
});

abstract interface class SubAgentMessageStore {
  Future<SubAgentMessageRecord> createUserPrompt({
    required String conversationId,
    required String prompt,
  });

  Future<String> latestAssistantContent(String conversationId);
}

typedef StartSubAgentRequest = SubAgentRequestHandle Function({
  required String parentId,
  required String childId,
});

abstract interface class SubAgentRequestHandle {
  Future<SubAgentCompletionStatus> get completion;

  bool get isStopped;

  void finish([
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  ]);
}

enum SubAgentCompletionStatus { done, stopped, error }

class const SubAgentCatalogEntry({
  required final String id,
  required final String workspaceId,
  required final String name,
  required final String description,
  required final List<String> types,
});

class const SubAgentConversationRecord({
  required final String id,
  required final String workspaceId,
  required final String? modelId,
  required final String? parentConversationId,
});

class const SubAgentMessageRecord({required final String id});

String _error(String message, {String? agentId}) {
  return jsonEncode({
    'status': 'error',
    'content': message,
    'agentId': ?agentId,
  });
}
