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

abstract class WorkspaceObject implements _i1.SerializableModel {
  WorkspaceObject._({
    this.id,
    required this.workspaceId,
    required this.objectKey,
    required this.purpose,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    required this.checksumSha256,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkspaceObject({
    int? id,
    required int workspaceId,
    required String objectKey,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required String status,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceObjectImpl;

  factory WorkspaceObject.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceObject(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectKey: jsonSerialization['objectKey'] as String,
      purpose: jsonSerialization['purpose'] as String,
      displayName: jsonSerialization['displayName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      checksumSha256: jsonSerialization['checksumSha256'] as String,
      status: jsonSerialization['status'] as String,
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String objectKey;

  String purpose;

  String displayName;

  String mimeType;

  int sizeBytes;

  String checksumSha256;

  String status;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [WorkspaceObject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceObject copyWith({
    int? id,
    int? workspaceId,
    String? objectKey,
    String? purpose,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
    String? status,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceObject',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectKey': objectKey,
      'purpose': purpose,
      'displayName': displayName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'checksumSha256': checksumSha256,
      'status': status,
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

class _Undefined {}

class _WorkspaceObjectImpl extends WorkspaceObject {
  _WorkspaceObjectImpl({
    int? id,
    required int workspaceId,
    required String objectKey,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required String status,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectKey: objectKey,
         purpose: purpose,
         displayName: displayName,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         checksumSha256: checksumSha256,
         status: status,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [WorkspaceObject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceObject copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? objectKey,
    String? purpose,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
    String? status,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceObject(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectKey: objectKey ?? this.objectKey,
      purpose: purpose ?? this.purpose,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      status: status ?? this.status,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
