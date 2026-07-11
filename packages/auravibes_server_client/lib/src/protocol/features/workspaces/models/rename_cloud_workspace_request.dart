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

abstract class RenameCloudWorkspaceRequest implements _i1.SerializableModel {
  RenameCloudWorkspaceRequest._({
    required this.workspaceId,
    required this.name,
  });

  factory RenameCloudWorkspaceRequest({
    required int workspaceId,
    required String name,
  }) = _RenameCloudWorkspaceRequestImpl;

  factory RenameCloudWorkspaceRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RenameCloudWorkspaceRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
    );
  }

  int workspaceId;

  String name;

  /// Returns a shallow copy of this [RenameCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RenameCloudWorkspaceRequest copyWith({
    int? workspaceId,
    String? name,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RenameCloudWorkspaceRequest',
      'workspaceId': workspaceId,
      'name': name,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RenameCloudWorkspaceRequestImpl extends RenameCloudWorkspaceRequest {
  _RenameCloudWorkspaceRequestImpl({
    required int workspaceId,
    required String name,
  }) : super._(
         workspaceId: workspaceId,
         name: name,
       );

  /// Returns a shallow copy of this [RenameCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RenameCloudWorkspaceRequest copyWith({
    int? workspaceId,
    String? name,
  }) {
    return RenameCloudWorkspaceRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
    );
  }
}
