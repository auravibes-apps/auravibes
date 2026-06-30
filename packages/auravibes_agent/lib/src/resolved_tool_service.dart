import 'package:auravibes_agent/src/tool_name_resolver.dart';

abstract interface class ResolvedToolProvider<TTool> {
  AgentResolvedToolExecution<TTool> toExecution(TTool tool);

  Future<Object?> runBuiltInTool({
    required String conversationId,
    required TTool tool,
    required Object input,
  });

  Future<Object?> runNativeTool({
    required String conversationId,
    required TTool tool,
    required Object input,
  });

  Future<Object?> runMcpTool({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  });

  Future<String> getConversationWorkspaceId(String conversationId);

  Future<Object?> runSkillControlTool({
    required String conversationId,
    required String workspaceId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  });

  Future<Object?> runSkillTemplateTool({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  });

  Future<Object?> runSkillNativeTool({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  });
}

class AgentResolvedToolExecution<TTool> {
  const AgentResolvedToolExecution({
    required this.descriptor,
    required this.tool,
  });

  final AgentResolvedToolName descriptor;
  final TTool tool;
}

class ResolvedToolService<TTool> {
  const ResolvedToolService({required this.provider});

  final ResolvedToolProvider<TTool> provider;

  Future<Object?> call({
    required String conversationId,
    required TTool tool,
    required Map<String, dynamic> arguments,
  }) async {
    final execution = provider.toExecution(tool);
    final descriptor = execution.descriptor;

    return switch (descriptor.kind) {
      AgentResolvedToolKind.builtIn => _runInputTool(
        conversationId: conversationId,
        tool: execution.tool,
        arguments: arguments,
        runner: provider.runBuiltInTool,
        missingInputMessage: 'Built-in tools require an input argument.',
      ),
      AgentResolvedToolKind.native => _runInputTool(
        conversationId: conversationId,
        tool: execution.tool,
        arguments: arguments,
        runner: provider.runNativeTool,
        missingInputMessage: 'Native tools require an input argument.',
      ),
      AgentResolvedToolKind.mcp => _runMcpTool(descriptor, arguments),
      AgentResolvedToolKind.skillControl => _runSkillControlTool(
        conversationId,
        descriptor,
        arguments,
      ),
      AgentResolvedToolKind.skillTemplate => _runSkillTemplateTool(
        conversationId,
        descriptor,
        arguments,
      ),
      AgentResolvedToolKind.skillNative => _runSkillNativeTool(
        conversationId,
        descriptor,
        arguments,
      ),
    };
  }

  Future<Object?> _runInputTool({
    required String conversationId,
    required TTool tool,
    required Map<String, dynamic> arguments,
    required Future<Object?> Function({
      required String conversationId,
      required TTool tool,
      required Object input,
    })
    runner,
    required String missingInputMessage,
  }) {
    final Object? input = arguments['input'];
    if (input == null) {
      throw FormatException(missingInputMessage);
    }

    return runner(conversationId: conversationId, tool: tool, input: input);
  }

  Future<Object?> _runMcpTool(
    AgentResolvedToolName descriptor,
    Map<String, dynamic> arguments,
  ) {
    final mcpServerId = descriptor.mcpServerId;
    if (mcpServerId == null || mcpServerId.isEmpty) {
      throw StateError(
        'MCP tool ${descriptor.toolIdentifier} is missing its server binding.',
      );
    }

    return provider.runMcpTool(
      mcpServerId: mcpServerId,
      toolIdentifier: descriptor.toolIdentifier,
      arguments: arguments,
    );
  }

  Future<Object?> _runSkillControlTool(
    String conversationId,
    AgentResolvedToolName descriptor,
    Map<String, dynamic> arguments,
  ) async {
    final workspaceId = await provider.getConversationWorkspaceId(
      conversationId,
    );

    return provider.runSkillControlTool(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolIdentifier: descriptor.toolIdentifier,
      arguments: arguments,
    );
  }

  Future<Object?> _runSkillTemplateTool(
    String conversationId,
    AgentResolvedToolName descriptor,
    Map<String, dynamic> arguments,
  ) async {
    final skillSlug = descriptor.skillSlug;
    if (skillSlug == null || skillSlug.isEmpty) {
      throw StateError('Skill template tool is missing skill slug.');
    }
    final workspaceId = await provider.getConversationWorkspaceId(
      conversationId,
    );

    return provider.runSkillTemplateTool(
      workspaceId: workspaceId,
      skillSlug: skillSlug,
      toolSlug: descriptor.toolIdentifier,
      arguments: arguments,
    );
  }

  Future<Object?> _runSkillNativeTool(
    String conversationId,
    AgentResolvedToolName descriptor,
    Map<String, dynamic> arguments,
  ) async {
    final skillSlug = descriptor.skillSlug;
    final toolSlug = descriptor.skillToolSlug;
    if (skillSlug == null || skillSlug.isEmpty) {
      throw StateError('Skill native tool is missing skill slug.');
    }
    if (toolSlug == null || toolSlug.isEmpty) {
      throw StateError('Skill native tool is missing tool slug.');
    }
    final workspaceId = await provider.getConversationWorkspaceId(
      conversationId,
    );

    return provider.runSkillNativeTool(
      workspaceId: workspaceId,
      skillSlug: skillSlug,
      toolSlug: toolSlug,
      arguments: arguments,
    );
  }
}
