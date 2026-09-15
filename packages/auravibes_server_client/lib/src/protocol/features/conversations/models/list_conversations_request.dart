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

abstract class ListConversationsRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ListConversationsRequest._({
    required this.workspaceId,
    required this.limit,
    this.cursor,
    this.search,
    this.offset,
  });

  factory ListConversationsRequest({
    required int workspaceId,
    required int limit,
    String? cursor,
    String? search,
    int? offset,
  }) = _ListConversationsRequestImpl;

  factory ListConversationsRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ListConversationsRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      limit: jsonSerialization['limit'] as int,
      cursor: jsonSerialization['cursor'] as String?,
      search: jsonSerialization['search'] as String?,
      offset: jsonSerialization['offset'] as int?,
    );
  }

  int workspaceId;

  int limit;

  String? cursor;

  String? search;

  int? offset;

  /// Returns a shallow copy of this [ListConversationsRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ListConversationsRequest copyWith({
    int? workspaceId,
    int? limit,
    String? cursor,
    String? search,
    int? offset,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListConversationsRequest',
      'workspaceId': workspaceId,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (search != null) 'search': search,
      if (offset != null) 'offset': offset,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListConversationsRequest',
      'workspaceId': workspaceId,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (search != null) 'search': search,
      if (offset != null) 'offset': offset,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ListConversationsRequestImpl extends ListConversationsRequest {
  _ListConversationsRequestImpl({
    required int workspaceId,
    required int limit,
    String? cursor,
    String? search,
    int? offset,
  }) : super._(
         workspaceId: workspaceId,
         limit: limit,
         cursor: cursor,
         search: search,
         offset: offset,
       );

  /// Returns a shallow copy of this [ListConversationsRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ListConversationsRequest copyWith({
    int? workspaceId,
    int? limit,
    Object? cursor = _Undefined,
    Object? search = _Undefined,
    Object? offset = _Undefined,
  }) {
    return ListConversationsRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      limit: limit ?? this.limit,
      cursor: cursor is String? ? cursor : this.cursor,
      search: search is String? ? search : this.search,
      offset: offset is int? ? offset : this.offset,
    );
  }
}
