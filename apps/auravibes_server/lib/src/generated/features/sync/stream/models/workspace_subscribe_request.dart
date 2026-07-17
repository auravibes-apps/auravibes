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
import 'package:auravibes_server/src/generated/protocol.dart' as _i2;

abstract class WorkspaceSubscribeRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceSubscribeRequest._({
    required this.workspaceId,
    required this.afterSequence,
    required this.activeTurnIds,
  });

  factory WorkspaceSubscribeRequest({
    required int workspaceId,
    required int afterSequence,
    required List<String> activeTurnIds,
  }) = _WorkspaceSubscribeRequestImpl;

  factory WorkspaceSubscribeRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceSubscribeRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      afterSequence: jsonSerialization['afterSequence'] as int,
      activeTurnIds: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['activeTurnIds'],
      ),
    );
  }

  int workspaceId;

  int afterSequence;

  List<String> activeTurnIds;

  /// Returns a shallow copy of this [WorkspaceSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceSubscribeRequest copyWith({
    int? workspaceId,
    int? afterSequence,
    List<String>? activeTurnIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceSubscribeRequest',
      'workspaceId': workspaceId,
      'afterSequence': afterSequence,
      'activeTurnIds': activeTurnIds.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceSubscribeRequest',
      'workspaceId': workspaceId,
      'afterSequence': afterSequence,
      'activeTurnIds': activeTurnIds.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _WorkspaceSubscribeRequestImpl extends WorkspaceSubscribeRequest {
  _WorkspaceSubscribeRequestImpl({
    required int workspaceId,
    required int afterSequence,
    required List<String> activeTurnIds,
  }) : super._(
         workspaceId: workspaceId,
         afterSequence: afterSequence,
         activeTurnIds: activeTurnIds,
       );

  /// Returns a shallow copy of this [WorkspaceSubscribeRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceSubscribeRequest copyWith({
    int? workspaceId,
    int? afterSequence,
    List<String>? activeTurnIds,
  }) {
    return WorkspaceSubscribeRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      afterSequence: afterSequence ?? this.afterSequence,
      activeTurnIds:
          activeTurnIds ?? this.activeTurnIds.map((e0) => e0).toList(),
    );
  }
}
