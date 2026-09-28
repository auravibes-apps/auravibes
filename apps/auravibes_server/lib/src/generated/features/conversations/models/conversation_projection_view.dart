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
import 'package:serverpod/serverpod.dart' as _is;

abstract class ConversationProjectionView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ConversationProjectionView._({
    required this.id,
    required this.workspaceId,
    required this.executionState,
    required this.projectionRevision,
    required this.sequence,
    this.modelId,
    this.agentId,
    this.reasoningConfigJson,
    this.forkSourceConversationId,
    this.forkSourceTitle,
    this.forkThroughMessageId,
    this.forkMaterializedAt,
    this.activeExecutionId,
    this.activeCompactionCheckpointId,
    required this.updatedAt,
  });

  factory ConversationProjectionView({
    required String id,
    required int workspaceId,
    required String executionState,
    required int projectionRevision,
    required int sequence,
    String? modelId,
    String? agentId,
    String? reasoningConfigJson,
    String? forkSourceConversationId,
    String? forkSourceTitle,
    String? forkThroughMessageId,
    DateTime? forkMaterializedAt,
    String? activeExecutionId,
    String? activeCompactionCheckpointId,
    required DateTime updatedAt,
  }) = _ConversationProjectionViewImpl;

  factory ConversationProjectionView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConversationProjectionView(
      id: jsonSerialization['id'] as String,
      workspaceId: jsonSerialization['workspaceId'] as int,
      executionState: jsonSerialization['executionState'] as String,
      projectionRevision: jsonSerialization['projectionRevision'] as int,
      sequence: jsonSerialization['sequence'] as int,
      modelId: jsonSerialization['modelId'] as String?,
      agentId: jsonSerialization['agentId'] as String?,
      reasoningConfigJson: jsonSerialization['reasoningConfigJson'] as String?,
      forkSourceConversationId:
          jsonSerialization['forkSourceConversationId'] as String?,
      forkSourceTitle: jsonSerialization['forkSourceTitle'] as String?,
      forkThroughMessageId:
          jsonSerialization['forkThroughMessageId'] as String?,
      forkMaterializedAt: jsonSerialization['forkMaterializedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['forkMaterializedAt'],
            ),
      activeExecutionId: jsonSerialization['activeExecutionId'] as String?,
      activeCompactionCheckpointId:
          jsonSerialization['activeCompactionCheckpointId'] as String?,
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  String id;

  int workspaceId;

  String executionState;

  int projectionRevision;

  int sequence;

  String? modelId;

  String? agentId;

  String? reasoningConfigJson;

  String? forkSourceConversationId;

  String? forkSourceTitle;

  String? forkThroughMessageId;

  DateTime? forkMaterializedAt;

  String? activeExecutionId;

  String? activeCompactionCheckpointId;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationProjectionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConversationProjectionView copyWith({
    String? id,
    int? workspaceId,
    String? executionState,
    int? projectionRevision,
    int? sequence,
    String? modelId,
    String? agentId,
    String? reasoningConfigJson,
    String? forkSourceConversationId,
    String? forkSourceTitle,
    String? forkThroughMessageId,
    DateTime? forkMaterializedAt,
    String? activeExecutionId,
    String? activeCompactionCheckpointId,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationProjectionView',
      'id': id,
      'workspaceId': workspaceId,
      'executionState': executionState,
      'projectionRevision': projectionRevision,
      'sequence': sequence,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (reasoningConfigJson != null)
        'reasoningConfigJson': reasoningConfigJson,
      if (forkSourceConversationId != null)
        'forkSourceConversationId': forkSourceConversationId,
      if (forkSourceTitle != null) 'forkSourceTitle': forkSourceTitle,
      if (forkThroughMessageId != null)
        'forkThroughMessageId': forkThroughMessageId,
      if (forkMaterializedAt != null)
        'forkMaterializedAt': forkMaterializedAt?.toJson(),
      if (activeExecutionId != null) 'activeExecutionId': activeExecutionId,
      if (activeCompactionCheckpointId != null)
        'activeCompactionCheckpointId': activeCompactionCheckpointId,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationProjectionView',
      'id': id,
      'workspaceId': workspaceId,
      'executionState': executionState,
      'projectionRevision': projectionRevision,
      'sequence': sequence,
      if (modelId != null) 'modelId': modelId,
      if (agentId != null) 'agentId': agentId,
      if (reasoningConfigJson != null)
        'reasoningConfigJson': reasoningConfigJson,
      if (forkSourceConversationId != null)
        'forkSourceConversationId': forkSourceConversationId,
      if (forkSourceTitle != null) 'forkSourceTitle': forkSourceTitle,
      if (forkThroughMessageId != null)
        'forkThroughMessageId': forkThroughMessageId,
      if (forkMaterializedAt != null)
        'forkMaterializedAt': forkMaterializedAt?.toJson(),
      if (activeExecutionId != null) 'activeExecutionId': activeExecutionId,
      if (activeCompactionCheckpointId != null)
        'activeCompactionCheckpointId': activeCompactionCheckpointId,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationProjectionViewImpl extends ConversationProjectionView {
  _ConversationProjectionViewImpl({
    required String id,
    required int workspaceId,
    required String executionState,
    required int projectionRevision,
    required int sequence,
    String? modelId,
    String? agentId,
    String? reasoningConfigJson,
    String? forkSourceConversationId,
    String? forkSourceTitle,
    String? forkThroughMessageId,
    DateTime? forkMaterializedAt,
    String? activeExecutionId,
    String? activeCompactionCheckpointId,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         executionState: executionState,
         projectionRevision: projectionRevision,
         sequence: sequence,
         modelId: modelId,
         agentId: agentId,
         reasoningConfigJson: reasoningConfigJson,
         forkSourceConversationId: forkSourceConversationId,
         forkSourceTitle: forkSourceTitle,
         forkThroughMessageId: forkThroughMessageId,
         forkMaterializedAt: forkMaterializedAt,
         activeExecutionId: activeExecutionId,
         activeCompactionCheckpointId: activeCompactionCheckpointId,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationProjectionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConversationProjectionView copyWith({
    String? id,
    int? workspaceId,
    String? executionState,
    int? projectionRevision,
    int? sequence,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
    Object? reasoningConfigJson = _Undefined,
    Object? forkSourceConversationId = _Undefined,
    Object? forkSourceTitle = _Undefined,
    Object? forkThroughMessageId = _Undefined,
    Object? forkMaterializedAt = _Undefined,
    Object? activeExecutionId = _Undefined,
    Object? activeCompactionCheckpointId = _Undefined,
    DateTime? updatedAt,
  }) {
    return ConversationProjectionView(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      executionState: executionState ?? this.executionState,
      projectionRevision: projectionRevision ?? this.projectionRevision,
      sequence: sequence ?? this.sequence,
      modelId: modelId is String? ? modelId : this.modelId,
      agentId: agentId is String? ? agentId : this.agentId,
      reasoningConfigJson: reasoningConfigJson is String?
          ? reasoningConfigJson
          : this.reasoningConfigJson,
      forkSourceConversationId: forkSourceConversationId is String?
          ? forkSourceConversationId
          : this.forkSourceConversationId,
      forkSourceTitle: forkSourceTitle is String?
          ? forkSourceTitle
          : this.forkSourceTitle,
      forkThroughMessageId: forkThroughMessageId is String?
          ? forkThroughMessageId
          : this.forkThroughMessageId,
      forkMaterializedAt: forkMaterializedAt is DateTime?
          ? forkMaterializedAt
          : this.forkMaterializedAt,
      activeExecutionId: activeExecutionId is String?
          ? activeExecutionId
          : this.activeExecutionId,
      activeCompactionCheckpointId: activeCompactionCheckpointId is String?
          ? activeCompactionCheckpointId
          : this.activeCompactionCheckpointId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
