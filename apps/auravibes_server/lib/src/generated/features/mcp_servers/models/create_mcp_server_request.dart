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

abstract class CreateMcpServerRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CreateMcpServerRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.name,
    required this.url,
    required this.transport,
    required this.useHttp2,
    this.description,
    this.bearerToken,
  });

  factory CreateMcpServerRequest({
    required int workspaceId,
    required String requestId,
    required String name,
    required String url,
    required String transport,
    required bool useHttp2,
    String? description,
    String? bearerToken,
  }) = _CreateMcpServerRequestImpl;

  factory CreateMcpServerRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateMcpServerRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      name: jsonSerialization['name'] as String,
      url: jsonSerialization['url'] as String,
      transport: jsonSerialization['transport'] as String,
      useHttp2: _i1.BoolJsonExtension.fromJson(jsonSerialization['useHttp2']),
      description: jsonSerialization['description'] as String?,
      bearerToken: jsonSerialization['bearerToken'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String name;

  String url;

  String transport;

  bool useHttp2;

  String? description;

  String? bearerToken;

  /// Returns a shallow copy of this [CreateMcpServerRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreateMcpServerRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? name,
    String? url,
    String? transport,
    bool? useHttp2,
    String? description,
    String? bearerToken,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateMcpServerRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'name': name,
      'url': url,
      'transport': transport,
      'useHttp2': useHttp2,
      if (description != null) 'description': description,
      if (bearerToken != null) 'bearerToken': bearerToken,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateMcpServerRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'name': name,
      'url': url,
      'transport': transport,
      'useHttp2': useHttp2,
      if (description != null) 'description': description,
      if (bearerToken != null) 'bearerToken': bearerToken,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CreateMcpServerRequestImpl extends CreateMcpServerRequest {
  _CreateMcpServerRequestImpl({
    required int workspaceId,
    required String requestId,
    required String name,
    required String url,
    required String transport,
    required bool useHttp2,
    String? description,
    String? bearerToken,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         name: name,
         url: url,
         transport: transport,
         useHttp2: useHttp2,
         description: description,
         bearerToken: bearerToken,
       );

  /// Returns a shallow copy of this [CreateMcpServerRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreateMcpServerRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? name,
    String? url,
    String? transport,
    bool? useHttp2,
    Object? description = _Undefined,
    Object? bearerToken = _Undefined,
  }) {
    return CreateMcpServerRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      name: name ?? this.name,
      url: url ?? this.url,
      transport: transport ?? this.transport,
      useHttp2: useHttp2 ?? this.useHttp2,
      description: description is String? ? description : this.description,
      bearerToken: bearerToken is String? ? bearerToken : this.bearerToken,
    );
  }
}
