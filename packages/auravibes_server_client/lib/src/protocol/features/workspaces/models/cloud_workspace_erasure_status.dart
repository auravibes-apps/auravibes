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

abstract class CloudWorkspaceErasureStatus
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CloudWorkspaceErasureStatus._({
    required this.workspaceId,
    required this.workspaceName,
    required this.requestId,
    required this.state,
    required this.requestedAt,
    this.completedAt,
  });

  factory CloudWorkspaceErasureStatus({
    required int workspaceId,
    required String workspaceName,
    required String requestId,
    required String state,
    required DateTime requestedAt,
    DateTime? completedAt,
  }) = _CloudWorkspaceErasureStatusImpl;

  factory CloudWorkspaceErasureStatus.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceErasureStatus(
      workspaceId: jsonSerialization['workspaceId'] as int,
      workspaceName: jsonSerialization['workspaceName'] as String,
      requestId: jsonSerialization['requestId'] as String,
      state: jsonSerialization['state'] as String,
      requestedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['requestedAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  int workspaceId;

  String workspaceName;

  String requestId;

  String state;

  DateTime requestedAt;

  DateTime? completedAt;

  /// Returns a shallow copy of this [CloudWorkspaceErasureStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CloudWorkspaceErasureStatus copyWith({
    int? workspaceId,
    String? workspaceName,
    String? requestId,
    String? state,
    DateTime? requestedAt,
    DateTime? completedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceErasureStatus',
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'requestId': requestId,
      'state': state,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CloudWorkspaceErasureStatus',
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'requestId': requestId,
      'state': state,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CloudWorkspaceErasureStatusImpl extends CloudWorkspaceErasureStatus {
  _CloudWorkspaceErasureStatusImpl({
    required int workspaceId,
    required String workspaceName,
    required String requestId,
    required String state,
    required DateTime requestedAt,
    DateTime? completedAt,
  }) : super._(
         workspaceId: workspaceId,
         workspaceName: workspaceName,
         requestId: requestId,
         state: state,
         requestedAt: requestedAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [CloudWorkspaceErasureStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CloudWorkspaceErasureStatus copyWith({
    int? workspaceId,
    String? workspaceName,
    String? requestId,
    String? state,
    DateTime? requestedAt,
    Object? completedAt = _Undefined,
  }) {
    return CloudWorkspaceErasureStatus(
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      requestId: requestId ?? this.requestId,
      state: state ?? this.state,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}
