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

abstract class CreateModelConnectionRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CreateModelConnectionRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.connectionId,
    required this.name,
    required this.providerId,
    this.url,
  });

  factory CreateModelConnectionRequest({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required String name,
    required String providerId,
    String? url,
  }) = _CreateModelConnectionRequestImpl;

  factory CreateModelConnectionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateModelConnectionRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      connectionId: jsonSerialization['connectionId'] as String,
      name: jsonSerialization['name'] as String,
      providerId: jsonSerialization['providerId'] as String,
      url: jsonSerialization['url'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String connectionId;

  String name;

  String providerId;

  String? url;

  /// Returns a shallow copy of this [CreateModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreateModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    String? name,
    String? providerId,
    String? url,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'name': name,
      'providerId': providerId,
      if (url != null) 'url': url,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateModelConnectionRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'connectionId': connectionId,
      'name': name,
      'providerId': providerId,
      if (url != null) 'url': url,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CreateModelConnectionRequestImpl extends CreateModelConnectionRequest {
  _CreateModelConnectionRequestImpl({
    required int workspaceId,
    required String requestId,
    required String connectionId,
    required String name,
    required String providerId,
    String? url,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         connectionId: connectionId,
         name: name,
         providerId: providerId,
         url: url,
       );

  /// Returns a shallow copy of this [CreateModelConnectionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreateModelConnectionRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? connectionId,
    String? name,
    String? providerId,
    Object? url = _Undefined,
  }) {
    return CreateModelConnectionRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      connectionId: connectionId ?? this.connectionId,
      name: name ?? this.name,
      providerId: providerId ?? this.providerId,
      url: url is String? ? url : this.url,
    );
  }
}
