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
import 'package:auravibes_server_client/src/protocol/protocol.dart'
    as _isctvzjc;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import '../../../features/workspace_state/models/workspace_patch_operation_kind.dart'
    as _isnc185w;
import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _iz7spkcy;

abstract class WorkspacePatchOperation
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspacePatchOperation._({
    required this.operation,
    required this.resourceKind,
    required this.resourceId,
    this.data,
    required this.fieldMask,
    this.expectedRevision,
  });

  factory WorkspacePatchOperation({
    required _isnc185w.WorkspacePatchOperationKind operation,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    String? data,
    required List<String> fieldMask,
    int? expectedRevision,
  }) = _WorkspacePatchOperationImpl;

  factory WorkspacePatchOperation.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspacePatchOperation(
      operation: _isnc185w.WorkspacePatchOperationKind.fromJson(
        (jsonSerialization['operation'] as String),
      ),
      resourceKind: _iz7spkcy.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      data: jsonSerialization['data'] as String?,
      fieldMask: _isctvzjc.Protocol().deserialize<List<String>>(
        jsonSerialization['fieldMask'],
      ),
      expectedRevision: jsonSerialization['expectedRevision'] as int?,
    );
  }

  _isnc185w.WorkspacePatchOperationKind operation;

  _iz7spkcy.WorkspaceResourceKind resourceKind;

  String resourceId;

  String? data;

  List<String> fieldMask;

  int? expectedRevision;

  /// Returns a shallow copy of this [WorkspacePatchOperation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspacePatchOperation copyWith({
    _isnc185w.WorkspacePatchOperationKind? operation,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    String? data,
    List<String>? fieldMask,
    int? expectedRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspacePatchOperation',
      'operation': operation.toJson(),
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      if (data != null) 'data': data,
      'fieldMask': fieldMask.toJson(),
      if (expectedRevision != null) 'expectedRevision': expectedRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspacePatchOperation',
      'operation': operation.toJson(),
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      if (data != null) 'data': data,
      'fieldMask': fieldMask.toJson(),
      if (expectedRevision != null) 'expectedRevision': expectedRevision,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspacePatchOperationImpl extends WorkspacePatchOperation {
  _WorkspacePatchOperationImpl({
    required _isnc185w.WorkspacePatchOperationKind operation,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    String? data,
    required List<String> fieldMask,
    int? expectedRevision,
  }) : super._(
         operation: operation,
         resourceKind: resourceKind,
         resourceId: resourceId,
         data: data,
         fieldMask: fieldMask,
         expectedRevision: expectedRevision,
       );

  /// Returns a shallow copy of this [WorkspacePatchOperation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspacePatchOperation copyWith({
    _isnc185w.WorkspacePatchOperationKind? operation,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    Object? data = _Undefined,
    List<String>? fieldMask,
    Object? expectedRevision = _Undefined,
  }) {
    return WorkspacePatchOperation(
      operation: operation ?? this.operation,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      data: data is String? ? data : this.data,
      fieldMask: fieldMask ?? this.fieldMask.map((e0) => e0).toList(),
      expectedRevision: expectedRevision is int?
          ? expectedRevision
          : this.expectedRevision,
    );
  }
}
