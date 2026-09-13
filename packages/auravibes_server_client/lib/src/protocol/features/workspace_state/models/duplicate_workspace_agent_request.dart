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

abstract class DuplicateWorkspaceAgentRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DuplicateWorkspaceAgentRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.sourceAgentId,
  });

  factory DuplicateWorkspaceAgentRequest({
    required int workspaceId,
    required String requestId,
    required String sourceAgentId,
  }) = _DuplicateWorkspaceAgentRequestImpl;

  factory DuplicateWorkspaceAgentRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DuplicateWorkspaceAgentRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      sourceAgentId: jsonSerialization['sourceAgentId'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String sourceAgentId;

  /// Returns a shallow copy of this [DuplicateWorkspaceAgentRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DuplicateWorkspaceAgentRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? sourceAgentId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DuplicateWorkspaceAgentRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'sourceAgentId': sourceAgentId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DuplicateWorkspaceAgentRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'sourceAgentId': sourceAgentId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _DuplicateWorkspaceAgentRequestImpl
    extends DuplicateWorkspaceAgentRequest {
  _DuplicateWorkspaceAgentRequestImpl({
    required int workspaceId,
    required String requestId,
    required String sourceAgentId,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         sourceAgentId: sourceAgentId,
       );

  /// Returns a shallow copy of this [DuplicateWorkspaceAgentRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DuplicateWorkspaceAgentRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? sourceAgentId,
  }) {
    return DuplicateWorkspaceAgentRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      sourceAgentId: sourceAgentId ?? this.sourceAgentId,
    );
  }
}
