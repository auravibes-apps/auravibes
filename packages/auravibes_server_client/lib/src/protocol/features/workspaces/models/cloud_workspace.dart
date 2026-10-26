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

abstract class CloudWorkspace
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CloudWorkspace._({
    this.id,
    required this.name,
    required this.ownerUserId,
    required this.revision,
    required this.sequence,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.erasureRequestedAt,
  });

  factory CloudWorkspace({
    int? id,
    required String name,
    required String ownerUserId,
    required int revision,
    required int sequence,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    DateTime? erasureRequestedAt,
  }) = _CloudWorkspaceImpl;

  factory CloudWorkspace.fromJson(Map<String, dynamic> jsonSerialization) {
    return CloudWorkspace(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      revision: jsonSerialization['revision'] as int,
      sequence: jsonSerialization['sequence'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      erasureRequestedAt: jsonSerialization['erasureRequestedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['erasureRequestedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  String ownerUserId;

  int revision;

  int sequence;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  DateTime? erasureRequestedAt;

  /// Returns a shallow copy of this [CloudWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CloudWorkspace copyWith({
    int? id,
    String? name,
    String? ownerUserId,
    int? revision,
    int? sequence,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? erasureRequestedAt,
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
      if (erasureRequestedAt != null)
        'erasureRequestedAt': erasureRequestedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
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
      if (erasureRequestedAt != null)
        'erasureRequestedAt': erasureRequestedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CloudWorkspaceImpl extends CloudWorkspace {
  _CloudWorkspaceImpl({
    int? id,
    required String name,
    required String ownerUserId,
    required int revision,
    required int sequence,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    DateTime? erasureRequestedAt,
  }) : super._(
         id: id,
         name: name,
         ownerUserId: ownerUserId,
         revision: revision,
         sequence: sequence,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         erasureRequestedAt: erasureRequestedAt,
       );

  /// Returns a shallow copy of this [CloudWorkspace]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    Object? erasureRequestedAt = _Undefined,
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
      erasureRequestedAt: erasureRequestedAt is DateTime?
          ? erasureRequestedAt
          : this.erasureRequestedAt,
    );
  }
}
