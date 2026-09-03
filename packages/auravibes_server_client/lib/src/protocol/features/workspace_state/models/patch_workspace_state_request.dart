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

import '../../../features/workspace_state/models/workspace_patch_operation.dart'
    as _i2;

import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i3;

abstract class PatchWorkspaceStateRequest implements _i1.SerializableModel {
  PatchWorkspaceStateRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.operations,
  });

  factory PatchWorkspaceStateRequest({
    required int workspaceId,
    required String requestId,
    required List<_i2.WorkspacePatchOperation> operations,
  }) = _PatchWorkspaceStateRequestImpl;

  factory PatchWorkspaceStateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PatchWorkspaceStateRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      operations: _i3.Protocol().deserialize<List<_i2.WorkspacePatchOperation>>(
        jsonSerialization['operations'],
      ),
    );
  }

  int workspaceId;

  String requestId;

  List<_i2.WorkspacePatchOperation> operations;

  /// Returns a shallow copy of this [PatchWorkspaceStateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatchWorkspaceStateRequest copyWith({
    int? workspaceId,
    String? requestId,
    List<_i2.WorkspacePatchOperation>? operations,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatchWorkspaceStateRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'operations': operations.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PatchWorkspaceStateRequestImpl extends PatchWorkspaceStateRequest {
  _PatchWorkspaceStateRequestImpl({
    required int workspaceId,
    required String requestId,
    required List<_i2.WorkspacePatchOperation> operations,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         operations: operations,
       );

  /// Returns a shallow copy of this [PatchWorkspaceStateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatchWorkspaceStateRequest copyWith({
    int? workspaceId,
    String? requestId,
    List<_i2.WorkspacePatchOperation>? operations,
  }) {
    return PatchWorkspaceStateRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      operations:
          operations ?? this.operations.map((e0) => e0.copyWith()).toList(),
    );
  }
}
