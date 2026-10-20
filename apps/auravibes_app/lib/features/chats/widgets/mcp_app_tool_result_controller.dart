class McpAppToolResultController {
  Future<void> Function()? teardownHandler;

  Future<void> prepareForTeardown() =>
      teardownHandler?.call() ?? Future<void>.value();
}

Future<void> prepareMcpAppToolResultsForTeardown(
  Iterable<McpAppToolResultController?> controllers,
) async {
  final _ = await Future.wait<void>([
    for (final controller in controllers)
      controller?.prepareForTeardown() ?? Future<void>.value(),
  ]);
}
