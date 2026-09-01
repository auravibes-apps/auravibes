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

abstract class WorkspaceAuditRecord._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int workspaceId,
  required var int sequence,
  required var String actorUserId,
  required var String operation,
  var String? targetKind,
  var String? targetId,
  required var DateTime createdAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int workspaceId,
    required int sequence,
    required String actorUserId,
    required String operation,
    String? targetKind,
    String? targetId,
    required DateTime createdAt,
  }) = _WorkspaceAuditRecordImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceAuditRecord(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      actorUserId: jsonSerialization['actorUserId'] as String,
      operation: jsonSerialization['operation'] as String,
      targetKind: jsonSerialization['targetKind'] as String?,
      targetId: jsonSerialization['targetId'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [WorkspaceAuditRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceAuditRecord copyWith({
    int? id,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? operation,
    String? targetKind,
    String? targetId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceAuditRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'sequence': sequence,
      'actorUserId': actorUserId,
      'operation': operation,
      if (targetKind != null) 'targetKind': targetKind,
      if (targetId != null) 'targetId': targetId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _WorkspaceAuditRecordImpl({
  int? id,
  required int workspaceId,
  required int sequence,
  required String actorUserId,
  required String operation,
  String? targetKind,
  String? targetId,
  required DateTime createdAt,
}) extends WorkspaceAuditRecord {
  this
    : super._(
        id: id,
        workspaceId: workspaceId,
        sequence: sequence,
        actorUserId: actorUserId,
        operation: operation,
        targetKind: targetKind,
        targetId: targetId,
        createdAt: createdAt,
      );

  /// Returns a shallow copy of this [WorkspaceAuditRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceAuditRecord copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? sequence,
    String? actorUserId,
    String? operation,
    Object? targetKind = _Undefined,
    Object? targetId = _Undefined,
    DateTime? createdAt,
  }) {
    return WorkspaceAuditRecord(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      sequence: sequence ?? this.sequence,
      actorUserId: actorUserId ?? this.actorUserId,
      operation: operation ?? this.operation,
      targetKind: targetKind is String? ? targetKind : this.targetKind,
      targetId: targetId is String? ? targetId : this.targetId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
