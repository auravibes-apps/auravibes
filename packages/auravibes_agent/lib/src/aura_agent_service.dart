import 'package:auravibes_agent/src/namespaces/agent_namespace.dart';
import 'package:auravibes_agent/src/namespaces/conversations_namespace.dart';
import 'package:auravibes_agent/src/namespaces/tools_namespace.dart';
import 'package:auravibes_agent/src/providers/agent_data_provider.dart';
import 'package:auravibes_agent/src/providers/agent_runtime_provider.dart';
import 'package:auravibes_agent/src/providers/agent_tool_provider.dart';

class AuraAgentService<TTool extends Object> {
  AuraAgentService({
    required AgentDataProvider data,
    required AgentToolProvider<TTool> tools,
    required AgentRuntimeProvider runtime,
  }) : agent = AgentNamespace(
         data: data,
         runtime: runtime,
       ),
       conversations = ConversationsNamespace(data: data),
       tools = ToolsNamespace<TTool>(tools: tools);

  final AgentNamespace agent;
  final ConversationsNamespace conversations;
  final ToolsNamespace<TTool> tools;
}
