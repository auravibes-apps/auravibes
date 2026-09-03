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
import '../../../features/mcp_servers/models/discover_mcp_server_result.dart'
    as _i2;
import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i3;

abstract class CreateMcpServerResult implements _i1.SerializableModel {
  CreateMcpServerResult._({
    required this.mcpServerId,
    required this.createdAt,
    required this.discovery,
  });

  factory CreateMcpServerResult({
    required String mcpServerId,
    required DateTime createdAt,
    required _i2.DiscoverMcpServerResult discovery,
  }) = _CreateMcpServerResultImpl;

  factory CreateMcpServerResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateMcpServerResult(
      mcpServerId: jsonSerialization['mcpServerId'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      discovery: _i3.Protocol().deserialize<_i2.DiscoverMcpServerResult>(
        jsonSerialization['discovery'],
      ),
    );
  }

  String mcpServerId;

  DateTime createdAt;

  _i2.DiscoverMcpServerResult discovery;

  /// Returns a shallow copy of this [CreateMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreateMcpServerResult copyWith({
    String? mcpServerId,
    DateTime? createdAt,
    _i2.DiscoverMcpServerResult? discovery,
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
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CreateMcpServerResultImpl extends CreateMcpServerResult {
  _CreateMcpServerResultImpl({
    required String mcpServerId,
    required DateTime createdAt,
    required _i2.DiscoverMcpServerResult discovery,
  }) : super._(
         mcpServerId: mcpServerId,
         createdAt: createdAt,
         discovery: discovery,
       );

  /// Returns a shallow copy of this [CreateMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreateMcpServerResult copyWith({
    String? mcpServerId,
    DateTime? createdAt,
    _i2.DiscoverMcpServerResult? discovery,
  }) {
    return CreateMcpServerResult(
      mcpServerId: mcpServerId ?? this.mcpServerId,
      createdAt: createdAt ?? this.createdAt,
      discovery: discovery ?? this.discovery.copyWith(),
    );
  }
}
