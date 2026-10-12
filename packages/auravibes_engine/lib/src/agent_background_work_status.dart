/// Lifecycle of one detached tool invocation.
enum AgentBackgroundWorkStatus {
  running,
  stopRequested,
  completed,
  failed,
  cancelled,
}
