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
import '../../../features/workspaces/models/cloud_workspace_summary.dart'
    as _i2;
import '../../../features/workspaces/models/cloud_workspace_capabilities.dart'
    as _i3;
import 'package:auravibes_server/src/generated/protocol.dart' as _i4;

abstract class CloudWorkspaceDetail
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CloudWorkspaceDetail._({
    required this.workspace,
    required this.ownerUserId,
    this.ownerEmail,
    required this.capabilities,
  });

  factory CloudWorkspaceDetail({
    required _i2.CloudWorkspaceSummary workspace,
    required String ownerUserId,
    String? ownerEmail,
    required _i3.CloudWorkspaceCapabilities capabilities,
  }) = _CloudWorkspaceDetailImpl;

  factory CloudWorkspaceDetail.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceDetail(
      workspace: _i4.Protocol().deserialize<_i2.CloudWorkspaceSummary>(
        jsonSerialization['workspace'],
      ),
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      ownerEmail: jsonSerialization['ownerEmail'] as String?,
      capabilities: _i4.Protocol().deserialize<_i3.CloudWorkspaceCapabilities>(
        jsonSerialization['capabilities'],
      ),
    );
  }

  _i2.CloudWorkspaceSummary workspace;

  String ownerUserId;

  String? ownerEmail;

  _i3.CloudWorkspaceCapabilities capabilities;

  /// Returns a shallow copy of this [CloudWorkspaceDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudWorkspaceDetail copyWith({
    _i2.CloudWorkspaceSummary? workspace,
    String? ownerUserId,
    String? ownerEmail,
    _i3.CloudWorkspaceCapabilities? capabilities,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceDetail',
      'workspace': workspace.toJson(),
      'ownerUserId': ownerUserId,
      if (ownerEmail != null) 'ownerEmail': ownerEmail,
      'capabilities': capabilities.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CloudWorkspaceDetail',
      'workspace': workspace.toJsonForProtocol(),
      'ownerUserId': ownerUserId,
      if (ownerEmail != null) 'ownerEmail': ownerEmail,
      'capabilities': capabilities.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CloudWorkspaceDetailImpl extends CloudWorkspaceDetail {
  _CloudWorkspaceDetailImpl({
    required _i2.CloudWorkspaceSummary workspace,
    required String ownerUserId,
    String? ownerEmail,
    required _i3.CloudWorkspaceCapabilities capabilities,
  }) : super._(
         workspace: workspace,
         ownerUserId: ownerUserId,
         ownerEmail: ownerEmail,
         capabilities: capabilities,
       );

  /// Returns a shallow copy of this [CloudWorkspaceDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CloudWorkspaceDetail copyWith({
    _i2.CloudWorkspaceSummary? workspace,
    String? ownerUserId,
    Object? ownerEmail = _Undefined,
    _i3.CloudWorkspaceCapabilities? capabilities,
  }) {
    return CloudWorkspaceDetail(
      workspace: workspace ?? this.workspace.copyWith(),
      ownerUserId: ownerUserId ?? this.ownerUserId,
      ownerEmail: ownerEmail is String? ? ownerEmail : this.ownerEmail,
      capabilities: capabilities ?? this.capabilities.copyWith(),
    );
  }
}
