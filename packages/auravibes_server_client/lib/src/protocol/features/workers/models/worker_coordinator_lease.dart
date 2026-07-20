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

abstract class WorkerCoordinatorLease implements _i1.SerializableModel {
  WorkerCoordinatorLease._({
    this.id,
    required this.key,
    required this.ownerId,
    required this.fencingToken,
    required this.expiresAt,
  });

  factory WorkerCoordinatorLease({
    int? id,
    required String key,
    required String ownerId,
    required int fencingToken,
    required DateTime expiresAt,
  }) = _WorkerCoordinatorLeaseImpl;

  factory WorkerCoordinatorLease.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkerCoordinatorLease(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
      ownerId: jsonSerialization['ownerId'] as String,
      fencingToken: jsonSerialization['fencingToken'] as int,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String key;

  String ownerId;

  int fencingToken;

  DateTime expiresAt;

  /// Returns a shallow copy of this [WorkerCoordinatorLease]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkerCoordinatorLease copyWith({
    int? id,
    String? key,
    String? ownerId,
    int? fencingToken,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkerCoordinatorLease',
      if (id != null) 'id': id,
      'key': key,
      'ownerId': ownerId,
      'fencingToken': fencingToken,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkerCoordinatorLeaseImpl extends WorkerCoordinatorLease {
  _WorkerCoordinatorLeaseImpl({
    int? id,
    required String key,
    required String ownerId,
    required int fencingToken,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         key: key,
         ownerId: ownerId,
         fencingToken: fencingToken,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [WorkerCoordinatorLease]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkerCoordinatorLease copyWith({
    Object? id = _Undefined,
    String? key,
    String? ownerId,
    int? fencingToken,
    DateTime? expiresAt,
  }) {
    return WorkerCoordinatorLease(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
      ownerId: ownerId ?? this.ownerId,
      fencingToken: fencingToken ?? this.fencingToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
