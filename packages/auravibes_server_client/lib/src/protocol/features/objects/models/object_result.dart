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

abstract class ObjectResult._({
  required var int objectId,
  required var int workspaceId,
  required var String displayName,
  required var String mimeType,
  required var int sizeBytes,
  required var String checksumSha256,
  required var int revision,
}) implements _i1.SerializableModel {
  factory({
    required int objectId,
    required int workspaceId,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required int revision,
  }) = _ObjectResultImpl;

  factory fromJson(Map<String, dynamic> jsonSerialization) {
    return ObjectResult(
      objectId: jsonSerialization['objectId'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      displayName: jsonSerialization['displayName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      checksumSha256: jsonSerialization['checksumSha256'] as String,
      revision: jsonSerialization['revision'] as int,
    );
  }

  /// Returns a shallow copy of this [ObjectResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ObjectResult copyWith({
    int? objectId,
    int? workspaceId,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
    int? revision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ObjectResult',
      'objectId': objectId,
      'workspaceId': workspaceId,
      'displayName': displayName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'checksumSha256': checksumSha256,
      'revision': revision,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ObjectResultImpl({
  required int objectId,
  required int workspaceId,
  required String displayName,
  required String mimeType,
  required int sizeBytes,
  required String checksumSha256,
  required int revision,
}) extends ObjectResult {
  this
    : super._(
        objectId: objectId,
        workspaceId: workspaceId,
        displayName: displayName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        checksumSha256: checksumSha256,
        revision: revision,
      );

  /// Returns a shallow copy of this [ObjectResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ObjectResult copyWith({
    int? objectId,
    int? workspaceId,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
    int? revision,
  }) {
    return ObjectResult(
      objectId: objectId ?? this.objectId,
      workspaceId: workspaceId ?? this.workspaceId,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      revision: revision ?? this.revision,
    );
  }
}
