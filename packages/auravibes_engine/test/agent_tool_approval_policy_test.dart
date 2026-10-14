import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('defaultModeLeavesAskPending', () {
    expect(
      applyConversationToolAccessMode(
        AgentToolPermissionResult.needsConfirmation,
        mode: ConversationToolAccessMode.defaultMode,
      ),
      AgentToolPermissionResult.needsConfirmation,
    );
  });

  test('allowAllPromotesOnlyNeedsConfirmation', () {
    expect(
      applyConversationToolAccessMode(
        AgentToolPermissionResult.needsConfirmation,
        mode: ConversationToolAccessMode.allowAll,
      ),
      AgentToolPermissionResult.granted,
    );
  });

  test('allowAllPreservesOtherResults', () {
    for (final result in AgentToolPermissionResult.values) {
      if (result == AgentToolPermissionResult.needsConfirmation) continue;
      expect(
        applyConversationToolAccessMode(
          result,
          mode: ConversationToolAccessMode.allowAll,
        ),
        result,
      );
    }
  });
}
