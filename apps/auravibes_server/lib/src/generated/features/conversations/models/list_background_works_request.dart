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
import 'package:serverpod/serverpod.dart' as _is;

abstract class ListBackgroundWorksRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ListBackgroundWorksRequest._({
    required this.workspaceId,
    required this.conversationId,
  });

  factory ListBackgroundWorksRequest({
    required int workspaceId,
    required String conversationId,
  }) = _ListBackgroundWorksRequestImpl;

  factory ListBackgroundWorksRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ListBackgroundWorksRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as String,
    );
  }

  int workspaceId;

  String conversationId;

  /// Returns a shallow copy of this [ListBackgroundWorksRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ListBackgroundWorksRequest copyWith({
    int? workspaceId,
    String? conversationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListBackgroundWorksRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListBackgroundWorksRequest',
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ListBackgroundWorksRequestImpl extends ListBackgroundWorksRequest {
  _ListBackgroundWorksRequestImpl({
    required int workspaceId,
    required String conversationId,
  }) : super._(
         workspaceId: workspaceId,
         conversationId: conversationId,
       );

  /// Returns a shallow copy of this [ListBackgroundWorksRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ListBackgroundWorksRequest copyWith({
    int? workspaceId,
    String? conversationId,
  }) {
    return ListBackgroundWorksRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
