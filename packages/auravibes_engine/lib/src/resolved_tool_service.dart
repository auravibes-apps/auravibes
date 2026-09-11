import 'package:auravibes_engine/src/tool_name_resolver.dart';

typedef SkillControlToolRequest = ({
  String conversationId,
  String workspaceId,
  String toolIdentifier,
  Map<String, dynamic> arguments,
});

typedef SkillTemplateToolRequest = ({
  String conversationId,
  String workspaceId,
  String skillSlug,
  String toolSlug,
  Map<String, dynamic> arguments,
});

typedef SkillNativeToolRequest = ({
  String conversationId,
  String workspaceId,
  String skillSlug,
  String toolSlug,
  Map<String, dynamic> arguments,
});

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

  Future<Object?> runSkillControlTool(SkillControlToolRequest request);

  Future<Object?> runSkillTemplateTool(SkillTemplateToolRequest request);

  Future<Object?> runSkillNativeTool(SkillNativeToolRequest request);
}

class const AgentResolvedToolExecution<TTool>({
  required final AgentResolvedToolName descriptor,
  required final TTool tool,
});

class const ResolvedToolService<TTool>({
  required final ResolvedToolProvider<TTool> provider,
}) {
  Future<Object?> call({
    required String conversationId,
    required TTool tool,
    required Map<String, dynamic> arguments,
  }) async {
    final execution = provider.toExecution(tool);
    final descriptor = execution.descriptor;

    return await switch (descriptor.kind) {
      .builtIn => _runInputTool(
        conversationId: conversationId,
        tool: execution.tool,
        arguments: arguments,
        runner: provider.runBuiltInTool,
        missingInputMessage: 'Built-in tools require an input argument.',
      ),
      .native => _runInputTool(
        conversationId: conversationId,
        tool: execution.tool,
        arguments: arguments,
        runner: provider.runNativeTool,
        missingInputMessage: 'Native tools require an input argument.',
      ),
      .mcp => _runMcpTool(descriptor, arguments),
      .skillControl => _runSkillControlTool(
        conversationId,
        descriptor,
        arguments,
      ),
      .skillTemplate => _runSkillTemplateTool(
        conversationId,
        descriptor,
        arguments,
      ),
      .skillNative => _runSkillNativeTool(
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

    return await provider.runSkillControlTool((
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolIdentifier: descriptor.toolIdentifier,
      arguments: arguments,
    ));
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

    return await provider.runSkillTemplateTool((
      conversationId: conversationId,
      workspaceId: workspaceId,
      skillSlug: skillSlug,
      toolSlug: descriptor.toolIdentifier,
      arguments: arguments,
    ));
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

    return await provider.runSkillNativeTool((
      conversationId: conversationId,
      workspaceId: workspaceId,
      skillSlug: skillSlug,
      toolSlug: toolSlug,
      arguments: arguments,
    ));
  }
}
