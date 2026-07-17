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

abstract class ObjectReference implements _i1.SerializableModel {
  ObjectReference._({
    this.id,
    required this.workspaceId,
    required this.objectId,
    required this.messageId,
    required this.createdAt,
    this.deletedAt,
  });

  factory ObjectReference({
    int? id,
    required int workspaceId,
    required int objectId,
    required int messageId,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _ObjectReferenceImpl;

  factory ObjectReference.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectReference(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
      messageId: jsonSerialization['messageId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
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

  int objectId;

  int messageId;

  DateTime createdAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [ObjectReference]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ObjectReference copyWith({
    int? id,
    int? workspaceId,
    int? objectId,
    int? messageId,
    DateTime? createdAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectReference',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'messageId': messageId,
      'createdAt': createdAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ObjectReferenceImpl extends ObjectReference {
  _ObjectReferenceImpl({
    int? id,
    required int workspaceId,
    required int objectId,
    required int messageId,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectId: objectId,
         messageId: messageId,
         createdAt: createdAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [ObjectReference]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ObjectReference copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? objectId,
    int? messageId,
    DateTime? createdAt,
    Object? deletedAt = _Undefined,
  }) {
    return ObjectReference(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
