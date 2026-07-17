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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class GetDownloadRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GetDownloadRequest._({
    required this.workspaceId,
    required this.objectId,
  });

  factory GetDownloadRequest({
    required int workspaceId,
    required int objectId,
  }) = _GetDownloadRequestImpl;

  factory GetDownloadRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return GetDownloadRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      objectId: jsonSerialization['objectId'] as int,
    );
  }

  int workspaceId;

  int objectId;

  /// Returns a shallow copy of this [GetDownloadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GetDownloadRequest copyWith({
    int? workspaceId,
    int? objectId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetDownloadRequest',
      'workspaceId': workspaceId,
      'objectId': objectId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GetDownloadRequest',
      'workspaceId': workspaceId,
      'objectId': objectId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GetDownloadRequestImpl extends GetDownloadRequest {
  _GetDownloadRequestImpl({
    required int workspaceId,
    required int objectId,
  }) : super._(
         workspaceId: workspaceId,
         objectId: objectId,
       );

  /// Returns a shallow copy of this [GetDownloadRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GetDownloadRequest copyWith({
    int? workspaceId,
    int? objectId,
  }) {
    return GetDownloadRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      objectId: objectId ?? this.objectId,
    );
  }
}
