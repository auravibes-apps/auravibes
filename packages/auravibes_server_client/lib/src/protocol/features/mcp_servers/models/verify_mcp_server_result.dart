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
import 'package:auravibes_server_client/src/protocol/protocol.dart'
    as _isctvzjc;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import '../../../features/mcp_servers/models/discover_mcp_server_result.dart'
    as _iihu1tr0;

abstract class VerifyMcpServerResult
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  VerifyMcpServerResult._({
    required this.discovery,
    required this.verificationReceipt,
    required this.expiresAt,
  });

  factory VerifyMcpServerResult({
    required _iihu1tr0.DiscoverMcpServerResult discovery,
    required String verificationReceipt,
    required DateTime expiresAt,
  }) = _VerifyMcpServerResultImpl;

  factory VerifyMcpServerResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerifyMcpServerResult(
      discovery: _isctvzjc.Protocol()
          .deserialize<_iihu1tr0.DiscoverMcpServerResult>(
            jsonSerialization['discovery'],
          ),
      verificationReceipt: jsonSerialization['verificationReceipt'] as String,
      expiresAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  _iihu1tr0.DiscoverMcpServerResult discovery;

  String verificationReceipt;

  DateTime expiresAt;

  /// Returns a shallow copy of this [VerifyMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  VerifyMcpServerResult copyWith({
    _iihu1tr0.DiscoverMcpServerResult? discovery,
    String? verificationReceipt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerifyMcpServerResult',
      'discovery': discovery.toJson(),
      'verificationReceipt': verificationReceipt,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'VerifyMcpServerResult',
      'discovery': discovery.toJsonForProtocol(),
      'verificationReceipt': verificationReceipt,
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _VerifyMcpServerResultImpl extends VerifyMcpServerResult {
  _VerifyMcpServerResultImpl({
    required _iihu1tr0.DiscoverMcpServerResult discovery,
    required String verificationReceipt,
    required DateTime expiresAt,
  }) : super._(
         discovery: discovery,
         verificationReceipt: verificationReceipt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [VerifyMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  VerifyMcpServerResult copyWith({
    _iihu1tr0.DiscoverMcpServerResult? discovery,
    String? verificationReceipt,
    DateTime? expiresAt,
  }) {
    return VerifyMcpServerResult(
      discovery: discovery ?? this.discovery.copyWith(),
      verificationReceipt: verificationReceipt ?? this.verificationReceipt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
