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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _i2;

abstract class WorkspaceResource._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int workspaceId,
  required var _i2.WorkspaceResourceKind resourceKind,
  required var String resourceId,
  required var String data,
  required var int revision,
  required var DateTime createdAt,
  required var DateTime updatedAt,
  var DateTime? deletedAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int workspaceId,
    required _i2.WorkspaceResourceKind resourceKind,
    required String resourceId,
    required String data,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceResourceImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceResource(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      resourceKind: _i2.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resourceId: jsonSerialization['resourceId'] as String,
      data: jsonSerialization['data'] as String,
      revision: jsonSerialization['revision'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// Returns a shallow copy of this [WorkspaceResource]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceResource copyWith({
    int? id,
    int? workspaceId,
    _i2.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    String? data,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceResource',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'resourceKind': resourceKind.toJson(),
      'resourceId': resourceId,
      'data': data,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _WorkspaceResourceImpl({
  int? id,
  required int workspaceId,
  required _i2.WorkspaceResourceKind resourceKind,
  required String resourceId,
  required String data,
  required int revision,
  required DateTime createdAt,
  required DateTime updatedAt,
  DateTime? deletedAt,
}) extends WorkspaceResource {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        resourceKind: resourceKind,
        resourceId: resourceId,
        data: data,
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  /// Returns a shallow copy of this [WorkspaceResource]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceResource copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    _i2.WorkspaceResourceKind? resourceKind,
    String? resourceId,
    String? data,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceResource(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      resourceKind: resourceKind ?? this.resourceKind,
      resourceId: resourceId ?? this.resourceId,
      data: data ?? this.data,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
