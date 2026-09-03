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

abstract class ObjectUpload implements _i1.SerializableModel {
  ObjectUpload._({
    this.id,
    required this.workspaceId,
    required this.objectId,
    required this.actorUserId,
    required this.requestId,
    required this.requestHash,
    required this.expiresAt,
    this.completedAt,
    required this.createdAt,
  });

  factory ObjectUpload({
    int? id,
    required int workspaceId,
    required int objectId,
    required String actorUserId,
    required String requestId,
    required String requestHash,
    required DateTime expiresAt,
    DateTime? completedAt,
    required DateTime createdAt,
  }) = _ObjectUploadImpl;

  factory ObjectUpload.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectUpload(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
      actorUserId: jsonSerialization['actorUserId'] as String,
      requestId: jsonSerialization['requestId'] as String,
      requestHash: jsonSerialization['requestHash'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  int objectId;

  String actorUserId;

  String requestId;

  String requestHash;

  DateTime expiresAt;

  DateTime? completedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [ObjectUpload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ObjectUpload copyWith({
    int? id,
    int? workspaceId,
    int? objectId,
    String? actorUserId,
    String? requestId,
    String? requestHash,
    DateTime? expiresAt,
    DateTime? completedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectUpload',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'actorUserId': actorUserId,
      'requestId': requestId,
      'requestHash': requestHash,
      'expiresAt': expiresAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ObjectUploadImpl extends ObjectUpload {
  _ObjectUploadImpl({
    int? id,
    required int workspaceId,
    required int objectId,
    required String actorUserId,
    required String requestId,
    required String requestHash,
    required DateTime expiresAt,
    DateTime? completedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectId: objectId,
         actorUserId: actorUserId,
         requestId: requestId,
         requestHash: requestHash,
         expiresAt: expiresAt,
         completedAt: completedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ObjectUpload]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ObjectUpload copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? objectId,
    String? actorUserId,
    String? requestId,
    String? requestHash,
    DateTime? expiresAt,
    Object? completedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return ObjectUpload(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
      actorUserId: actorUserId ?? this.actorUserId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
