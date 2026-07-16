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
    required this.requestId,
    required this.expectedWorkspaceRevision,
  });

  factory RenameCloudWorkspaceRequest({
    required int workspaceId,
    required String name,
    required String requestId,
    required int expectedWorkspaceRevision,
  }) = _RenameCloudWorkspaceRequestImpl;

  factory RenameCloudWorkspaceRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RenameCloudWorkspaceRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      requestId: jsonSerialization['requestId'] as String,
      expectedWorkspaceRevision:
          jsonSerialization['expectedWorkspaceRevision'] as int,
    );
  }

  int workspaceId;

  String name;

  String requestId;

  int expectedWorkspaceRevision;

  /// Returns a shallow copy of this [RenameCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RenameCloudWorkspaceRequest copyWith({
    int? workspaceId,
    String? name,
    String? requestId,
    int? expectedWorkspaceRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RenameCloudWorkspaceRequest',
      'workspaceId': workspaceId,
      'name': name,
      'requestId': requestId,
      'expectedWorkspaceRevision': expectedWorkspaceRevision,
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
    required String requestId,
    required int expectedWorkspaceRevision,
  }) : super._(
         workspaceId: workspaceId,
         name: name,
         requestId: requestId,
         expectedWorkspaceRevision: expectedWorkspaceRevision,
       );

  /// Returns a shallow copy of this [RenameCloudWorkspaceRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RenameCloudWorkspaceRequest copyWith({
    int? workspaceId,
    String? name,
    String? requestId,
    int? expectedWorkspaceRevision,
  }) {
    return RenameCloudWorkspaceRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      requestId: requestId ?? this.requestId,
      expectedWorkspaceRevision:
          expectedWorkspaceRevision ?? this.expectedWorkspaceRevision,
    );
  }
}
