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
import '../../../features/mcp_servers/models/mcp_server_health.dart' as _i2;
import '../../../features/mcp_servers/models/discovered_mcp_tool.dart' as _i3;
import 'package:auravibes_server/src/generated/protocol.dart' as _i4;

abstract class DiscoverMcpServerResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DiscoverMcpServerResult._({
    required this.health,
    this.serverName,
    this.serverVersion,
    this.protocolVersion,
    required this.tools,
    this.errorCode,
  });

  factory DiscoverMcpServerResult({
    required _i2.McpServerHealth health,
    String? serverName,
    String? serverVersion,
    String? protocolVersion,
    required List<_i3.DiscoveredMcpTool> tools,
    String? errorCode,
  }) = _DiscoverMcpServerResultImpl;

  factory DiscoverMcpServerResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DiscoverMcpServerResult(
      health: _i2.McpServerHealth.fromJson(
        (jsonSerialization['health'] as String),
      ),
      serverName: jsonSerialization['serverName'] as String?,
      serverVersion: jsonSerialization['serverVersion'] as String?,
      protocolVersion: jsonSerialization['protocolVersion'] as String?,
      tools: _i4.Protocol().deserialize<List<_i3.DiscoveredMcpTool>>(
        jsonSerialization['tools'],
      ),
      errorCode: jsonSerialization['errorCode'] as String?,
    );
  }

  _i2.McpServerHealth health;

  String? serverName;

  String? serverVersion;

  String? protocolVersion;

  List<_i3.DiscoveredMcpTool> tools;

  String? errorCode;

  /// Returns a shallow copy of this [DiscoverMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DiscoverMcpServerResult copyWith({
    _i2.McpServerHealth? health,
    String? serverName,
    String? serverVersion,
    String? protocolVersion,
    List<_i3.DiscoveredMcpTool>? tools,
    String? errorCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DiscoverMcpServerResult',
      'health': health.toJson(),
      if (serverName != null) 'serverName': serverName,
      if (serverVersion != null) 'serverVersion': serverVersion,
      if (protocolVersion != null) 'protocolVersion': protocolVersion,
      'tools': tools.toJson(valueToJson: (v) => v.toJson()),
      if (errorCode != null) 'errorCode': errorCode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DiscoverMcpServerResult',
      'health': health.toJson(),
      if (serverName != null) 'serverName': serverName,
      if (serverVersion != null) 'serverVersion': serverVersion,
      if (protocolVersion != null) 'protocolVersion': protocolVersion,
      'tools': tools.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (errorCode != null) 'errorCode': errorCode,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DiscoverMcpServerResultImpl extends DiscoverMcpServerResult {
  _DiscoverMcpServerResultImpl({
    required _i2.McpServerHealth health,
    String? serverName,
    String? serverVersion,
    String? protocolVersion,
    required List<_i3.DiscoveredMcpTool> tools,
    String? errorCode,
  }) : super._(
         health: health,
         serverName: serverName,
         serverVersion: serverVersion,
         protocolVersion: protocolVersion,
         tools: tools,
         errorCode: errorCode,
       );

  /// Returns a shallow copy of this [DiscoverMcpServerResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DiscoverMcpServerResult copyWith({
    _i2.McpServerHealth? health,
    Object? serverName = _Undefined,
    Object? serverVersion = _Undefined,
    Object? protocolVersion = _Undefined,
    List<_i3.DiscoveredMcpTool>? tools,
    Object? errorCode = _Undefined,
  }) {
    return DiscoverMcpServerResult(
      health: health ?? this.health,
      serverName: serverName is String? ? serverName : this.serverName,
      serverVersion: serverVersion is String?
          ? serverVersion
          : this.serverVersion,
      protocolVersion: protocolVersion is String?
          ? protocolVersion
          : this.protocolVersion,
      tools: tools ?? this.tools.map((e0) => e0.copyWith()).toList(),
      errorCode: errorCode is String? ? errorCode : this.errorCode,
    );
  }
}
