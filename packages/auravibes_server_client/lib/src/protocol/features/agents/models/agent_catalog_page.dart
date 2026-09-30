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

import '../../../features/agents/models/agent_catalog_item.dart' as _ij3q200n;

abstract class AgentCatalogPage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AgentCatalogPage._({
    required this.agents,
    this.nextCursor,
  });

  factory AgentCatalogPage({
    required List<_ij3q200n.AgentCatalogItem> agents,
    String? nextCursor,
  }) = _AgentCatalogPageImpl;

  factory AgentCatalogPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentCatalogPage(
      agents: _isctvzjc.Protocol()
          .deserialize<List<_ij3q200n.AgentCatalogItem>>(
            jsonSerialization['agents'],
          ),
      nextCursor: jsonSerialization['nextCursor'] as String?,
    );
  }

  List<_ij3q200n.AgentCatalogItem> agents;

  String? nextCursor;

  /// Returns a shallow copy of this [AgentCatalogPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AgentCatalogPage copyWith({
    List<_ij3q200n.AgentCatalogItem>? agents,
    String? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentCatalogPage',
      'agents': agents.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AgentCatalogPage',
      'agents': agents.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (nextCursor != null) 'nextCursor': nextCursor,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentCatalogPageImpl extends AgentCatalogPage {
  _AgentCatalogPageImpl({
    required List<_ij3q200n.AgentCatalogItem> agents,
    String? nextCursor,
  }) : super._(
         agents: agents,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [AgentCatalogPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AgentCatalogPage copyWith({
    List<_ij3q200n.AgentCatalogItem>? agents,
    Object? nextCursor = _Undefined,
  }) {
    return AgentCatalogPage(
      agents: agents ?? this.agents.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is String? ? nextCursor : this.nextCursor,
    );
  }
}
