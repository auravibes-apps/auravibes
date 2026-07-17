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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class ListConversationMessagesRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ListConversationMessagesRequest._({
    required this.workspaceId,
    required this.conversationId,
    required this.limit,
  });

  factory ListConversationMessagesRequest({
    required int workspaceId,
    required String conversationId,
    required int limit,
  }) = _ListConversationMessagesRequestImpl;

  factory ListConversationMessagesRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ListConversationMessagesRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
      limit: jsonSerialization['limit'] as int,
    );
  }

  int workspaceId;

  String conversationId;

  int limit;

  /// Returns a shallow copy of this [ListConversationMessagesRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListConversationMessagesRequest copyWith({
    int? workspaceId,
    String? conversationId,
    int? limit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListConversationMessagesRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'limit': limit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListConversationMessagesRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ListConversationMessagesRequestImpl
    extends ListConversationMessagesRequest {
  _ListConversationMessagesRequestImpl({
    required int workspaceId,
    required String conversationId,
    required int limit,
  }) : super._(
         workspaceId: workspaceId,
         conversationId: conversationId,
         limit: limit,
       );

  /// Returns a shallow copy of this [ListConversationMessagesRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListConversationMessagesRequest copyWith({
    int? workspaceId,
    String? conversationId,
    int? limit,
  }) {
    return ListConversationMessagesRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      limit: limit ?? this.limit,
    );
  }
}
