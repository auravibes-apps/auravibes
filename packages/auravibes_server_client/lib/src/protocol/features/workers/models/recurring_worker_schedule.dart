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

abstract class RecurringWorkerSchedule implements _i1.SerializableModel {
  RecurringWorkerSchedule._({
    this.id,
    required this.workerKey,
    required this.nextRunAt,
    this.runToken,
    this.leaderFencingToken,
    this.runLeaseExpiresAt,
    required this.updatedAt,
  });

  factory RecurringWorkerSchedule({
    int? id,
    required String workerKey,
    required DateTime nextRunAt,
    String? runToken,
    int? leaderFencingToken,
    DateTime? runLeaseExpiresAt,
    required DateTime updatedAt,
  }) = _RecurringWorkerScheduleImpl;

  factory RecurringWorkerSchedule.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RecurringWorkerSchedule(
      id: jsonSerialization['id'] as int?,
      workerKey: jsonSerialization['workerKey'] as String,
      nextRunAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['nextRunAt'],
      ),
      runToken: jsonSerialization['runToken'] as String?,
      leaderFencingToken: jsonSerialization['leaderFencingToken'] as int?,
      runLeaseExpiresAt: jsonSerialization['runLeaseExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['runLeaseExpiresAt'],
            ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String workerKey;

  DateTime nextRunAt;

  String? runToken;

  int? leaderFencingToken;

  DateTime? runLeaseExpiresAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [RecurringWorkerSchedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RecurringWorkerSchedule copyWith({
    int? id,
    String? workerKey,
    DateTime? nextRunAt,
    String? runToken,
    int? leaderFencingToken,
    DateTime? runLeaseExpiresAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RecurringWorkerSchedule',
      if (id != null) 'id': id,
      'workerKey': workerKey,
      'nextRunAt': nextRunAt.toJson(),
      if (runToken != null) 'runToken': runToken,
      if (leaderFencingToken != null) 'leaderFencingToken': leaderFencingToken,
      if (runLeaseExpiresAt != null)
        'runLeaseExpiresAt': runLeaseExpiresAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RecurringWorkerScheduleImpl extends RecurringWorkerSchedule {
  _RecurringWorkerScheduleImpl({
    int? id,
    required String workerKey,
    required DateTime nextRunAt,
    String? runToken,
    int? leaderFencingToken,
    DateTime? runLeaseExpiresAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workerKey: workerKey,
         nextRunAt: nextRunAt,
         runToken: runToken,
         leaderFencingToken: leaderFencingToken,
         runLeaseExpiresAt: runLeaseExpiresAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RecurringWorkerSchedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RecurringWorkerSchedule copyWith({
    Object? id = _Undefined,
    String? workerKey,
    DateTime? nextRunAt,
    Object? runToken = _Undefined,
    Object? leaderFencingToken = _Undefined,
    Object? runLeaseExpiresAt = _Undefined,
    DateTime? updatedAt,
  }) {
    return RecurringWorkerSchedule(
      id: id is int? ? id : this.id,
      workerKey: workerKey ?? this.workerKey,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      runToken: runToken is String? ? runToken : this.runToken,
      leaderFencingToken: leaderFencingToken is int?
          ? leaderFencingToken
          : this.leaderFencingToken,
      runLeaseExpiresAt: runLeaseExpiresAt is DateTime?
          ? runLeaseExpiresAt
          : this.runLeaseExpiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
