import 'dart:async';

import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs collapse action after every MCP App teardown', () async {
    final firstTeardown = Completer<void>();
    final secondTeardown = Completer<void>();
    final collapse = Completer<void>();
    final teardown = runAfterMcpAppToolResultsTeardown(
      [
        McpAppToolResultController()
          ..teardownHandler = () => firstTeardown.future,
        McpAppToolResultController()
          ..teardownHandler = () => secondTeardown.future,
      ],
      collapse.complete,
    );

    firstTeardown.complete();
    await expectLater(
      collapse.future.timeout(const .new(milliseconds: 10)),
      throwsA(isA<TimeoutException>()),
    );

    secondTeardown.complete();
    await teardown;
    expect(collapse.isCompleted, isTrue);
  });
}
