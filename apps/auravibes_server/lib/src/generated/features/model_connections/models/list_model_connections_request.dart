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

abstract class ListModelConnectionsRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ListModelConnectionsRequest._({required this.workspaceId});

  factory ListModelConnectionsRequest({required int workspaceId}) =
      _ListModelConnectionsRequestImpl;

  factory ListModelConnectionsRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ListModelConnectionsRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
    );
  }

  int workspaceId;

  /// Returns a shallow copy of this [ListModelConnectionsRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListModelConnectionsRequest copyWith({int? workspaceId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListModelConnectionsRequest',
      'workspaceId': workspaceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListModelConnectionsRequest',
      'workspaceId': workspaceId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ListModelConnectionsRequestImpl extends ListModelConnectionsRequest {
  _ListModelConnectionsRequestImpl({required int workspaceId})
    : super._(workspaceId: workspaceId);

  /// Returns a shallow copy of this [ListModelConnectionsRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListModelConnectionsRequest copyWith({int? workspaceId}) {
    return ListModelConnectionsRequest(
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }
}
