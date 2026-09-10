class ConversationBusyState {
  const new({
    required this.isStreaming,
    required this.hasPendingTools,
    this.isCompacting = false,
    this.cloudExecutionBusy = false,
  });

  const new cloud({required bool isBusy})
    : isStreaming = false,
      hasPendingTools = false,
      isCompacting = false,
      cloudExecutionBusy = isBusy;

  final bool isStreaming;
  final bool hasPendingTools;
  final bool isCompacting;
  final bool cloudExecutionBusy;

  bool hasLocalActivity() => isStreaming || hasPendingTools || isCompacting;

  bool hasCloudActivity() => cloudExecutionBusy;

  bool get isBusy => hasCloudActivity() || hasLocalActivity();
}
