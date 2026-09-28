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

abstract class UpdateModelConnectionRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  UpdateModelConnectionRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.connectionId,
    required this.expectedRevision,
    required this.name,
    this.url,
    this.verificationReceipt,
    this.hasSecretOverride,
  });

  factory UpdateModelConnectionRequest({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required int expectedRevision,
    required String name,
    String? url,
    String? verificationReceipt,
    bool? hasSecretOverride,
  }) = _UpdateModelConnectionRequestImpl;

  factory UpdateModelConnectionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return UpdateModelConnectionRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      connectionId: jsonSerialization['connectionId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      name: jsonSerialization['name'] as String,
      url: jsonSerialization['url'] as String?,
      verificationReceipt: jsonSerialization['verificationReceipt'] as String?,
      hasSecretOverride: jsonSerialization['hasSecretOverride'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['hasSecretOverride'],
            ),
    );
  }

  int workspaceId;

  String requestId;

  String connectionId;

  int expectedRevision;

  String name;

  String? url;

  String? verificationReceipt;

  bool? hasSecretOverride;

  /// Returns a shallow copy of this [UpdateModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  UpdateModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
    String? name,
    String? url,
    String? verificationReceipt,
    bool? hasSecretOverride,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UpdateModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'expectedRevision': expectedRevision,
      'name': name,
      if (url != null) 'url': url,
      if (verificationReceipt != null)
        'verificationReceipt': verificationReceipt,
      if (hasSecretOverride != null) 'hasSecretOverride': hasSecretOverride,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UpdateModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'expectedRevision': expectedRevision,
      'name': name,
      if (url != null) 'url': url,
      if (verificationReceipt != null)
        'verificationReceipt': verificationReceipt,
      if (hasSecretOverride != null) 'hasSecretOverride': hasSecretOverride,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UpdateModelConnectionRequestImpl extends UpdateModelConnectionRequest {
  _UpdateModelConnectionRequestImpl({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required int expectedRevision,
    required String name,
    String? url,
    String? verificationReceipt,
    bool? hasSecretOverride,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         connectionId: connectionId,
         expectedRevision: expectedRevision,
         name: name,
         url: url,
         verificationReceipt: verificationReceipt,
         hasSecretOverride: hasSecretOverride,
       );

  /// Returns a shallow copy of this [UpdateModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  UpdateModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    int? expectedRevision,
    String? name,
    Object? url = _Undefined,
    Object? verificationReceipt = _Undefined,
    Object? hasSecretOverride = _Undefined,
  }) {
    return UpdateModelConnectionRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      connectionId: connectionId ?? this.connectionId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      name: name ?? this.name,
      url: url is String? ? url : this.url,
      verificationReceipt: verificationReceipt is String?
          ? verificationReceipt
          : this.verificationReceipt,
      hasSecretOverride: hasSecretOverride is bool?
          ? hasSecretOverride
          : this.hasSecretOverride,
    );
  }
}
