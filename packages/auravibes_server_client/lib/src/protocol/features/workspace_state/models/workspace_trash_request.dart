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

abstract class WorkspaceTrashRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceTrashRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.targetJson,
    required this.planToken,
  });

  factory WorkspaceTrashRequest({
    required int workspaceId,
    required String requestId,
    required String targetJson,
    required String planToken,
  }) = _WorkspaceTrashRequestImpl;

  factory WorkspaceTrashRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceTrashRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      targetJson: jsonSerialization['targetJson'] as String,
      planToken: jsonSerialization['planToken'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String targetJson;

  String planToken;

  /// Returns a shallow copy of this [WorkspaceTrashRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceTrashRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? targetJson,
    String? planToken,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceTrashRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'targetJson': targetJson,
      'planToken': planToken,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceTrashRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'targetJson': targetJson,
      'planToken': planToken,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _WorkspaceTrashRequestImpl extends WorkspaceTrashRequest {
  _WorkspaceTrashRequestImpl({
    required int workspaceId,
    required String requestId,
    required String targetJson,
    required String planToken,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         targetJson: targetJson,
         planToken: planToken,
       );

  /// Returns a shallow copy of this [WorkspaceTrashRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceTrashRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? targetJson,
    String? planToken,
  }) {
    return WorkspaceTrashRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      targetJson: targetJson ?? this.targetJson,
      planToken: planToken ?? this.planToken,
    );
  }
}
