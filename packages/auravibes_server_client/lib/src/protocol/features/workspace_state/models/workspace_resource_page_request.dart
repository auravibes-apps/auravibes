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

import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _i2;

abstract class WorkspaceResourcePageRequest implements _i1.SerializableModel {
  WorkspaceResourcePageRequest._({
    required this.resourceKind,
    this.afterResourceId,
    required this.limit,
  });

  factory WorkspaceResourcePageRequest({
    required _i2.WorkspaceResourceKind resourceKind,
    String? afterResourceId,
    required int limit,
  }) = _WorkspaceResourcePageRequestImpl;

  factory WorkspaceResourcePageRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceResourcePageRequest(
      resourceKind: _i2.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      afterResourceId: jsonSerialization['afterResourceId'] as String?,
      limit: jsonSerialization['limit'] as int,
    );
  }

  _i2.WorkspaceResourceKind resourceKind;

  String? afterResourceId;

  int limit;

  /// Returns a shallow copy of this [WorkspaceResourcePageRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceResourcePageRequest copyWith({
    _i2.WorkspaceResourceKind? resourceKind,
    String? afterResourceId,
    int? limit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceResourcePageRequest',
      'resourceKind': resourceKind.toJson(),
      if (afterResourceId != null) 'afterResourceId': afterResourceId,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceResourcePageRequestImpl extends WorkspaceResourcePageRequest {
  _WorkspaceResourcePageRequestImpl({
    required _i2.WorkspaceResourceKind resourceKind,
    String? afterResourceId,
    required int limit,
  }) : super._(
         resourceKind: resourceKind,
         afterResourceId: afterResourceId,
         limit: limit,
       );

  /// Returns a shallow copy of this [WorkspaceResourcePageRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceResourcePageRequest copyWith({
    _i2.WorkspaceResourceKind? resourceKind,
    Object? afterResourceId = _Undefined,
    int? limit,
  }) {
    return WorkspaceResourcePageRequest(
      resourceKind: resourceKind ?? this.resourceKind,
      afterResourceId: afterResourceId is String?
          ? afterResourceId
          : this.afterResourceId,
      limit: limit ?? this.limit,
    );
  }
}
