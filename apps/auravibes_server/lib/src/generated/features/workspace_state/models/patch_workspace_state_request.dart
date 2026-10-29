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

import '../../../features/workspace_state/models/workspace_patch_operation.dart'
    as _iou6lkaa;
import '../../../features/workspace_state/models/workspace_view_move.dart'
    as _ia3e3t31;

abstract class PatchWorkspaceStateRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PatchWorkspaceStateRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.operations,
    this.viewMoves,
  });

  factory PatchWorkspaceStateRequest({
    required int workspaceId,
    required String requestId,
    required List<_iou6lkaa.WorkspacePatchOperation> operations,
    List<_ia3e3t31.WorkspaceViewMove>? viewMoves,
  }) = _PatchWorkspaceStateRequestImpl;

  factory PatchWorkspaceStateRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PatchWorkspaceStateRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      operations: _if5qez1k.Protocol()
          .deserialize<List<_iou6lkaa.WorkspacePatchOperation>>(
            jsonSerialization['operations'],
          ),
      viewMoves: jsonSerialization['viewMoves'] == null
          ? null
          : _if5qez1k.Protocol().deserialize<List<_ia3e3t31.WorkspaceViewMove>>(
              jsonSerialization['viewMoves'],
            ),
    );
  }

  int workspaceId;

  String requestId;

  List<_iou6lkaa.WorkspacePatchOperation> operations;

  List<_ia3e3t31.WorkspaceViewMove>? viewMoves;

  /// Returns a shallow copy of this [PatchWorkspaceStateRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PatchWorkspaceStateRequest copyWith({
    int? workspaceId,
    String? requestId,
    List<_iou6lkaa.WorkspacePatchOperation>? operations,
    List<_ia3e3t31.WorkspaceViewMove>? viewMoves,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatchWorkspaceStateRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'operations': operations.toJson(valueToJson: (v) => v.toJson()),
      if (viewMoves != null)
        'viewMoves': viewMoves?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatchWorkspaceStateRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'operations': operations.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (viewMoves != null)
        'viewMoves': viewMoves?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PatchWorkspaceStateRequestImpl extends PatchWorkspaceStateRequest {
  _PatchWorkspaceStateRequestImpl({
    required int workspaceId,
    required String requestId,
    required List<_iou6lkaa.WorkspacePatchOperation> operations,
    List<_ia3e3t31.WorkspaceViewMove>? viewMoves,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         operations: operations,
         viewMoves: viewMoves,
       );

  /// Returns a shallow copy of this [PatchWorkspaceStateRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PatchWorkspaceStateRequest copyWith({
    int? workspaceId,
    String? requestId,
    List<_iou6lkaa.WorkspacePatchOperation>? operations,
    Object? viewMoves = _Undefined,
  }) {
    return PatchWorkspaceStateRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      operations:
          operations ?? this.operations.map((e0) => e0.copyWith()).toList(),
      viewMoves: viewMoves is List<_ia3e3t31.WorkspaceViewMove>?
          ? viewMoves
          : this.viewMoves?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
