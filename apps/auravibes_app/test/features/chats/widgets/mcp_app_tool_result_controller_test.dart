import 'dart:async';

import 'package:auravibes_app/features/chats/notifiers/activity_run_expansion_notifier.dart';
import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs collapse action after every MCP App teardown', () async {
    final firstTeardown = Completer<void>();
    final secondTeardown = Completer<void>();
    final collapse = Completer<void>();
    final teardown = runAfterMcpAppToolResultsTeardown(
      controllers: [
        McpAppToolResultController()
          ..teardownHandler = () => firstTeardown.future,
        McpAppToolResultController()
          ..teardownHandler = () => secondTeardown.future,
      ],
      action: collapse.complete,
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

  test('repeated deferred collapse stays collapsed', () async {
    final teardown = Completer<void>();
    final controller = McpAppToolResultController()
      ..teardownHandler = () => teardown.future;
    var expandedToolIds = <String>{'tool-1'};

    Future<void> collapse() => runAfterMcpAppToolResultsTeardown(
      controllers: [controller],
      action: () {
        expandedToolIds = updateActivityRunExpandedIds(
          expandedIds: expandedToolIds,
          id: 'tool-1',
          isExpanded: false,
        );
      },
    );

    final firstTap = collapse();
    final secondTap = collapse();
    expect(expandedToolIds, {'tool-1'});

    teardown.complete();
    final _ = await Future.wait<void>([firstTap, secondTap]);

    expect(expandedToolIds, isEmpty);
  });
}
