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

abstract class ProviderAdmissionReservation implements _i1.SerializableModel {
  ProviderAdmissionReservation._({
    this.id,
    required this.jobId,
    required this.workspaceId,
    required this.providerId,
    required this.leaseToken,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderAdmissionReservation({
    int? id,
    required int jobId,
    required int workspaceId,
    required String providerId,
    required String leaseToken,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProviderAdmissionReservationImpl;

  factory ProviderAdmissionReservation.fromJson(
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int jobId;

  int workspaceId;

  String providerId;

  String leaseToken;

  DateTime expiresAt;

  DateTime createdAt;

  DateTime updatedAt;

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

class _Undefined {}

class _ProviderAdmissionReservationImpl extends ProviderAdmissionReservation {
  _ProviderAdmissionReservationImpl({
    int? id,
    required int jobId,
    required int workspaceId,
    required String providerId,
    required String leaseToken,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
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
