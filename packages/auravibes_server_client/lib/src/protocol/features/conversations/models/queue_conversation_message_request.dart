/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i2;

abstract class QueueConversationMessageRequest._({
  required var int workspaceId,
  required var String requestId,
  required var String conversationId,
  required var int expectedProjectionRevision,
  required var String clientMessageId,
  required var String content,
  required var List<String> attachmentIds,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
  }) = _QueueConversationMessageRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return QueueConversationMessageRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedProjectionRevision:
          jsonSerialization['expectedProjectionRevision'] as int,
      clientMessageId: jsonSerialization['clientMessageId'] as String,
      content: jsonSerialization['content'] as String,
      attachmentIds: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['attachmentIds'],
      ),
    );
  }

  /// Returns a shallow copy of this [QueueConversationMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  QueueConversationMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    String? clientMessageId,
    String? content,
    List<String>? attachmentIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QueueConversationMessageRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedProjectionRevision': expectedProjectionRevision,
      'clientMessageId': clientMessageId,
      'content': content,
      'attachmentIds': attachmentIds.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _QueueConversationMessageRequestImpl({
  required int workspaceId,
  required String requestId,
  required String conversationId,
  required int expectedProjectionRevision,
  required String clientMessageId,
  required String content,
  required List<String> attachmentIds,
}) extends QueueConversationMessageRequest {
  this
    : super._(
        workspaceId: workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
        clientMessageId: clientMessageId,
        content: content,
        attachmentIds: attachmentIds,
      );

  /// Returns a shallow copy of this [QueueConversationMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  QueueConversationMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    String? clientMessageId,
    String? content,
    List<String>? attachmentIds,
  }) {
    return QueueConversationMessageRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedProjectionRevision:
          expectedProjectionRevision ?? this.expectedProjectionRevision,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      content: content ?? this.content,
      attachmentIds:
          attachmentIds ?? this.attachmentIds.map((e0) => e0).toList(),
    );
  }
}
