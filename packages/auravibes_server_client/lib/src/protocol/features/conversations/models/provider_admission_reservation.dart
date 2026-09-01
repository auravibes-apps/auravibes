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

abstract class ProviderAdmissionReservation._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int jobId,
  required var int workspaceId,
  required var String providerId,
  required var String leaseToken,
  required var DateTime expiresAt,
  required var DateTime createdAt,
  required var DateTime updatedAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int jobId,
    required int workspaceId,
    required String providerId,
    required String leaseToken,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProviderAdmissionReservationImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProviderAdmissionReservation(
      id: jsonSerialization['id'] as int?,
      jobId: jsonSerialization['jobId'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      providerId: jsonSerialization['providerId'] as String,
      leaseToken: jsonSerialization['leaseToken'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ProviderAdmissionReservation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProviderAdmissionReservation copyWith({
    int? id,
    int? jobId,
    int? workspaceId,
    String? providerId,
    String? leaseToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProviderAdmissionReservation',
      if (id != null) 'id': id,
      'jobId': jobId,
      'workspaceId': workspaceId,
      'providerId': providerId,
      'leaseToken': leaseToken,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ProviderAdmissionReservationImpl({
  int? id,
  required int jobId,
  required int workspaceId,
  required String providerId,
  required String leaseToken,
  required DateTime expiresAt,
  required DateTime createdAt,
  required DateTime updatedAt,
}) extends ProviderAdmissionReservation {
  this
    : super._(
        id: id,
        jobId: jobId,
        workspaceId: workspaceId,
        providerId: providerId,
        leaseToken: leaseToken,
        expiresAt: expiresAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Returns a shallow copy of this [ProviderAdmissionReservation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProviderAdmissionReservation copyWith({
    Object? id = _Undefined,
    int? jobId,
    int? workspaceId,
    String? providerId,
    String? leaseToken,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderAdmissionReservation(
      id: id is int? ? id : this.id,
      jobId: jobId ?? this.jobId,
      workspaceId: workspaceId ?? this.workspaceId,
      providerId: providerId ?? this.providerId,
      leaseToken: leaseToken ?? this.leaseToken,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
