import 'package:auravibes_agent/src/agent_service.dart' as agent_service;
import 'package:auravibes_agent/src/agent_stream_service.dart'
    as agent_stream_service;
import 'package:auravibes_agent/src/agent_tool_decision_service.dart'
    as agent_tool_decision_service;
import 'package:auravibes_agent/src/agent_tool_execution_service.dart'
    as agent_tool_execution_service;
import 'package:auravibes_agent/src/resolved_tool_service.dart'
    as resolved_tool_service;
import 'package:auravibes_agent/src/tool_resume_service.dart'
    as tool_resume_service;

typedef AgentLoopRunner = agent_service.AgentService;
typedef AgentStreamRunner<TChunk> =
    agent_stream_service.AgentStreamService<TChunk>;
typedef AgentToolDecisionRunner =
    agent_tool_decision_service.AgentToolDecisionService;
typedef AgentToolExecutionRunner<TTool extends Object> =
    agent_tool_execution_service.AgentToolExecutionService<TTool>;
typedef ResolvedToolRunner<TTool> =
    resolved_tool_service.ResolvedToolService<TTool>;
typedef AgentToolResumeRunner = tool_resume_service.AgentToolResumeService;
