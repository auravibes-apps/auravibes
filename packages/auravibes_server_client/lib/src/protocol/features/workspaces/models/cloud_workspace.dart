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

abstract class CloudWorkspace._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var String name,
  required var String ownerUserId,
  required var int revision,
  required var int sequence,
  required var DateTime createdAt,
  required var DateTime updatedAt,
  var DateTime? deletedAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required String name,
    required String ownerUserId,
    required int revision,
    required int sequence,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _CloudWorkspaceImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return CloudWorkspace(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      revision: jsonSerialization['revision'] as int,
      sequence: jsonSerialization['sequence'] as int,
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

  /// Returns a shallow copy of this [CloudWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudWorkspace copyWith({
    int? id,
    String? name,
    String? ownerUserId,
    int? revision,
    int? sequence,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspace',
      if (id != null) 'id': id,
      'name': name,
      'ownerUserId': ownerUserId,
      'revision': revision,
      'sequence': sequence,
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

class _CloudWorkspaceImpl({
  int? id,
  required String name,
  required String ownerUserId,
  required int revision,
  required int sequence,
  required DateTime createdAt,
  required DateTime updatedAt,
  DateTime? deletedAt,
}) extends CloudWorkspace {
  this
    : super._(
        id: id,
        name: name,
        ownerUserId: ownerUserId,
        revision: revision,
        sequence: sequence,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  /// Returns a shallow copy of this [CloudWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CloudWorkspace copyWith({
    Object? id = _Undefined,
    String? name,
    String? ownerUserId,
    int? revision,
    int? sequence,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return CloudWorkspace(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      revision: revision ?? this.revision,
      sequence: sequence ?? this.sequence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
