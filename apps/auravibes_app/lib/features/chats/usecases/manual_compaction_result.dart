// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:riverpod/riverpod.dart';

class ManualCompactionResult {
  const ManualCompactionResult({required this.success, this.error});
  final bool success;
  final CompactionException? error;
}

class ManualCompactConversationUsecase {
  const ManualCompactConversationUsecase({
    required this.compactConversationUsecase,
  });

  final CompactConversationUsecase compactConversationUsecase;

  Future<ManualCompactionResult> call(String conversationId) async {
    try {
      final _ = await compactConversationUsecase(
        conversationId: conversationId,
        trigger: CompactionTrigger.manual,
      );
      return const ManualCompactionResult(success: true);
    } on CompactionException catch (e) {
      return ManualCompactionResult(success: false, error: e);
    }
  }
}

final manualCompactConversationUsecaseProvider =
    Provider<ManualCompactConversationUsecase>((ref) {
      return ManualCompactConversationUsecase(
        compactConversationUsecase: ref.watch(
          compactConversationUsecaseProvider,
        ),
      );
    });
