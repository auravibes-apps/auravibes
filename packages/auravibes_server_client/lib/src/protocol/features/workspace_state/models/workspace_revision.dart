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

import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _iz7spkcy;

abstract class WorkspaceRevision
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceRevision._({
    this.id,
    required this.workspaceId,
    required this.resourceKind,
    required this.resourceId,
    required this.revision,
    required this.data,
    required this.capturedAt,
    this.actorUserId,
    this.aiInvolved,
    this.operation,
    this.conversationId,
  });

  factory WorkspaceRevision({
    int? id,
    required int workspaceId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required int revision,
    required String data,
    required DateTime capturedAt,
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  }) = _WorkspaceRevisionImpl;

  factory WorkspaceRevision.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceRevision(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      resourceKind: _iz7spkcy.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      revision: jsonSerialization['revision'] as int,
      data: jsonSerialization['data'] as String,
      capturedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['capturedAt'],
      ),
      actorUserId: jsonSerialization['actorUserId'] as String?,
      aiInvolved: jsonSerialization['aiInvolved'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['aiInvolved']),
      operation: jsonSerialization['operation'] as String?,
      conversationId: jsonSerialization['conversationId'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  _iz7spkcy.WorkspaceResourceKind resourceKind;

  String resourceId;

  int revision;

  String data;

  DateTime capturedAt;

  String? actorUserId;

  bool? aiInvolved;

  String? operation;

  String? conversationId;

  /// Returns a shallow copy of this [WorkspaceRevision]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceRevision copyWith({
    int? id,
    int? workspaceId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    int? revision,
    String? data,
    DateTime? capturedAt,
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceRevision',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      'revision': revision,
      'data': data,
      'capturedAt': capturedAt.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId,
      if (aiInvolved != null) 'aiInvolved': aiInvolved,
      if (operation != null) 'operation': operation,
      if (conversationId != null) 'conversationId': conversationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceRevision',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      'revision': revision,
      'data': data,
      'capturedAt': capturedAt.toJson(),
      if (actorUserId != null) 'actorUserId': actorUserId,
      if (aiInvolved != null) 'aiInvolved': aiInvolved,
      if (operation != null) 'operation': operation,
      if (conversationId != null) 'conversationId': conversationId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceRevisionImpl extends WorkspaceRevision {
  _WorkspaceRevisionImpl({
    int? id,
    required int workspaceId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required int revision,
    required String data,
    required DateTime capturedAt,
    String? actorUserId,
    bool? aiInvolved,
    String? operation,
    String? conversationId,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         resourceKind: resourceKind,
         resourceId: resourceId,
         revision: revision,
         data: data,
         capturedAt: capturedAt,
         actorUserId: actorUserId,
         aiInvolved: aiInvolved,
         operation: operation,
         conversationId: conversationId,
       );

  /// Returns a shallow copy of this [WorkspaceRevision]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceRevision copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    int? revision,
    String? data,
    DateTime? capturedAt,
    Object? actorUserId = _Undefined,
    Object? aiInvolved = _Undefined,
    Object? operation = _Undefined,
    Object? conversationId = _Undefined,
  }) {
    return WorkspaceRevision(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      revision: revision ?? this.revision,
      data: data ?? this.data,
      capturedAt: capturedAt ?? this.capturedAt,
      actorUserId: actorUserId is String? ? actorUserId : this.actorUserId,
      aiInvolved: aiInvolved is bool? ? aiInvolved : this.aiInvolved,
      operation: operation is String? ? operation : this.operation,
      conversationId: conversationId is String?
          ? conversationId
          : this.conversationId,
    );
  }
}
