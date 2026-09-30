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

import '../../../features/agents/models/agent_catalog_status.dart' as _iu7mkbq9;
import '../../../features/agents/models/agent_catalog_type.dart' as _iqmsiiah;

abstract class ListAgentsRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ListAgentsRequest._({
    required this.workspaceId,
    required this.search,
    this.type,
    this.status,
    required this.limit,
    this.cursor,
  });

  factory ListAgentsRequest({
    required int workspaceId,
    required String search,
    _iqmsiiah.AgentCatalogType? type,
    _iu7mkbq9.AgentCatalogStatus? status,
    required int limit,
    String? cursor,
  }) = _ListAgentsRequestImpl;

  factory ListAgentsRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return ListAgentsRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      search: jsonSerialization['search'] as String,
      type: jsonSerialization['type'] == null
          ? null
          : _iqmsiiah.AgentCatalogType.fromJson(
              (jsonSerialization['type'] as String),
            ),
      status: jsonSerialization['status'] == null
          ? null
          : _iu7mkbq9.AgentCatalogStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      limit: jsonSerialization['limit'] as int,
      cursor: jsonSerialization['cursor'] as String?,
    );
  }

  int workspaceId;

  String search;

  _iqmsiiah.AgentCatalogType? type;

  _iu7mkbq9.AgentCatalogStatus? status;

  int limit;

  String? cursor;

  /// Returns a shallow copy of this [ListAgentsRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ListAgentsRequest copyWith({
    int? workspaceId,
    String? search,
    _iqmsiiah.AgentCatalogType? type,
    _iu7mkbq9.AgentCatalogStatus? status,
    int? limit,
    String? cursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListAgentsRequest',
      'workspaceId': workspaceId,
      'search': search,
      if (type != null) 'type': type?.toJson(),
      if (status != null) 'status': status?.toJson(),
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListAgentsRequest',
      'workspaceId': workspaceId,
      'search': search,
      if (type != null) 'type': type?.toJson(),
      if (status != null) 'status': status?.toJson(),
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ListAgentsRequestImpl extends ListAgentsRequest {
  _ListAgentsRequestImpl({
    required int workspaceId,
    required String search,
    _iqmsiiah.AgentCatalogType? type,
    _iu7mkbq9.AgentCatalogStatus? status,
    required int limit,
    String? cursor,
  }) : super._(
         workspaceId: workspaceId,
         search: search,
         type: type,
         status: status,
         limit: limit,
         cursor: cursor,
       );

  /// Returns a shallow copy of this [ListAgentsRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ListAgentsRequest copyWith({
    int? workspaceId,
    String? search,
    Object? type = _Undefined,
    Object? status = _Undefined,
    int? limit,
    Object? cursor = _Undefined,
  }) {
    return ListAgentsRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      search: search ?? this.search,
      type: type is _iqmsiiah.AgentCatalogType? ? type : this.type,
      status: status is _iu7mkbq9.AgentCatalogStatus? ? status : this.status,
      limit: limit ?? this.limit,
      cursor: cursor is String? ? cursor : this.cursor,
    );
  }
}
