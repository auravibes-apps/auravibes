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
import 'package:auravibes_server_client/src/protocol/protocol.dart'
    as _isctvzjc;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import '../../../features/workspace_state/models/workspace_resource.dart'
    as _i4gad2ja;
import '../../../features/workspace_state/models/workspace_resource_kind.dart'
    as _iz7spkcy;

abstract class WorkspaceResourcePage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WorkspaceResourcePage._({
    required this.resourceKind,
    required this.resources,
    this.nextResourceId,
  });

  factory WorkspaceResourcePage({
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required List<_i4gad2ja.WorkspaceResource> resources,
    String? nextResourceId,
  }) = _WorkspaceResourcePageImpl;

  factory WorkspaceResourcePage.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceResourcePage(
      resourceKind: _iz7spkcy.WorkspaceResourceKind.fromJson(
        (jsonSerialization['resourceKind'] as String),
      ),
      resources: _isctvzjc.Protocol()
          .deserialize<List<_i4gad2ja.WorkspaceResource>>(
            jsonSerialization['resources'],
          ),
      nextResourceId: jsonSerialization['nextResourceId'] as String?,
    );
  }

  _iz7spkcy.WorkspaceResourceKind resourceKind;

  List<_i4gad2ja.WorkspaceResource> resources;

  String? nextResourceId;

  /// Returns a shallow copy of this [WorkspaceResourcePage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WorkspaceResourcePage copyWith({
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    List<_i4gad2ja.WorkspaceResource>? resources,
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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceResourcePage',
      'resourceKind': resourceKind.toJson(),
      'resources': resources.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (nextResourceId != null) 'nextResourceId': nextResourceId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceResourcePageImpl extends WorkspaceResourcePage {
  _WorkspaceResourcePageImpl({
    required _iz7spkcy.WorkspaceResourceKind resourceKind,
    required List<_i4gad2ja.WorkspaceResource> resources,
    String? nextResourceId,
  }) : super._(
         resourceKind: resourceKind,
         resources: resources,
         nextResourceId: nextResourceId,
       );

  /// Returns a shallow copy of this [WorkspaceResourcePage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WorkspaceResourcePage copyWith({
    _iz7spkcy.WorkspaceResourceKind? resourceKind,
    List<_i4gad2ja.WorkspaceResource>? resources,
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
