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

abstract class UpdateConversationRequest._({
  required var int workspaceId,
  required var String requestId,
  required var String conversationId,
  required var int expectedRevision,
  var String? title,
  var bool? isPinned,
  var String? modelId,
  required var bool clearModel,
  var String? agentId,
  required var bool clearAgent,
  var String? parentConversationId,
  required var bool clearParent,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required String requestId,
    required String conversationId,
    required int expectedRevision,
    String? title,
    bool? isPinned,
    String? modelId,
    required bool clearModel,
    String? agentId,
    required bool clearAgent,
    String? parentConversationId,
    required bool clearParent,
  }) = _UpdateConversationRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return UpdateConversationRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      conversationId: jsonSerialization['conversationId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      title: jsonSerialization['title'] as String?,
      isPinned: jsonSerialization['isPinned'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isPinned']),
      modelId: jsonSerialization['modelId'] as String?,
      clearModel: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['clearModel'],
      ),
      agentId: jsonSerialization['agentId'] as String?,
      clearAgent: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['clearAgent'],
      ),
      parentConversationId:
          jsonSerialization['parentConversationId'] as String?,
      clearParent: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['clearParent'],
      ),
    );
  }

  /// Returns a shallow copy of this [UpdateConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UpdateConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedRevision,
    String? title,
    bool? isPinned,
    String? modelId,
    bool? clearModel,
    String? agentId,
    bool? clearAgent,
    String? parentConversationId,
    bool? clearParent,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UpdateConversationRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'conversationId': conversationId,
      'expectedRevision': expectedRevision,
      if (title != null) 'title': title,
      if (isPinned != null) 'isPinned': isPinned,
      if (modelId != null) 'modelId': modelId,
      'clearModel': clearModel,
      if (agentId != null) 'agentId': agentId,
      'clearAgent': clearAgent,
      if (parentConversationId != null)
        'parentConversationId': parentConversationId,
      'clearParent': clearParent,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _UpdateConversationRequestImpl({
  required int workspaceId,
  required String requestId,
  required String conversationId,
  required int expectedRevision,
  String? title,
  bool? isPinned,
  String? modelId,
  required bool clearModel,
  String? agentId,
  required bool clearAgent,
  String? parentConversationId,
  required bool clearParent,
}) extends UpdateConversationRequest {
  this
    : super._(
        workspaceId: workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedRevision: expectedRevision,
        title: title,
        isPinned: isPinned,
        modelId: modelId,
        clearModel: clearModel,
        agentId: agentId,
        clearAgent: clearAgent,
        parentConversationId: parentConversationId,
        clearParent: clearParent,
      );

  /// Returns a shallow copy of this [UpdateConversationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UpdateConversationRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? conversationId,
    int? expectedRevision,
    Object? title = _Undefined,
    Object? isPinned = _Undefined,
    Object? modelId = _Undefined,
    bool? clearModel,
    Object? agentId = _Undefined,
    bool? clearAgent,
    Object? parentConversationId = _Undefined,
    bool? clearParent,
  }) {
    return UpdateConversationRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      conversationId: conversationId ?? this.conversationId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      title: title is String? ? title : this.title,
      isPinned: isPinned is bool? ? isPinned : this.isPinned,
      modelId: modelId is String? ? modelId : this.modelId,
      clearModel: clearModel ?? this.clearModel,
      agentId: agentId is String? ? agentId : this.agentId,
      clearAgent: clearAgent ?? this.clearAgent,
      parentConversationId: parentConversationId is String?
          ? parentConversationId
          : this.parentConversationId,
      clearParent: clearParent ?? this.clearParent,
    );
  }
}
