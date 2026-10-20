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

abstract class SearchConversationMessagesRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SearchConversationMessagesRequest._({
    required this.workspaceId,
    required this.query,
    required this.limit,
    required this.offset,
  });

  factory SearchConversationMessagesRequest({
    required int workspaceId,
    required String query,
    required int limit,
    required int offset,
  }) = _SearchConversationMessagesRequestImpl;

  factory SearchConversationMessagesRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return SearchConversationMessagesRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      query: jsonSerialization['query'] as String,
      limit: jsonSerialization['limit'] as int,
      offset: jsonSerialization['offset'] as int,
    );
  }

  int workspaceId;

  String query;

  int limit;

  int offset;

  /// Returns a shallow copy of this [SearchConversationMessagesRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SearchConversationMessagesRequest copyWith({
    int? workspaceId,
    String? query,
    int? limit,
    int? offset,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchConversationMessagesRequest',
      'workspaceId': workspaceId,
      'query': query,
      'limit': limit,
      'offset': offset,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchConversationMessagesRequest',
      'workspaceId': workspaceId,
      'query': query,
      'limit': limit,
      'offset': offset,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _SearchConversationMessagesRequestImpl
    extends SearchConversationMessagesRequest {
  _SearchConversationMessagesRequestImpl({
    required int workspaceId,
    required String query,
    required int limit,
    required int offset,
  }) : super._(
         workspaceId: workspaceId,
         query: query,
         limit: limit,
         offset: offset,
       );

  /// Returns a shallow copy of this [SearchConversationMessagesRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SearchConversationMessagesRequest copyWith({
    int? workspaceId,
    String? query,
    int? limit,
    int? offset,
  }) {
    return SearchConversationMessagesRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      query: query ?? this.query,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
