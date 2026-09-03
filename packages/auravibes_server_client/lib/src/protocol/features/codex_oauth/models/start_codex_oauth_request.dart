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

abstract class StartCodexOAuthRequest implements _i1.SerializableModel {
  StartCodexOAuthRequest._({
    required this.workspaceId,
    required this.connectionId,
  });

  factory StartCodexOAuthRequest({
    required int workspaceId,
    required String connectionId,
  }) = _StartCodexOAuthRequestImpl;

  factory StartCodexOAuthRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StartCodexOAuthRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
    );
  }

  int workspaceId;

  String connectionId;

  /// Returns a shallow copy of this [StartCodexOAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StartCodexOAuthRequest copyWith({
    int? workspaceId,
    String? connectionId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StartCodexOAuthRequest',
      'workspaceId': workspaceId,
      'connectionId': connectionId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _StartCodexOAuthRequestImpl extends StartCodexOAuthRequest {
  _StartCodexOAuthRequestImpl({
    required int workspaceId,
    required String connectionId,
  }) : super._(
         workspaceId: workspaceId,
         connectionId: connectionId,
       );

  /// Returns a shallow copy of this [StartCodexOAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StartCodexOAuthRequest copyWith({
    int? workspaceId,
    String? connectionId,
  }) {
    return StartCodexOAuthRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
    );
  }
}
