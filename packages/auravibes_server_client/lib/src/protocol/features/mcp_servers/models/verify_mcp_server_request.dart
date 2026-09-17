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

abstract class VerifyMcpServerRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VerifyMcpServerRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.url,
    required this.transport,
    required this.useHttp2,
    this.bearerToken,
  });

  factory VerifyMcpServerRequest({
    required int workspaceId,
    required String requestId,
    required String url,
    required String transport,
    required bool useHttp2,
    String? bearerToken,
  }) = _VerifyMcpServerRequestImpl;

  factory VerifyMcpServerRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerifyMcpServerRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      url: jsonSerialization['url'] as String,
      transport: jsonSerialization['transport'] as String,
      useHttp2: _isc.BoolJsonExtension.fromJson(jsonSerialization['useHttp2']),
      bearerToken: jsonSerialization['bearerToken'] as String?,
    );
  }

  int workspaceId;

  String requestId;

  String url;

  String transport;

  bool useHttp2;

  String? bearerToken;

  /// Returns a shallow copy of this [VerifyMcpServerRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VerifyMcpServerRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? url,
    String? transport,
    bool? useHttp2,
    String? bearerToken,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerifyMcpServerRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'url': url,
      'transport': transport,
      'useHttp2': useHttp2,
      if (bearerToken != null) 'bearerToken': bearerToken,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerifyMcpServerRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'url': url,
      'transport': transport,
      'useHttp2': useHttp2,
      if (bearerToken != null) 'bearerToken': bearerToken,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerifyMcpServerRequestImpl extends VerifyMcpServerRequest {
  _VerifyMcpServerRequestImpl({
    required int workspaceId,
    required String requestId,
    required String url,
    required String transport,
    required bool useHttp2,
    String? bearerToken,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         url: url,
         transport: transport,
         useHttp2: useHttp2,
         bearerToken: bearerToken,
       );

  /// Returns a shallow copy of this [VerifyMcpServerRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VerifyMcpServerRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? url,
    String? transport,
    bool? useHttp2,
    Object? bearerToken = _Undefined,
  }) {
    return VerifyMcpServerRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      url: url ?? this.url,
      transport: transport ?? this.transport,
      useHttp2: useHttp2 ?? this.useHttp2,
      bearerToken: bearerToken is String? ? bearerToken : this.bearerToken,
    );
  }
}
