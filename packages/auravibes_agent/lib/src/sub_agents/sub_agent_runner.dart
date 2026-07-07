import 'dart:convert';

import 'package:auravibes_agent/src/agent_iteration_context.dart';
import 'package:auravibes_agent/src/agent_iteration_decision.dart';

const maxSubAgentTitleLength = 160;
const maxSubAgentPromptLength = 20000;

typedef ContinueSubAgentTurn =
    Future<AgentIterationDecision> Function({
      required String conversationId,
      required AgentIterationContext context,
    });

typedef SubAgentChildStarted =
    void Function({
      required String parentId,
      required String childId,
    });

class SubAgentTurnRunner {
  ContinueSubAgentTurn? _runner;

  ContinueSubAgentTurn? get runner => _runner;

  set runner(ContinueSubAgentTurn runner) => _runner = runner;

  void clear(ContinueSubAgentTurn runner) {
    if (_runner != runner) return;

    _runner = null;
  }

  Future<AgentIterationDecision> call({
    required String conversationId,
    required AgentIterationContext context,
  }) {
    final runner = this.runner;
    if (runner == null) {
      throw StateError('Sub-agent runner is not configured.');
    }

    return runner(conversationId: conversationId, context: context);
  }
}

final subAgentTurnRunner = SubAgentTurnRunner();

class SubAgentRunner {
  const SubAgentRunner({
    required this.agentCatalog,
    required this.conversationStore,
    required this.messageStore,
    required this.activeTracker,
    required this.continueAgentTurn,
    this.onChildStarted,
  });

  final SubAgentCatalog agentCatalog;
  final SubAgentConversationStore conversationStore;
  final SubAgentMessageStore messageStore;
  final ActiveSubAgentTracker activeTracker;
  final ContinueSubAgentTurn continueAgentTurn;
  final SubAgentChildStarted? onChildStarted;

  Future<String> listAgents(
    String workspaceId, {
    Map<String, dynamic> arguments = const {},
  }) async {
    final rawType = arguments['type'];
    if (rawType != null && rawType != 'main' && rawType != 'sub_agent') {
      return _error('Unknown agent type.');
    }
    final agents = await agentCatalog.listSubAgents(workspaceId);
    final type = rawType as String?;

    return jsonEncode({
      'agents': [
        for (final agent in agents)
          if (type == null || agent.types.contains(type))
            {
              'id': agent.id,
              'name': agent.name,
              'description': agent.description,
              'types': agent.types,
            },
      ],
    });
  }

  Future<String> run({
    required String parentConversationId,
    required String workspaceId,
    required Map<String, dynamic> arguments,
  }) async {
    final title = arguments['title'];
    final prompt = arguments['prompt'];
    if (title is! String || title.trim().isEmpty) {
      return _error('Missing title.');
    }
    if (prompt is! String || prompt.trim().isEmpty) {
      return _error('Missing prompt.');
    }
    final trimmedTitle = title.trim();
    final trimmedPrompt = prompt.trim();
    if (trimmedTitle.length > maxSubAgentTitleLength) {
      return _error('Title is too long.');
    }
    if (trimmedPrompt.length > maxSubAgentPromptLength) {
      return _error('Prompt is too long.');
    }

    final parent = await conversationStore.getConversation(
      parentConversationId,
    );
    if (parent == null || parent.workspaceId != workspaceId) {
      return _error('Parent conversation not found.');
    }
    if (parent.parentConversationId != null) {
      return _error('Sub-agents cannot start sub-agents.');
    }

    final rawAgentId = arguments['agentId'];
    final agentId = rawAgentId is String && rawAgentId.trim().isNotEmpty
        ? rawAgentId.trim()
        : null;
    if (agentId != null) {
      final agent = await agentCatalog.getSubAgent(agentId);
      if (agent == null || agent.workspaceId != workspaceId) {
        return _error('Unknown agent.', agentId: agentId);
      }
    }

    final child = await conversationStore.createChildConversation(
      parentConversationId: parentConversationId,
      workspaceId: workspaceId,
      modelId: parent.modelId,
      agentId: agentId,
      title: trimmedTitle,
    );
    activeTracker.start(parentId: parentConversationId, childId: child.id);
    onChildStarted?.call(parentId: parentConversationId, childId: child.id);
    var completionStatus = SubAgentCompletionStatus.done;
    try {
      final message = await messageStore.createUserPrompt(
        conversationId: child.id,
        prompt: trimmedPrompt,
      );
      final decision = await continueAgentTurn(
        conversationId: child.id,
        context: AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageIds: [message.id],
        ),
      );
      if (activeTracker.isStopped(child.id)) {
        completionStatus = SubAgentCompletionStatus.stopped;
        final assistant = await messageStore.latestAssistantContent(child.id);

        return jsonEncode({
          'conversationId': child.id,
          'status': 'stopped',
          'content': assistant,
          'agentId': ?agentId,
        });
      }
      if (decision == AgentIterationDecision.waitForToolApproval) {
        final status = await activeTracker.waitForCompletion(child.id);
        if (status == SubAgentCompletionStatus.stopped) {
          completionStatus = SubAgentCompletionStatus.stopped;
          final assistant = await messageStore.latestAssistantContent(child.id);

          return jsonEncode({
            'conversationId': child.id,
            'status': 'stopped',
            'content': assistant,
            'agentId': ?agentId,
          });
        }
        if (status == SubAgentCompletionStatus.error) {
          completionStatus = SubAgentCompletionStatus.error;

          return jsonEncode({
            'conversationId': child.id,
            'status': 'error',
            'content': 'Sub-agent failed.',
            'agentId': ?agentId,
          });
        }
      }
      final assistant = await messageStore.latestAssistantContent(child.id);

      return jsonEncode({
        'conversationId': child.id,
        'status': 'done',
        'content': assistant,
        'agentId': ?agentId,
      });
    } on Object {
      completionStatus = SubAgentCompletionStatus.error;

      return jsonEncode({
        'conversationId': child.id,
        'status': 'error',
        'content': 'Sub-agent failed.',
        'agentId': ?agentId,
      });
    } finally {
      activeTracker.finish(
        parentId: parentConversationId,
        childId: child.id,
        status: completionStatus,
      );
    }
  }
}

abstract interface class SubAgentCatalog {
  Future<List<SubAgentCatalogEntry>> listSubAgents(String workspaceId);

  Future<SubAgentCatalogEntry?> getSubAgent(String agentId);
}

abstract interface class SubAgentConversationStore {
  Future<SubAgentConversationRecord?> getConversation(String conversationId);

  Future<SubAgentConversationRecord> createChildConversation({
    required String parentConversationId,
    required String workspaceId,
    required String? modelId,
    required String? agentId,
    required String title,
  });
}

abstract interface class SubAgentMessageStore {
  Future<SubAgentMessageRecord> createUserPrompt({
    required String conversationId,
    required String prompt,
  });

  Future<String> latestAssistantContent(String conversationId);
}

abstract interface class ActiveSubAgentTracker {
  void start({required String parentId, required String childId});

  void finish({
    required String parentId,
    required String childId,
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  });

  Future<SubAgentCompletionStatus> waitForCompletion(String childId);

  bool isStopped(String childId);
}

enum SubAgentCompletionStatus { done, stopped, error }

class SubAgentCatalogEntry {
  const SubAgentCatalogEntry({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.types,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final List<String> types;
}

class SubAgentConversationRecord {
  const SubAgentConversationRecord({
    required this.id,
    required this.workspaceId,
    required this.modelId,
    required this.parentConversationId,
  });

  final String id;
  final String workspaceId;
  final String? modelId;
  final String? parentConversationId;
}

class SubAgentMessageRecord {
  const SubAgentMessageRecord({required this.id});

  final String id;
}

String _error(String message, {String? agentId}) {
  return jsonEncode({
    'status': 'error',
    'content': message,
    'agentId': ?agentId,
  });
}
