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
import '../../../features/workspace_state/models/workspace_resource.dart'
    as _i2;
import 'package:auravibes_server/src/generated/protocol.dart' as _i3;

abstract class PatchWorkspaceStateResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PatchWorkspaceStateResponse._({
    required this.resources,
    required this.sequence,
  });

  factory PatchWorkspaceStateResponse({
    required List<_i2.WorkspaceResource> resources,
    required int sequence,
  }) = _PatchWorkspaceStateResponseImpl;

  factory PatchWorkspaceStateResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PatchWorkspaceStateResponse(
      resources: _i3.Protocol().deserialize<List<_i2.WorkspaceResource>>(
        jsonSerialization['resources'],
      ),
      sequence: jsonSerialization['sequence'] as int,
    );
  }

  List<_i2.WorkspaceResource> resources;

  int sequence;

  /// Returns a shallow copy of this [PatchWorkspaceStateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PatchWorkspaceStateResponse copyWith({
    List<_i2.WorkspaceResource>? resources,
    int? sequence,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PatchWorkspaceStateResponse',
      'resources': resources.toJson(valueToJson: (v) => v.toJson()),
      'sequence': sequence,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PatchWorkspaceStateResponse',
      'resources': resources.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'sequence': sequence,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PatchWorkspaceStateResponseImpl extends PatchWorkspaceStateResponse {
  _PatchWorkspaceStateResponseImpl({
    required List<_i2.WorkspaceResource> resources,
    required int sequence,
  }) : super._(
         resources: resources,
         sequence: sequence,
       );

  /// Returns a shallow copy of this [PatchWorkspaceStateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PatchWorkspaceStateResponse copyWith({
    List<_i2.WorkspaceResource>? resources,
    int? sequence,
  }) {
    return PatchWorkspaceStateResponse(
      resources:
          resources ?? this.resources.map((e0) => e0.copyWith()).toList(),
      sequence: sequence ?? this.sequence,
    );
  }
}
