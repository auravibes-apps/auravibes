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
import 'package:serverpod/serverpod.dart' as _is;

abstract class WorkspaceHistoryRestoreRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WorkspaceHistoryRestoreRequest._({
    required this.workspaceId,
    required this.targetJson,
    required this.revision,
    required this.requestId,
  });

  factory WorkspaceHistoryRestoreRequest({
    required int workspaceId,
    required String targetJson,
    required int revision,
    required String requestId,
  }) = _WorkspaceHistoryRestoreRequestImpl;

  factory WorkspaceHistoryRestoreRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceHistoryRestoreRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      targetJson: jsonSerialization['targetJson'] as String,
      revision: jsonSerialization['revision'] as int,
      requestId: jsonSerialization['requestId'] as String,
    );
  }

  int workspaceId;

  String targetJson;

  int revision;

  String requestId;

  /// Returns a shallow copy of this [WorkspaceHistoryRestoreRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WorkspaceHistoryRestoreRequest copyWith({
    int? workspaceId,
    String? targetJson,
    int? revision,
    String? requestId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceHistoryRestoreRequest',
      'workspaceId': workspaceId,
      'targetJson': targetJson,
      'revision': revision,
      'requestId': requestId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceHistoryRestoreRequest',
      'workspaceId': workspaceId,
      'targetJson': targetJson,
      'revision': revision,
      'requestId': requestId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _WorkspaceHistoryRestoreRequestImpl
    extends WorkspaceHistoryRestoreRequest {
  _WorkspaceHistoryRestoreRequestImpl({
    required int workspaceId,
    required String targetJson,
    required int revision,
    required String requestId,
  }) : super._(
         workspaceId: workspaceId,
         targetJson: targetJson,
         revision: revision,
         requestId: requestId,
       );

  /// Returns a shallow copy of this [WorkspaceHistoryRestoreRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WorkspaceHistoryRestoreRequest copyWith({
    int? workspaceId,
    String? targetJson,
    int? revision,
    String? requestId,
  }) {
    return WorkspaceHistoryRestoreRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      targetJson: targetJson ?? this.targetJson,
      revision: revision ?? this.revision,
      requestId: requestId ?? this.requestId,
    );
  }
}
