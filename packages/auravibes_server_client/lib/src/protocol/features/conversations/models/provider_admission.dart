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

abstract class ProviderAdmission._({
  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  var int? id,
  required var int jobId,
  required var int workspaceId,
  required var String providerId,
  required var String leaseToken,
  required var DateTime createdAt,
}) implements _i1.SerializableModel {
  factory({
    int? id,
    required int jobId,
    required int workspaceId,
    required String providerId,
    required String leaseToken,
    required DateTime createdAt,
  }) = _ProviderAdmissionImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return ProviderAdmission(
      id: jsonSerialization['id'] as int?,
      jobId: jsonSerialization['jobId'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      providerId: jsonSerialization['providerId'] as String,
      leaseToken: jsonSerialization['leaseToken'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Returns a shallow copy of this [ProviderAdmission]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProviderAdmission copyWith({
    int? id,
    int? jobId,
    int? workspaceId,
    String? providerId,
    String? leaseToken,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProviderAdmission',
      if (id != null) 'id': id,
      'jobId': jobId,
      'workspaceId': workspaceId,
      'providerId': providerId,
      'leaseToken': leaseToken,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ProviderAdmissionImpl({
  int? id,
  required int jobId,
  required int workspaceId,
  required String providerId,
  required String leaseToken,
  required DateTime createdAt,
}) extends ProviderAdmission {
  this
    : super._(
        id: id,
        jobId: jobId,
        workspaceId: workspaceId,
        providerId: providerId,
        leaseToken: leaseToken,
        createdAt: createdAt,
      );

  /// Returns a shallow copy of this [ProviderAdmission]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProviderAdmission copyWith({
    Object? id = _Undefined,
    int? jobId,
    int? workspaceId,
    String? providerId,
    String? leaseToken,
    DateTime? createdAt,
  }) {
    return ProviderAdmission(
      id: id is int? ? id : this.id,
      jobId: jobId ?? this.jobId,
      workspaceId: workspaceId ?? this.workspaceId,
      providerId: providerId ?? this.providerId,
      leaseToken: leaseToken ?? this.leaseToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
