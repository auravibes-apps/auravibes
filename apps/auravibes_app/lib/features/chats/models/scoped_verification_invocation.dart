import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef ScopedVerificationInvocation = ({
  String conversationId,
  String toolCallId,
  ResolvedTool tool,
});
typedef ScopedVerificationIdentity = ({String workspaceId, String? turnId});
typedef ScopedVerificationRunnerInput = ({
  ScopedVerificationInvocation invocation,
  ScopedVerificationSettings settings,
  ScopedVerificationRequest request,
  AgentCancellationScope cancellation,
});

typedef ScopedVerificationOwnedCaller = ({
  McpToolCaller call,
  void Function() close,
});
