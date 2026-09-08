import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_repository.dart';

class ObjectReferenceService({ObjectRepository? repository}) {
  final ObjectRepository repository = repository ?? ObjectRepository();

  Future<void> attachToMessage(
    Session session, {
    required int workspaceId,
    required int objectId,
    required int messageId,
    required Transaction transaction,
  }) async {
    final object = await repository.findObject(
      session,
      workspaceId: workspaceId,
      objectId: objectId,
      transaction: transaction,
      lock: true,
    );
    final message = await ConversationMessage.db.findFirstRow(
      session,
      where: (t) => t.id.equals(messageId) & t.workspaceId.equals(workspaceId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (object == null ||
        object.status != 'active' ||
        object.deletedAt != null ||
        message == null ||
        message.status == 'deleted') {
      throw ObjectException(code: ObjectErrorCode.objectNotFound);
    }
    final existing = await ObjectReference.db.findFirstRow(
      session,
      where: (t) =>
          t.workspaceId.equals(workspaceId) &
          t.objectId.equals(objectId) &
          t.messageId.equals(messageId),
      transaction: transaction,
    );
    if (existing == null) {
      await ObjectReference.db.insertRow(
        session,
        ObjectReference(
          workspaceId: workspaceId,
          objectId: objectId,
          messageId: messageId,
          createdAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    }
  }
}
