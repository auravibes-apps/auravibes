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

abstract class WorkspaceModelSelectionToolSamplingPolicy
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceModelSelectionToolSamplingPolicy._({
    this.id,
    required this.workspaceId,
    required this.connectionId,
    required this.modelId,
    required this.toolSamplingPolicy,
  });

  factory WorkspaceModelSelectionToolSamplingPolicy({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String modelId,
    required String toolSamplingPolicy,
  }) = _WorkspaceModelSelectionToolSamplingPolicyImpl;

  factory WorkspaceModelSelectionToolSamplingPolicy.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceModelSelectionToolSamplingPolicy(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      modelId: jsonSerialization['modelId'] as String,
      toolSamplingPolicy: jsonSerialization['toolSamplingPolicy'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String connectionId;

  String modelId;

  String toolSamplingPolicy;

  /// Returns a shallow copy of this [WorkspaceModelSelectionToolSamplingPolicy]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceModelSelectionToolSamplingPolicy copyWith({
    int? id,
    int? workspaceId,
    String? connectionId,
    String? modelId,
    String? toolSamplingPolicy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceModelSelectionToolSamplingPolicy',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'modelId': modelId,
      'toolSamplingPolicy': toolSamplingPolicy,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceModelSelectionToolSamplingPolicy',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'modelId': modelId,
      'toolSamplingPolicy': toolSamplingPolicy,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceModelSelectionToolSamplingPolicyImpl
    extends WorkspaceModelSelectionToolSamplingPolicy {
  _WorkspaceModelSelectionToolSamplingPolicyImpl({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String modelId,
    required String toolSamplingPolicy,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         connectionId: connectionId,
         modelId: modelId,
         toolSamplingPolicy: toolSamplingPolicy,
       );

  /// Returns a shallow copy of this [WorkspaceModelSelectionToolSamplingPolicy]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceModelSelectionToolSamplingPolicy copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? connectionId,
    String? modelId,
    String? toolSamplingPolicy,
  }) {
    return WorkspaceModelSelectionToolSamplingPolicy(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
      modelId: modelId ?? this.modelId,
      toolSamplingPolicy: toolSamplingPolicy ?? this.toolSamplingPolicy,
    );
  }
}
