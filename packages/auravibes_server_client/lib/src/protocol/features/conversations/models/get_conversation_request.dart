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

abstract class GetConversationRequest._({
  required var int workspaceId,
  required var String conversationId,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String conversationId,
  }) = _GetConversationRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GetConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
    );
  }

  /// Returns a shallow copy of this [GetConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GetConversationRequest copyWith({
    int? workspaceId,
    String? conversationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetConversationRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GetConversationRequestImpl({
  required int workspaceId,
  required String conversationId,
}) extends GetConversationRequest {
  this
    : super._(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );

  /// Returns a shallow copy of this [GetConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GetConversationRequest copyWith({
    int? workspaceId,
    String? conversationId,
  }) {
    return GetConversationRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
