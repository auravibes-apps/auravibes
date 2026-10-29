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

abstract class WorkspaceView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceView._({
    this.id,
    required this.workspaceId,
    required this.stableId,
    required this.data,
    required this.revision,
    required this.history,
    this.deletedAt,
  });

  factory WorkspaceView({
    int? id,
    required int workspaceId,
    required String stableId,
    required String data,
    required int revision,
    required String history,
    DateTime? deletedAt,
  }) = _WorkspaceViewImpl;

  factory WorkspaceView.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceView(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      stableId: jsonSerialization['stableId'] as String,
      data: jsonSerialization['data'] as String,
      revision: jsonSerialization['revision'] as int,
      history: jsonSerialization['history'] as String,
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String stableId;

  String data;

  int revision;

  String history;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [WorkspaceView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceView copyWith({
    int? id,
    int? workspaceId,
    String? stableId,
    String? data,
    int? revision,
    String? history,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceView',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      'data': data,
      'revision': revision,
      'history': history,
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceView',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'stableId': stableId,
      'data': data,
      'revision': revision,
      'history': history,
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceViewImpl extends WorkspaceView {
  _WorkspaceViewImpl({
    int? id,
    required int workspaceId,
    required String stableId,
    required String data,
    required int revision,
    required String history,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         stableId: stableId,
         data: data,
         revision: revision,
         history: history,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [WorkspaceView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceView copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? stableId,
    String? data,
    int? revision,
    String? history,
    Object? deletedAt = _Undefined,
  }) {
    return WorkspaceView(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      stableId: stableId ?? this.stableId,
      data: data ?? this.data,
      revision: revision ?? this.revision,
      history: history ?? this.history,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
