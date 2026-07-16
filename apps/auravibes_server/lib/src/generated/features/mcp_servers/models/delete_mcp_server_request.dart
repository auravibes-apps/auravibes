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

abstract class DeleteMcpServerRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DeleteMcpServerRequest._({
    required this.workspaceId,
    required this.mcpServerId,
  });

  factory DeleteMcpServerRequest({
    required int workspaceId,
    required String mcpServerId,
  }) = _DeleteMcpServerRequestImpl;

  factory DeleteMcpServerRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeleteMcpServerRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      mcpServerId: jsonSerialization['mcpServerId'] as String,
    );
  }

  int workspaceId;

  String mcpServerId;

  /// Returns a shallow copy of this [DeleteMcpServerRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeleteMcpServerRequest copyWith({
    int? workspaceId,
    String? mcpServerId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteMcpServerRequest',
      'workspaceId': workspaceId,
      'mcpServerId': mcpServerId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeleteMcpServerRequest',
      'workspaceId': workspaceId,
      'mcpServerId': mcpServerId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeleteMcpServerRequestImpl extends DeleteMcpServerRequest {
  _DeleteMcpServerRequestImpl({
    required int workspaceId,
    required String mcpServerId,
  }) : super._(
         workspaceId: workspaceId,
         mcpServerId: mcpServerId,
       );

  /// Returns a shallow copy of this [DeleteMcpServerRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeleteMcpServerRequest copyWith({
    int? workspaceId,
    String? mcpServerId,
  }) {
    return DeleteMcpServerRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      mcpServerId: mcpServerId ?? this.mcpServerId,
    );
  }
}
