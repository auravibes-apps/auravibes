import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/manual_compaction_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockCompactConversationUsecase extends Mock
    implements CompactConversationUsecase {}

void main() {
  group('ManualCompactionResult', () {
    test('success result has no error', () {
      const result = ManualCompactionResult(success: true);
      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('failure result carries the exception', () {
      const exception = CompactionFailedException();
      const result = ManualCompactionResult(
        success: false,
        error: exception,
      );
      expect(result.success, isFalse);
      expect(result.error, same(exception));
    });
  });

  group('ManualCompactConversationUsecase', () {
    late MockCompactConversationUsecase mockCompact;
    late ManualCompactConversationUsecase usecase;

    setUp(() {
      mockCompact = MockCompactConversationUsecase();
      usecase = ManualCompactConversationUsecase(
        compactConversationUsecase: mockCompact,
      );
    });

    test('returns success when compaction completes', () async {
      final execState = CompactionExecutionState(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.manual,
        startedAt: DateTime(2026),
        status: CompactionExecutionStatus.success,
      );
      when(
        () => mockCompact.call(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        ),
      ).thenAnswer((_) async => execState);

      final result = await usecase('conv-1');

      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('returns failure with exception when compaction throws', () async {
      const exception = CompactionUnsafeException();
      when(
        () => mockCompact.call(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        ),
      ).thenThrow(exception);

      final result = await usecase('conv-1');

      expect(result.success, isFalse);
      expect(result.error, same(exception));
    });

    test('catches only CompactionException, not unexpected errors', () async {
      when(
        () => mockCompact.call(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        ),
      ).thenThrow(Exception('Unexpected'));

      expect(
        () => usecase('conv-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('provider creates usecase with correct dependency', () {
      final container = ProviderContainer(
        overrides: [
          compactConversationUsecaseProvider.overrideWith(
            (ref) => mockCompact,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(manualCompactConversationUsecaseProvider);

      expect(result, isA<ManualCompactConversationUsecase>());
    });
  });
}
