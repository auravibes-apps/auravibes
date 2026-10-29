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

abstract class WorkspaceTrashBatch
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceTrashBatch._({
    this.id,
    required this.workspaceId,
    required this.batchId,
    required this.targetJson,
    required this.name,
    required this.membersJson,
    required this.createdAt,
    this.restoredAt,
    this.restoredResultJson,
  });

  factory WorkspaceTrashBatch({
    int? id,
    required int workspaceId,
    required String batchId,
    required String targetJson,
    required String name,
    required String membersJson,
    required DateTime createdAt,
    DateTime? restoredAt,
    String? restoredResultJson,
  }) = _WorkspaceTrashBatchImpl;

  factory WorkspaceTrashBatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceTrashBatch(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      batchId: jsonSerialization['batchId'] as String,
      targetJson: jsonSerialization['targetJson'] as String,
      name: jsonSerialization['name'] as String,
      membersJson: jsonSerialization['membersJson'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      restoredAt: jsonSerialization['restoredAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['restoredAt'],
            ),
      restoredResultJson: jsonSerialization['restoredResultJson'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String batchId;

  String targetJson;

  String name;

  String membersJson;

  DateTime createdAt;

  DateTime? restoredAt;

  String? restoredResultJson;

  /// Returns a shallow copy of this [WorkspaceTrashBatch]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceTrashBatch copyWith({
    int? id,
    int? workspaceId,
    String? batchId,
    String? targetJson,
    String? name,
    String? membersJson,
    DateTime? createdAt,
    DateTime? restoredAt,
    String? restoredResultJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceTrashBatch',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'batchId': batchId,
      'targetJson': targetJson,
      'name': name,
      'membersJson': membersJson,
      'createdAt': createdAt.toJson(),
      if (restoredAt != null) 'restoredAt': restoredAt?.toJson(),
      if (restoredResultJson != null) 'restoredResultJson': restoredResultJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceTrashBatch',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'batchId': batchId,
      'targetJson': targetJson,
      'name': name,
      'membersJson': membersJson,
      'createdAt': createdAt.toJson(),
      if (restoredAt != null) 'restoredAt': restoredAt?.toJson(),
      if (restoredResultJson != null) 'restoredResultJson': restoredResultJson,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceTrashBatchImpl extends WorkspaceTrashBatch {
  _WorkspaceTrashBatchImpl({
    int? id,
    required int workspaceId,
    required String batchId,
    required String targetJson,
    required String name,
    required String membersJson,
    required DateTime createdAt,
    DateTime? restoredAt,
    String? restoredResultJson,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         batchId: batchId,
         targetJson: targetJson,
         name: name,
         membersJson: membersJson,
         createdAt: createdAt,
         restoredAt: restoredAt,
         restoredResultJson: restoredResultJson,
       );

  /// Returns a shallow copy of this [WorkspaceTrashBatch]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceTrashBatch copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? batchId,
    String? targetJson,
    String? name,
    String? membersJson,
    DateTime? createdAt,
    Object? restoredAt = _Undefined,
    Object? restoredResultJson = _Undefined,
  }) {
    return WorkspaceTrashBatch(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      batchId: batchId ?? this.batchId,
      targetJson: targetJson ?? this.targetJson,
      name: name ?? this.name,
      membersJson: membersJson ?? this.membersJson,
      createdAt: createdAt ?? this.createdAt,
      restoredAt: restoredAt is DateTime? ? restoredAt : this.restoredAt,
      restoredResultJson: restoredResultJson is String?
          ? restoredResultJson
          : this.restoredResultJson,
    );
  }
}
