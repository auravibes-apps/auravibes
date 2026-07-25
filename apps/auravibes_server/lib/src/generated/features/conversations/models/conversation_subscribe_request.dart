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

abstract class ConversationSubscribeRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationSubscribeRequest._({
    required this.workspaceId,
    required this.conversationId,
    required this.afterSequence,
  });

  factory ConversationSubscribeRequest({
    required int workspaceId,
    required String conversationId,
    required int afterSequence,
  }) = _ConversationSubscribeRequestImpl;

  factory ConversationSubscribeRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationSubscribeRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
      afterSequence: jsonSerialization['afterSequence'] as int,
    );
  }

  int workspaceId;

  String conversationId;

  int afterSequence;

  /// Returns a shallow copy of this [ConversationSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationSubscribeRequest copyWith({
    int? workspaceId,
    String? conversationId,
    int? afterSequence,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationSubscribeRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'afterSequence': afterSequence,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationSubscribeRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'afterSequence': afterSequence,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ConversationSubscribeRequestImpl extends ConversationSubscribeRequest {
  _ConversationSubscribeRequestImpl({
    required int workspaceId,
    required String conversationId,
    required int afterSequence,
  }) : super._(
         workspaceId: workspaceId,
         conversationId: conversationId,
         afterSequence: afterSequence,
       );

  /// Returns a shallow copy of this [ConversationSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationSubscribeRequest copyWith({
    int? workspaceId,
    String? conversationId,
    int? afterSequence,
  }) {
    return ConversationSubscribeRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      afterSequence: afterSequence ?? this.afterSequence,
    );
  }
}
