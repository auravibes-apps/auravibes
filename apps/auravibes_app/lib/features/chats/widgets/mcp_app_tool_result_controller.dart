class McpAppToolResultController {
  Future<void> Function()? teardownHandler;

  Future<void> prepareForTeardown() =>
      teardownHandler?.call() ?? Future<void>.value();
}

abstract final class McpAppToolResultTeardown {
  static Future<void> runAfter({
    required Iterable<McpAppToolResultController?> controllers,
    required void Function() action,
  }) async {
    final activeControllers = controllers
        .whereType<McpAppToolResultController>()
        .where((controller) => controller.teardownHandler != null)
        .toList(growable: false);
    if (activeControllers.isNotEmpty) {
      final _ = await Future.wait<void>([
        for (final controller in activeControllers)
          controller.prepareForTeardown(),
      ]);
    }
    action();
  }
}
