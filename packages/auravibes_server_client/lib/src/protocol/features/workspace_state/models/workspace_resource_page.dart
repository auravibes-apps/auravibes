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
import '../../../features/workspace_state/models/workspace_resource.dart'
    as _i3;

import 'package:auravibes_server_client/src/protocol/protocol.dart' as _i4;

abstract class WorkspaceResourcePage._({
  required var _i2.WorkspaceResourceKind resourceKind,
  required var List<_i3.WorkspaceResource> resources,
  var String? nextResourceId,
}) implements _i1.SerializableModel {
  factory({
    required _i2.WorkspaceResourceKind resourceKind,
    required List<_i3.WorkspaceResource> resources,
    String? nextResourceId,
  }) = _WorkspaceResourcePageImpl;

  factory fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceResourcePage(
      resourceKind: _i2.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resources: _i4.Protocol().deserialize<List<_i3.WorkspaceResource>>(
        jsonSerialization['resources'],
      ),
      nextResourceId: jsonSerialization['nextResourceId'] as String?,
    );
  }

  /// Returns a shallow copy of this [WorkspaceResourcePage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceResourcePage copyWith({
    _i2.WorkspaceResourceKind? resourceKind,
    List<_i3.WorkspaceResource>? resources,
    String? nextResourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceResourcePage',
      'resourceKind': resourceKind.toJson(),
      'resources': resources.toJson(valueToJson: (v) => v.toJson()),
      if (nextResourceId != null) 'nextResourceId': nextResourceId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined;

class _WorkspaceResourcePageImpl({
  required _i2.WorkspaceResourceKind resourceKind,
  required List<_i3.WorkspaceResource> resources,
  String? nextResourceId,
}) extends WorkspaceResourcePage {
  this
    : super._(
        resourceKind: resourceKind,
        resources: resources,
        nextResourceId: nextResourceId,
      );

  /// Returns a shallow copy of this [WorkspaceResourcePage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceResourcePage copyWith({
    _i2.WorkspaceResourceKind? resourceKind,
    List<_i3.WorkspaceResource>? resources,
    Object? nextResourceId = _Undefined,
  }) {
    return WorkspaceResourcePage(
      resourceKind: resourceKind ?? this.resourceKind,
      resources:
          resources ?? this.resources.map((e0) => e0.copyWith()).toList(),
      nextResourceId: nextResourceId is String?
          ? nextResourceId
          : this.nextResourceId,
    );
  }
}
