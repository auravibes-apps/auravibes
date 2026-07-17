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

abstract class BeginUploadRequest implements _i1.SerializableModel {
  BeginUploadRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.purpose,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    required this.checksumSha256,
  });

  factory BeginUploadRequest({
    required int workspaceId,
    required String requestId,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
  }) = _BeginUploadRequestImpl;

  factory BeginUploadRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return BeginUploadRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      purpose: jsonSerialization['purpose'] as String,
      displayName: jsonSerialization['displayName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      checksumSha256: jsonSerialization['checksumSha256'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String purpose;

  String displayName;

  String mimeType;

  int sizeBytes;

  String checksumSha256;

  /// Returns a shallow copy of this [BeginUploadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BeginUploadRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? purpose,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BeginUploadRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'purpose': purpose,
      'displayName': displayName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'checksumSha256': checksumSha256,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BeginUploadRequestImpl extends BeginUploadRequest {
  _BeginUploadRequestImpl({
    required int workspaceId,
    required String requestId,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         purpose: purpose,
         displayName: displayName,
         mimeType: mimeType,
         sizeBytes: sizeBytes,
         checksumSha256: checksumSha256,
       );

  /// Returns a shallow copy of this [BeginUploadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BeginUploadRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? purpose,
    String? displayName,
    String? mimeType,
    int? sizeBytes,
    String? checksumSha256,
  }) {
    return BeginUploadRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      purpose: purpose ?? this.purpose,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
    );
  }
}
