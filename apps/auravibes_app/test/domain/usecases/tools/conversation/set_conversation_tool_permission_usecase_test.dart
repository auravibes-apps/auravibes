import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/set_conversation_tool_permission_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetConversationToolPermissionUseCase', () {
    test('returns true when conversation id is empty', () async {
      final usecase = SetConversationToolPermissionUseCase(
        setConversationToolPermission:
            (
              _,
              _, {
              required permissionMode,
            }) async => false,
      );

      final result = await usecase.call(
        conversationId: '',
        toolId: 'tool1',
        permissionMode: ToolPermissionMode.alwaysAsk,
      );

      expect(result, isTrue);
    });

    test('delegates when conversation id exists', () async {
      var called = false;
      final usecase = SetConversationToolPermissionUseCase(
        setConversationToolPermission:
            (
              conversationId,
              toolId, {
              required permissionMode,
            }) async {
              called = true;
              expect(conversationId, 'c1');
              expect(toolId, 't1');
              expect(permissionMode, ToolPermissionMode.alwaysAllow);
              return true;
            },
      );

      final result = await usecase.call(
        conversationId: 'c1',
        toolId: 't1',
        permissionMode: ToolPermissionMode.alwaysAllow,
      );

      expect(called, isTrue);
      expect(result, isTrue);
    });
  });
}
