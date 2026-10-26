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

abstract class ObjectDeletion
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ObjectDeletion._({
    this.id,
    required this.workspaceId,
    required this.objectId,
    required this.objectKey,
    required this.requestId,
    required this.expectedRevision,
    required this.requestedAt,
    this.completedAt,
    int? cleanupGeneration,
    this.uploadCleanupVerifiedAt,
    this.uploadCleanupVerifiedGeneration,
    this.uploadCleanupVerifiedExpiresAt,
    required this.attempts,
    required this.availableAt,
    this.lastError,
  }) : cleanupGeneration = cleanupGeneration ?? 0;

  factory ObjectDeletion({
    int? id,
    required int workspaceId,
    required int objectId,
    required String objectKey,
    required String requestId,
    required int expectedRevision,
    required DateTime requestedAt,
    DateTime? completedAt,
    int? cleanupGeneration,
    DateTime? uploadCleanupVerifiedAt,
    int? uploadCleanupVerifiedGeneration,
    DateTime? uploadCleanupVerifiedExpiresAt,
    required int attempts,
    required DateTime availableAt,
    String? lastError,
  }) = _ObjectDeletionImpl;

  factory ObjectDeletion.fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectDeletion(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
      objectKey: jsonSerialization['objectKey'] as String,
      requestId: jsonSerialization['requestId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      requestedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['requestedAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      cleanupGeneration: jsonSerialization['cleanupGeneration'] as int?,
      uploadCleanupVerifiedAt:
          jsonSerialization['uploadCleanupVerifiedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['uploadCleanupVerifiedAt'],
            ),
      uploadCleanupVerifiedGeneration:
          jsonSerialization['uploadCleanupVerifiedGeneration'] as int?,
      uploadCleanupVerifiedExpiresAt:
          jsonSerialization['uploadCleanupVerifiedExpiresAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['uploadCleanupVerifiedExpiresAt'],
            ),
      attempts: jsonSerialization['attempts'] as int,
      availableAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['availableAt'],
      ),
      lastError: jsonSerialization['lastError'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  int objectId;

  String objectKey;

  String requestId;

  int expectedRevision;

  DateTime requestedAt;

  DateTime? completedAt;

  int cleanupGeneration;

  DateTime? uploadCleanupVerifiedAt;

  int? uploadCleanupVerifiedGeneration;

  DateTime? uploadCleanupVerifiedExpiresAt;

  int attempts;

  DateTime availableAt;

  String? lastError;

  /// Returns a shallow copy of this [ObjectDeletion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ObjectDeletion copyWith({
    int? id,
    int? workspaceId,
    int? objectId,
    String? objectKey,
    String? requestId,
    int? expectedRevision,
    DateTime? requestedAt,
    DateTime? completedAt,
    int? cleanupGeneration,
    DateTime? uploadCleanupVerifiedAt,
    int? uploadCleanupVerifiedGeneration,
    DateTime? uploadCleanupVerifiedExpiresAt,
    int? attempts,
    DateTime? availableAt,
    String? lastError,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectDeletion',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'objectKey': objectKey,
      'requestId': requestId,
      'expectedRevision': expectedRevision,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'cleanupGeneration': cleanupGeneration,
      if (uploadCleanupVerifiedAt != null)
        'uploadCleanupVerifiedAt': uploadCleanupVerifiedAt?.toJson(),
      if (uploadCleanupVerifiedGeneration != null)
        'uploadCleanupVerifiedGeneration': uploadCleanupVerifiedGeneration,
      if (uploadCleanupVerifiedExpiresAt != null)
        'uploadCleanupVerifiedExpiresAt': uploadCleanupVerifiedExpiresAt
            ?.toJson(),
      'attempts': attempts,
      'availableAt': availableAt.toJson(),
      if (lastError != null) 'lastError': lastError,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ObjectDeletion',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'objectId': objectId,
      'objectKey': objectKey,
      'requestId': requestId,
      'expectedRevision': expectedRevision,
      'requestedAt': requestedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'cleanupGeneration': cleanupGeneration,
      if (uploadCleanupVerifiedAt != null)
        'uploadCleanupVerifiedAt': uploadCleanupVerifiedAt?.toJson(),
      if (uploadCleanupVerifiedGeneration != null)
        'uploadCleanupVerifiedGeneration': uploadCleanupVerifiedGeneration,
      if (uploadCleanupVerifiedExpiresAt != null)
        'uploadCleanupVerifiedExpiresAt': uploadCleanupVerifiedExpiresAt
            ?.toJson(),
      'attempts': attempts,
      'availableAt': availableAt.toJson(),
      if (lastError != null) 'lastError': lastError,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ObjectDeletionImpl extends ObjectDeletion {
  _ObjectDeletionImpl({
    int? id,
    required int workspaceId,
    required int objectId,
    required String objectKey,
    required String requestId,
    required int expectedRevision,
    required DateTime requestedAt,
    DateTime? completedAt,
    int? cleanupGeneration,
    DateTime? uploadCleanupVerifiedAt,
    int? uploadCleanupVerifiedGeneration,
    DateTime? uploadCleanupVerifiedExpiresAt,
    required int attempts,
    required DateTime availableAt,
    String? lastError,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         objectId: objectId,
         objectKey: objectKey,
         requestId: requestId,
         expectedRevision: expectedRevision,
         requestedAt: requestedAt,
         completedAt: completedAt,
         cleanupGeneration: cleanupGeneration,
         uploadCleanupVerifiedAt: uploadCleanupVerifiedAt,
         uploadCleanupVerifiedGeneration: uploadCleanupVerifiedGeneration,
         uploadCleanupVerifiedExpiresAt: uploadCleanupVerifiedExpiresAt,
         attempts: attempts,
         availableAt: availableAt,
         lastError: lastError,
       );

  /// Returns a shallow copy of this [ObjectDeletion]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ObjectDeletion copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? objectId,
    String? objectKey,
    String? requestId,
    int? expectedRevision,
    DateTime? requestedAt,
    Object? completedAt = _Undefined,
    int? cleanupGeneration,
    Object? uploadCleanupVerifiedAt = _Undefined,
    Object? uploadCleanupVerifiedGeneration = _Undefined,
    Object? uploadCleanupVerifiedExpiresAt = _Undefined,
    int? attempts,
    DateTime? availableAt,
    Object? lastError = _Undefined,
  }) {
    return ObjectDeletion(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
      objectKey: objectKey ?? this.objectKey,
      requestId: requestId ?? this.requestId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      cleanupGeneration: cleanupGeneration ?? this.cleanupGeneration,
      uploadCleanupVerifiedAt: uploadCleanupVerifiedAt is DateTime?
          ? uploadCleanupVerifiedAt
          : this.uploadCleanupVerifiedAt,
      uploadCleanupVerifiedGeneration: uploadCleanupVerifiedGeneration is int?
          ? uploadCleanupVerifiedGeneration
          : this.uploadCleanupVerifiedGeneration,
      uploadCleanupVerifiedExpiresAt:
          uploadCleanupVerifiedExpiresAt is DateTime?
          ? uploadCleanupVerifiedExpiresAt
          : this.uploadCleanupVerifiedExpiresAt,
      attempts: attempts ?? this.attempts,
      availableAt: availableAt ?? this.availableAt,
      lastError: lastError is String? ? lastError : this.lastError,
    );
  }
}
