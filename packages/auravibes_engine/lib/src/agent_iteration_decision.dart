enum AgentIterationDecision {
  done,
  continueIteration,
  waitForToolApproval,
  iterationLimitReached,
  repeatedToolLoopDetected,
}

extension AgentIterationDecisionX on AgentIterationDecision {
  bool get isPartial =>
      this == AgentIterationDecision.iterationLimitReached ||
      this == AgentIterationDecision.repeatedToolLoopDetected;

  bool get needsUserNotice => isPartial;
}
