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
import 'package:auravibes_server/src/generated/protocol.dart' as _if5qez1k;
import 'package:serverpod/serverpod.dart' as _is;

import '../../../features/mcp_servers/models/discover_mcp_server_result.dart'
    as _iihu1tr0;

abstract class CreateMcpServerResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CreateMcpServerResult._({
    required this.mcpServerId,
    required this.createdAt,
    required this.discovery,
  });

  factory CreateMcpServerResult({
    required String mcpServerId,
    required DateTime createdAt,
    required _iihu1tr0.DiscoverMcpServerResult discovery,
  }) = _CreateMcpServerResultImpl;

  factory CreateMcpServerResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateMcpServerResult(
      mcpServerId: jsonSerialization['mcpServerId'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      discovery: _if5qez1k.Protocol()
          .deserialize<_iihu1tr0.DiscoverMcpServerResult>(
            jsonSerialization['discovery'],
          ),
    );
  }

  String mcpServerId;

  DateTime createdAt;

  _iihu1tr0.DiscoverMcpServerResult discovery;

  /// Returns a shallow copy of this [CreateMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CreateMcpServerResult copyWith({
    String? mcpServerId,
    DateTime? createdAt,
    _iihu1tr0.DiscoverMcpServerResult? discovery,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateMcpServerResult',
      'mcpServerId': mcpServerId,
      'createdAt': createdAt.toJson(),
      'discovery': discovery.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateMcpServerResult',
      'mcpServerId': mcpServerId,
      'createdAt': createdAt.toJson(),
      'discovery': discovery.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _CreateMcpServerResultImpl extends CreateMcpServerResult {
  _CreateMcpServerResultImpl({
    required String mcpServerId,
    required DateTime createdAt,
    required _iihu1tr0.DiscoverMcpServerResult discovery,
  }) : super._(
         mcpServerId: mcpServerId,
         createdAt: createdAt,
         discovery: discovery,
       );

  /// Returns a shallow copy of this [CreateMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CreateMcpServerResult copyWith({
    String? mcpServerId,
    DateTime? createdAt,
    _iihu1tr0.DiscoverMcpServerResult? discovery,
  }) {
    return CreateMcpServerResult(
      mcpServerId: mcpServerId ?? this.mcpServerId,
      createdAt: createdAt ?? this.createdAt,
      discovery: discovery ?? this.discovery.copyWith(),
    );
  }
}
