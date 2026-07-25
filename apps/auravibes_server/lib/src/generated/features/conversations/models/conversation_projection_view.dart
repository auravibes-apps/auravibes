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

abstract class ConversationProjectionView
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ConversationProjectionView._({
    required this.id,
    required this.workspaceId,
    required this.executionState,
    required this.projectionRevision,
    required this.sequence,
    this.modelId,
    this.agentId,
    this.activeExecutionId,
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
    String? activeExecutionId,
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
      activeExecutionId: jsonSerialization['activeExecutionId'] as String?,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
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

  String? activeExecutionId;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ConversationProjectionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConversationProjectionView copyWith({
    String? id,
    int? workspaceId,
    String? executionState,
    int? projectionRevision,
    int? sequence,
    String? modelId,
    String? agentId,
    String? activeExecutionId,
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
      if (activeExecutionId != null) 'activeExecutionId': activeExecutionId,
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
      if (activeExecutionId != null) 'activeExecutionId': activeExecutionId,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
    String? activeExecutionId,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         executionState: executionState,
         projectionRevision: projectionRevision,
         sequence: sequence,
         modelId: modelId,
         agentId: agentId,
         activeExecutionId: activeExecutionId,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ConversationProjectionView]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConversationProjectionView copyWith({
    String? id,
    int? workspaceId,
    String? executionState,
    int? projectionRevision,
    int? sequence,
    Object? modelId = _Undefined,
    Object? agentId = _Undefined,
    Object? activeExecutionId = _Undefined,
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
      activeExecutionId: activeExecutionId is String?
          ? activeExecutionId
          : this.activeExecutionId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
