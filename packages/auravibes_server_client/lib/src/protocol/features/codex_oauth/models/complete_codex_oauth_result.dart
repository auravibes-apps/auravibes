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

abstract class CompleteCodexOAuthResult implements _i1.SerializableModel {
  CompleteCodexOAuthResult._({
    required this.workspaceId,
    required this.connectionId,
    required this.configured,
  });

  factory CompleteCodexOAuthResult({
    required int workspaceId,
    required String connectionId,
    required bool configured,
  }) = _CompleteCodexOAuthResultImpl;

  factory CompleteCodexOAuthResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CompleteCodexOAuthResult(
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectionId: jsonSerialization['connectionId'] as String,
      configured: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['configured'],
      ),
    );
  }

  int workspaceId;

  String connectionId;

  bool configured;

  /// Returns a shallow copy of this [CompleteCodexOAuthResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CompleteCodexOAuthResult copyWith({
    int? workspaceId,
    String? connectionId,
    bool? configured,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompleteCodexOAuthResult',
      'workspaceId': workspaceId,
      'connectionId': connectionId,
      'configured': configured,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CompleteCodexOAuthResultImpl extends CompleteCodexOAuthResult {
  _CompleteCodexOAuthResultImpl({
    required int workspaceId,
    required String connectionId,
    required bool configured,
  }) : super._(
         workspaceId: workspaceId,
         connectionId: connectionId,
         configured: configured,
       );

  /// Returns a shallow copy of this [CompleteCodexOAuthResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CompleteCodexOAuthResult copyWith({
    int? workspaceId,
    String? connectionId,
    bool? configured,
  }) {
    return CompleteCodexOAuthResult(
      workspaceId: workspaceId ?? this.workspaceId,
      connectionId: connectionId ?? this.connectionId,
      configured: configured ?? this.configured,
    );
  }
}
