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
  });

  factory WorkspaceRevision({
    int? id,
    required int workspaceId,
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required int revision,
    required String data,
    required DateTime capturedAt,
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
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         resourceKind: resourceKind,
         resourceId: resourceId,
         revision: revision,
         data: data,
         capturedAt: capturedAt,
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
  }) {
    return WorkspaceRevision(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      revision: revision ?? this.revision,
      data: data ?? this.data,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
