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

abstract class CreateConversationRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CreateConversationRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.conversationId,
    required this.title,
    required this.isPinned,
    this.modelId,
    this.agentId,
    this.parentConversationId,
  });

  factory CreateConversationRequest({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationId,
  }) = _CreateConversationRequestImpl;

  factory CreateConversationRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      title: jsonSerialization['title'] as String,
      isPinned: _i1.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
      parentConversationId:
          jsonSerialization['parentConversationId'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String conversationId;

  String title;

  bool isPinned;

  String? modelId;

  String? agentId;

  String? parentConversationId;

  /// Returns a shallow copy of this [CreateConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreateConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? title,
    bool? isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateConversationRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'title': title,
      'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (parentConversationId != null)
        'parentConversationId': parentConversationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateConversationRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'title': title,
      'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (parentConversationId != null)
        'parentConversationId': parentConversationId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CreateConversationRequestImpl extends CreateConversationRequest {
  _CreateConversationRequestImpl({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required String title,
    required bool isPinned,
    String? modelId,
    String? agentId,
    String? parentConversationId,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         conversationId: conversationId,
         title: title,
         isPinned: isPinned,
         modelId: modelId,
         agentId: agentId,
         parentConversationId: parentConversationId,
       );

  /// Returns a shallow copy of this [CreateConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreateConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    String? title,
    bool? isPinned,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
    Object? parentConversationId = _Undefined,
  }) {
    return CreateConversationRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      modelId: modelId is String? ? modelId : this.modelId,
      agentId: agentId is String? ? agentId : this.agentId,
      parentConversationId: parentConversationId is String?
          ? parentConversationId
          : this.parentConversationId,
    );
  }
}
