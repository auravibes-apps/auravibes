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

abstract class GetConversationRequest implements _i1.SerializableModel {
  GetConversationRequest._({
    required this.workspaceId,
    required this.conversationId,
  });

  factory GetConversationRequest({
    required int workspaceId,
    required String conversationId,
  }) = _GetConversationRequestImpl;

  factory GetConversationRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GetConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
    );
  }

  int workspaceId;

  String conversationId;

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

class _GetConversationRequestImpl extends GetConversationRequest {
  _GetConversationRequestImpl({
    required int workspaceId,
    required String conversationId,
  }) : super._(
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
