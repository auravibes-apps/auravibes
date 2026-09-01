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

abstract class ListConversationsRequest._({
  required var int workspaceId,
  required var int limit,
  var String? cursor,
}) implements _i1.SerializableModel {
  factory({
    required int workspaceId,
    required int limit,
    String? cursor,
  }) = _ListConversationsRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ListConversationsRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      limit: jsonSerialization['limit'] as int,
      cursor: jsonSerialization['cursor'] as String?,
    );
  }

  /// Returns a shallow copy of this [ListConversationsRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListConversationsRequest copyWith({
    int? workspaceId,
    int? limit,
    String? cursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListConversationsRequest',
      'workspaceId': workspaceId,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _ListConversationsRequestImpl({
  required int workspaceId,
  required int limit,
  String? cursor,
}) extends ListConversationsRequest {
  this
    : super._(
        workspaceId: workspaceId,
        limit: limit,
        cursor: cursor,
      );

  /// Returns a shallow copy of this [ListConversationsRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListConversationsRequest copyWith({
    int? workspaceId,
    int? limit,
    Object? cursor = _Undefined,
  }) {
    return ListConversationsRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      limit: limit ?? this.limit,
      cursor: cursor is String? ? cursor : this.cursor,
    );
  }
}
