import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';

class FakeConversationRepository implements ConversationRepository {
  final _controllers = <StreamController<List<ConversationEntity>>>[];
  final _pendingRemoval = <StreamController<List<ConversationEntity>>>{};

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) {
    _processPendingRemovals();
    final controller = StreamController<List<ConversationEntity>>()
      ..add(const []);
    controller.onCancel = () => _pendingRemoval.add(controller);
    _controllers.add(controller);

    return controller.stream;
  }

  @override
  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) => const Stream.empty();

  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async => const [];

  Future<void> close() async {
    _processPendingRemovals();
    final controllersSnapshot =
        List<StreamController<List<ConversationEntity>>>.of(_controllers);
    _controllers.clear();
    _pendingRemoval.clear();
    final _ = await Future.wait(
      controllersSnapshot
          .where((controller) => !controller.isClosed)
          .map((controller) => controller.close()),
    );
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) => throw UnimplementedError();

  @override
  Future<bool> deleteConversation(String id) => throw UnimplementedError();

  @override
  Future<ConversationEntity?> getConversationById(String id) =>
      throw UnimplementedError();

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) => throw UnimplementedError();

  @override
  Stream<ConversationEntity?> watchConversationById(String id) =>
      throw UnimplementedError();

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) => throw UnimplementedError();

  void _processPendingRemovals() {
    if (_pendingRemoval.isNotEmpty) {
      _controllers.removeWhere(_pendingRemoval.contains);
      _pendingRemoval.clear();
    }
  }
}
