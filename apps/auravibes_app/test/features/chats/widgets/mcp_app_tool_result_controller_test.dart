import 'dart:async';

import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waits for every MCP App result teardown', () async {
    final firstTeardown = Completer<void>();
    final secondTeardown = Completer<void>();
    final teardown = prepareMcpAppToolResultsForTeardown([
      McpAppToolResultController()
        ..teardownHandler = () => firstTeardown.future,
      McpAppToolResultController()
        ..teardownHandler = () => secondTeardown.future,
    ]);

    firstTeardown.complete();
    await expectLater(
      teardown.timeout(const .new(milliseconds: 10)),
      throwsA(isA<TimeoutException>()),
    );

    secondTeardown.complete();
    await teardown;
  });
}
