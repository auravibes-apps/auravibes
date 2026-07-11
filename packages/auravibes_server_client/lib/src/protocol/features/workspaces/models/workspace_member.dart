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

abstract class WorkspaceMember implements _i1.SerializableModel {
  WorkspaceMember._({
    this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.removedAt,
  });

  factory WorkspaceMember({
    int? id,
    required int workspaceId,
    required String userId,
    required String role,
    required DateTime createdAt,
    DateTime? removedAt,
  }) = _WorkspaceMemberImpl;

  factory WorkspaceMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceMember(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      userId: jsonSerialization['userId'] as String,
      role: jsonSerialization['role'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      removedAt: jsonSerialization['removedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['removedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String userId;

  String role;

  DateTime createdAt;

  DateTime? removedAt;

  /// Returns a shallow copy of this [WorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceMember copyWith({
    int? id,
    int? workspaceId,
    String? userId,
    String? role,
    DateTime? createdAt,
    DateTime? removedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceMember',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
      'createdAt': createdAt.toJson(),
      if (removedAt != null) 'removedAt': removedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceMemberImpl extends WorkspaceMember {
  _WorkspaceMemberImpl({
    int? id,
    required int workspaceId,
    required String userId,
    required String role,
    required DateTime createdAt,
    DateTime? removedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         userId: userId,
         role: role,
         createdAt: createdAt,
         removedAt: removedAt,
       );

  /// Returns a shallow copy of this [WorkspaceMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceMember copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? userId,
    String? role,
    DateTime? createdAt,
    Object? removedAt = _Undefined,
  }) {
    return WorkspaceMember(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      removedAt: removedAt is DateTime? ? removedAt : this.removedAt,
    );
  }
}
