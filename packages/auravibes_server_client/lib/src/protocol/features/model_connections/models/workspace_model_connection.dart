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

abstract class WorkspaceModelConnection implements _i1.SerializableModel {
  WorkspaceModelConnection._({
    this.id,
    required this.workspaceId,
    required this.connectionId,
    required this.providerId,
    required this.name,
    this.url,
    this.keySuffix,
    required this.hasSecret,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory WorkspaceModelConnection({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String providerId,
    required String name,
    String? url,
    String? keySuffix,
    required bool hasSecret,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _WorkspaceModelConnectionImpl;

  factory WorkspaceModelConnection.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceModelConnection(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      providerId: jsonSerialization['providerId'] as String,
      name: jsonSerialization['name'] as String,
      url: jsonSerialization['url'] as String?,
      keySuffix: jsonSerialization['keySuffix'] as String?,
      hasSecret: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasSecret']),
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

  String connectionId;

  String providerId;

  String name;

  String? url;

  String? keySuffix;

  bool hasSecret;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [WorkspaceModelConnection]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceModelConnection copyWith({
    int? id,
    int? workspaceId,
    String? connectionId,
    String? providerId,
    String? name,
    String? url,
    String? keySuffix,
    bool? hasSecret,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceModelConnection',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'providerId': providerId,
      'name': name,
      if (url != null) 'url': url,
      if (keySuffix != null) 'keySuffix': keySuffix,
      'hasSecret': hasSecret,
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

class _WorkspaceModelConnectionImpl extends WorkspaceModelConnection {
  _WorkspaceModelConnectionImpl({
    int? id,
    required int workspaceId,
    required String connectionId,
    required String providerId,
    required String name,
    String? url,
    String? keySuffix,
    required bool hasSecret,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         connectionId: connectionId,
         providerId: providerId,
         name: name,
         url: url,
         keySuffix: keySuffix,
         hasSecret: hasSecret,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [WorkspaceModelConnection]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceModelConnection copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? connectionId,
    String? providerId,
    String? name,
    Object? url = _Undefined,
    Object? keySuffix = _Undefined,
    bool? hasSecret,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceModelConnection(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      url: url is String? ? url : this.url,
      keySuffix: keySuffix is String? ? keySuffix : this.keySuffix,
      hasSecret: hasSecret ?? this.hasSecret,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
