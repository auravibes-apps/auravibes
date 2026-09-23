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
import 'package:serverpod/serverpod.dart' as _is;

abstract class VerifyModelConnectionRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  VerifyModelConnectionRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.connectionId,
    required this.expectedRevision,
    this.url,
  });

  factory VerifyModelConnectionRequest({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required int expectedRevision,
    String? url,
  }) = _VerifyModelConnectionRequestImpl;

  factory VerifyModelConnectionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerifyModelConnectionRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      connectionId: jsonSerialization['connectionId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      url: jsonSerialization['url'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String connectionId;

  int expectedRevision;

  String? url;

  /// Returns a shallow copy of this [VerifyModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerifyModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
    String? url,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerifyModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'expectedRevision': expectedRevision,
      if (url != null) 'url': url,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerifyModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'expectedRevision': expectedRevision,
      if (url != null) 'url': url,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerifyModelConnectionRequestImpl extends VerifyModelConnectionRequest {
  _VerifyModelConnectionRequestImpl({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required int expectedRevision,
    String? url,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         connectionId: connectionId,
         expectedRevision: expectedRevision,
         url: url,
       );

  /// Returns a shallow copy of this [VerifyModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerifyModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
    Object? url = _Undefined,
  }) {
    return VerifyModelConnectionRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      connectionId: connectionId ?? this.connectionId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      url: url is String? ? url : this.url,
    );
  }
}
