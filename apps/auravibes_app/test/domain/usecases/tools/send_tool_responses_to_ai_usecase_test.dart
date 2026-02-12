// test/domain/usecases/tools/send_tool_responses_to_ai_usecase_test.dart
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/send_tool_responses_to_ai_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'send_tool_responses_to_ai_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  group('SendToolResponsesToAIUseCase', () {
    test('can be instantiated', () {
      final mockMessageRepo = MockMessageRepository();

      final useCase = SendToolResponsesToAIUseCase(
        mockMessageRepo,
        (_, __) async {},
      );

      expect(useCase, isNotNull);
    });
  });
}
