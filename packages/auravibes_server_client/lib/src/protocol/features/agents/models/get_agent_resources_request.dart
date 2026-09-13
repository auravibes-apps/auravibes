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

abstract class GetAgentResourcesRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  GetAgentResourcesRequest._({
    required this.workspaceId,
    required this.agentId,
  });

  factory GetAgentResourcesRequest({
    required int workspaceId,
    required String agentId,
  }) = _GetAgentResourcesRequestImpl;

  factory GetAgentResourcesRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GetAgentResourcesRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      agentId: jsonSerialization['agentId'] as String,
    );
  }

  int workspaceId;

  String agentId;

  /// Returns a shallow copy of this [GetAgentResourcesRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  GetAgentResourcesRequest copyWith({
    int? workspaceId,
    String? agentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetAgentResourcesRequest',
      'workspaceId': workspaceId,
      'agentId': agentId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GetAgentResourcesRequest',
      'workspaceId': workspaceId,
      'agentId': agentId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _GetAgentResourcesRequestImpl extends GetAgentResourcesRequest {
  _GetAgentResourcesRequestImpl({
    required int workspaceId,
    required String agentId,
  }) : super._(
         workspaceId: workspaceId,
         agentId: agentId,
       );

  /// Returns a shallow copy of this [GetAgentResourcesRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  GetAgentResourcesRequest copyWith({
    int? workspaceId,
    String? agentId,
  }) {
    return GetAgentResourcesRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      agentId: agentId ?? this.agentId,
    );
  }
}
