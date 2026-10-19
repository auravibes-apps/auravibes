class McpAppToolResultController {
  Future<void> Function()? teardownHandler;

  Future<void> prepareForTeardown() =>
      teardownHandler?.call() ?? Future<void>.value();
}
