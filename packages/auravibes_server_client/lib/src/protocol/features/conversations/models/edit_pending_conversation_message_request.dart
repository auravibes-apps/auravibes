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

abstract class EditPendingConversationMessageRequest._({
  required var int workspaceId,
  required var String requestId,
  required var String conversationId,
  required var int expectedProjectionRevision,
  required var String messageId,
  required var String content,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    required String messageId,
    required String content,
  }) = _EditPendingConversationMessageRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EditPendingConversationMessageRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedProjectionRevision:
          jsonSerialization['expectedProjectionRevision'] as int,
      messageId: jsonSerialization['messageId'] as String,
      content: jsonSerialization['content'] as String,
    );
  }

  /// Returns a shallow copy of this [EditPendingConversationMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EditPendingConversationMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    String? messageId,
    String? content,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EditPendingConversationMessageRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedProjectionRevision': expectedProjectionRevision,
      'messageId': messageId,
      'content': content,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EditPendingConversationMessageRequestImpl({
  required int workspaceId,
  required String requestId,
  required String conversationId,
  required int expectedProjectionRevision,
  required String messageId,
  required String content,
}) extends EditPendingConversationMessageRequest {
  this
    : super._(
        workspaceId: workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
        messageId: messageId,
        content: content,
      );

  /// Returns a shallow copy of this [EditPendingConversationMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EditPendingConversationMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    String? messageId,
    String? content,
  }) {
    return EditPendingConversationMessageRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedProjectionRevision:
          expectedProjectionRevision ?? this.expectedProjectionRevision,
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
    );
  }
}
