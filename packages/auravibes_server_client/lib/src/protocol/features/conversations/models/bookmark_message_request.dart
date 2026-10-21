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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class BookmarkMessageRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BookmarkMessageRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.sourceConversationId,
    required this.messageId,
  });

  factory BookmarkMessageRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String sourceConversationId,
    required String messageId,
  }) = _BookmarkMessageRequestImpl;

  factory BookmarkMessageRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BookmarkMessageRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      sourceConversationId: jsonSerialization['sourceConversationId'] as String,
      messageId: jsonSerialization['messageId'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  String sourceConversationId;

  String messageId;

  /// Returns a shallow copy of this [BookmarkMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BookmarkMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? sourceConversationId,
    String? messageId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BookmarkMessageRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'sourceConversationId': sourceConversationId,
      'messageId': messageId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BookmarkMessageRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'sourceConversationId': sourceConversationId,
      'messageId': messageId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _BookmarkMessageRequestImpl extends BookmarkMessageRequest {
  _BookmarkMessageRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String sourceConversationId,
    required String messageId,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         sourceConversationId: sourceConversationId,
         messageId: messageId,
       );

  /// Returns a shallow copy of this [BookmarkMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BookmarkMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? sourceConversationId,
    String? messageId,
  }) {
    return BookmarkMessageRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      sourceConversationId: sourceConversationId ?? this.sourceConversationId,
      messageId: messageId ?? this.messageId,
    );
  }
}
