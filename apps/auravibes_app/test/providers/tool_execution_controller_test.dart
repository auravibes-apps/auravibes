import 'package:auravibes_app/providers/tool_execution_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolExecutionController', () {
    test('should track running tools', () async {
      final container = ProviderContainer();
      final controller = container.read(
        toolExecutionControllerProvider.notifier,
      );

      expect(controller.state, isEmpty);

      controller.markToolRunning('tool-1', 'Test Tool', 'msg-1');
      expect(controller.state.length, 1);
      expect(controller.state.first.id, 'tool-1');
    });
  });
}
