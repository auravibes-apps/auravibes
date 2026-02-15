import 'package:auravibes_app/domain/usecases/tools/conversation/get_context_aware_tools_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delegates to getAvailableTools callback', () async {
    final usecase = GetContextAwareToolsUseCase(
      getAvailableTools: (conversationId, workspaceId) async {
        expect(conversationId, 'c1');
        expect(workspaceId, 'w1');
        return ['a', 'b'];
      },
    );

    final result = await usecase.call(conversationId: 'c1', workspaceId: 'w1');
    expect(result, ['a', 'b']);
  });
}
