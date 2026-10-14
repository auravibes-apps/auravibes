import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  for (final result in AgentToolPermissionResult.values) {
    test('auto approval preserves $result unless confirmation is required', () {
      expect(
        applyAgentToolAutoApproval(result, autoApproveTools: false),
        result,
      );
      expect(
        applyAgentToolAutoApproval(result, autoApproveTools: true),
        result == AgentToolPermissionResult.needsConfirmation
            ? AgentToolPermissionResult.granted
            : result,
      );
    });
  }
}
