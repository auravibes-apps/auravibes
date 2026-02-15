class WaitForMcpConnectionsUseCase {
  const WaitForMcpConnectionsUseCase();

  Future<void> call({
    required List<String> mcpServerIds,
    required Duration timeout,
    required bool Function() isStillConnecting,
  }) async {
    if (mcpServerIds.isEmpty || timeout.inSeconds <= 0) {
      return;
    }

    if (!isStillConnecting()) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    const pollInterval = Duration(milliseconds: 100);
    while (isStillConnecting() && stopwatch.elapsed < timeout) {
      await Future<void>.delayed(pollInterval);
    }
    stopwatch.stop();
  }
}
