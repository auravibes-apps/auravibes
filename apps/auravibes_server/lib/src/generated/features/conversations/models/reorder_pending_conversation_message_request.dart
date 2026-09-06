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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

abstract class ReorderPendingConversationMessageRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ReorderPendingConversationMessageRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.expectedProjectionRevision,
    required this.messageId,
    this.beforeMessageId,
    this.a2uiSupportedComponents,
  });

  factory ReorderPendingConversationMessageRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    required String messageId,
    String? beforeMessageId,
    List<String>? a2uiSupportedComponents,
  }) = _ReorderPendingConversationMessageRequestImpl;

  factory ReorderPendingConversationMessageRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ReorderPendingConversationMessageRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedProjectionRevision:
          jsonSerialization['expectedProjectionRevision'] as int,
      messageId: jsonSerialization['messageId'] as String,
      beforeMessageId: jsonSerialization['beforeMessageId'] as String?,
      a2uiSupportedComponents:
          jsonSerialization['a2uiSupportedComponents'] == null
          ? null
          : _if5qez1k.Protocol().deserialize<List<String>>(
              jsonSerialization['a2uiSupportedComponents'],
            ),
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  int expectedProjectionRevision;

  String messageId;

  String? beforeMessageId;

  List<String>? a2uiSupportedComponents;

  /// Returns a shallow copy of this [ReorderPendingConversationMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReorderPendingConversationMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    String? messageId,
    String? beforeMessageId,
    List<String>? a2uiSupportedComponents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReorderPendingConversationMessageRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedProjectionRevision': expectedProjectionRevision,
      'messageId': messageId,
      if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReorderPendingConversationMessageRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedProjectionRevision': expectedProjectionRevision,
      'messageId': messageId,
      if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
      if (a2uiSupportedComponents != null)
        'a2uiSupportedComponents': a2uiSupportedComponents?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReorderPendingConversationMessageRequestImpl
    extends ReorderPendingConversationMessageRequest {
  _ReorderPendingConversationMessageRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    required String messageId,
    String? beforeMessageId,
    List<String>? a2uiSupportedComponents,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         expectedProjectionRevision: expectedProjectionRevision,
         messageId: messageId,
         beforeMessageId: beforeMessageId,
         a2uiSupportedComponents: a2uiSupportedComponents,
       );

  /// Returns a shallow copy of this [ReorderPendingConversationMessageRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReorderPendingConversationMessageRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedProjectionRevision,
    String? messageId,
    Object? beforeMessageId = _Undefined,
    Object? a2uiSupportedComponents = _Undefined,
  }) {
    return ReorderPendingConversationMessageRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedProjectionRevision:
          expectedProjectionRevision ?? this.expectedProjectionRevision,
      messageId: messageId ?? this.messageId,
      beforeMessageId: beforeMessageId is String?
          ? beforeMessageId
          : this.beforeMessageId,
      a2uiSupportedComponents: a2uiSupportedComponents is List<String>?
          ? a2uiSupportedComponents
          : this.a2uiSupportedComponents?.map((e0) => e0).toList(),
    );
  }
}
