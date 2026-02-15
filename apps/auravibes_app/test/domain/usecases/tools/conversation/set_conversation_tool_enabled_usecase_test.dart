import 'package:auravibes_app/domain/usecases/tools/conversation/set_conversation_tool_enabled_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetConversationToolEnabledUseCase', () {
    test('returns true when conversation id is null', () async {
      final usecase = SetConversationToolEnabledUseCase(
        setConversationToolEnabled: (_, _, {required isEnabled}) async => false,
      );

      final result = await usecase.call(
        conversationId: null,
        toolId: 'tool1',
        isEnabled: true,
      );

      expect(result, isTrue);
    });

    test('delegates when conversation id exists', () async {
      var called = false;
      final usecase = SetConversationToolEnabledUseCase(
        setConversationToolEnabled:
            (conversationId, toolId, {required isEnabled}) async {
              called = true;
              expect(conversationId, 'c1');
              expect(toolId, 't1');
              expect(isEnabled, isFalse);
              return true;
            },
      );

      final result = await usecase.call(
        conversationId: 'c1',
        toolId: 't1',
        isEnabled: false,
      );

      expect(called, isTrue);
      expect(result, isTrue);
    });
  });
}
