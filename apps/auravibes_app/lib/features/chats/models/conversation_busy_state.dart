class ConversationBusyState {
  const new({
    required this.isStreaming,
    required this.hasPendingTools,
    this.isAgentWorking = false,
    this.isCompacting = false,
    this.cloudExecutionBusy = false,
  });

  const new cloud({required bool isBusy})
    : isStreaming = false,
      isAgentWorking = false,
      hasPendingTools = false,
      isCompacting = false,
      cloudExecutionBusy = isBusy;

  final bool isStreaming;
  final bool isAgentWorking;
  final bool hasPendingTools;
  final bool isCompacting;
  final bool cloudExecutionBusy;

  bool get isBusy => hasCloudActivity() || hasLocalActivity();

  bool hasLocalActivity() =>
      isStreaming || isAgentWorking || hasPendingTools || isCompacting;

  bool hasCloudActivity() => cloudExecutionBusy;
}
