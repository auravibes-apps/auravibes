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

abstract class DeleteConversationRequest._({
  required var int workspaceId,
  required var String requestId,
  required var String conversationId,
  required var int expectedRevision,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedRevision,
  }) = _DeleteConversationRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeleteConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
    );
  }

  /// Returns a shallow copy of this [DeleteConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeleteConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteConversationRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedRevision': expectedRevision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeleteConversationRequestImpl({
  required int workspaceId,
  required String requestId,
  required String conversationId,
  required int expectedRevision,
}) extends DeleteConversationRequest {
  this
    : super._(
        workspaceId: workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedRevision: expectedRevision,
      );

  /// Returns a shallow copy of this [DeleteConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeleteConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedRevision,
  }) {
    return DeleteConversationRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
    );
  }
}
