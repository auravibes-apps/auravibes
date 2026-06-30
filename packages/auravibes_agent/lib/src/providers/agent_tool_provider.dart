import 'package:auravibes_agent/src/agent_tool_decision_service.dart';
import 'package:auravibes_agent/src/agent_tool_execution_service.dart';
import 'package:auravibes_agent/src/tool_call_actions.dart';
import 'package:auravibes_agent/src/tool_calls.dart';
import 'package:auravibes_agent/src/tool_resume_service.dart';

abstract interface class AgentToolProvider<TTool extends Object>
    implements
        AgentToolExecutionProvider<TTool>,
        AgentToolCallProvider<TTool>,
        AgentToolDecisionProvider,
        ApproveToolCallProvider<TTool>,
        SkipToolCallProvider,
        StopPendingToolCallsProvider,
        AgentToolResumeProvider {}
