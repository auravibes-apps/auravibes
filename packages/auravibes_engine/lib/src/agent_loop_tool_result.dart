import 'package:auravibes_engine/src/agent_iteration_decision.dart';

/// The result of one tool-execution batch within an agent turn.
///
/// [fingerprint] is an ephemeral digest of the tool calls and their outcomes.
/// It is used only by the in-memory no-progress loop detector.
class const AgentLoopToolResult({
  required final AgentIterationDecision decision,
  final String? fingerprint,
});
