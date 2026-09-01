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

abstract class CreateCloudWorkspaceRequest._({
  required var String name,
  required var String requestId,
}) implements _i1.SerializableModel {
  factory({
    required String name,
    required String requestId,
  }) = _CreateCloudWorkspaceRequestImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateCloudWorkspaceRequest(
      name: jsonSerialization['name'] as String,
      requestId: jsonSerialization['requestId'] as String,
    );
  }

  /// Returns a shallow copy of this [CreateCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CreateCloudWorkspaceRequest copyWith({
    String? name,
    String? requestId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateCloudWorkspaceRequest',
      'name': name,
      'requestId': requestId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CreateCloudWorkspaceRequestImpl({
  required String name,
  required String requestId,
}) extends CreateCloudWorkspaceRequest {
  this
    : super._(
        name: name,
        requestId: requestId,
      );

  /// Returns a shallow copy of this [CreateCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CreateCloudWorkspaceRequest copyWith({
    String? name,
    String? requestId,
  }) {
    return CreateCloudWorkspaceRequest(
      name: name ?? this.name,
      requestId: requestId ?? this.requestId,
    );
  }
}
