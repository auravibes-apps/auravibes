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

import '../../../features/workspaces/models/cloud_workspace_capabilities.dart'
    as _iwu19n1x;
import '../../../features/workspaces/models/cloud_workspace_summary.dart'
    as _ispulebx;

abstract class CloudWorkspaceDetail
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CloudWorkspaceDetail._({
    required this.workspace,
    required this.ownerUserId,
    this.ownerEmail,
    required this.capabilities,
  });

  factory CloudWorkspaceDetail({
    required _ispulebx.CloudWorkspaceSummary workspace,
    required String ownerUserId,
    String? ownerEmail,
    required _iwu19n1x.CloudWorkspaceCapabilities capabilities,
  }) = _CloudWorkspaceDetailImpl;

  factory CloudWorkspaceDetail.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceDetail(
      workspace: _isctvzjc.Protocol()
          .deserialize<_ispulebx.CloudWorkspaceSummary>(
            jsonSerialization['workspace'],
          ),
      ownerUserId: jsonSerialization['ownerUserId'] as String,
      ownerEmail: jsonSerialization['ownerEmail'] as String?,
      capabilities: _isctvzjc.Protocol()
          .deserialize<_iwu19n1x.CloudWorkspaceCapabilities>(
            jsonSerialization['capabilities'],
          ),
    );
  }

  _ispulebx.CloudWorkspaceSummary workspace;

  String ownerUserId;

  String? ownerEmail;

  _iwu19n1x.CloudWorkspaceCapabilities capabilities;

  /// Returns a shallow copy of this [CloudWorkspaceDetail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CloudWorkspaceDetail copyWith({
    _ispulebx.CloudWorkspaceSummary? workspace,
    String? ownerUserId,
    String? ownerEmail,
    _iwu19n1x.CloudWorkspaceCapabilities? capabilities,
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
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CloudWorkspaceDetailImpl extends CloudWorkspaceDetail {
  _CloudWorkspaceDetailImpl({
    required _ispulebx.CloudWorkspaceSummary workspace,
    required String ownerUserId,
    String? ownerEmail,
    required _iwu19n1x.CloudWorkspaceCapabilities capabilities,
  }) : super._(
         workspace: workspace,
         ownerUserId: ownerUserId,
         ownerEmail: ownerEmail,
         capabilities: capabilities,
       );

  /// Returns a shallow copy of this [CloudWorkspaceDetail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CloudWorkspaceDetail copyWith({
    _ispulebx.CloudWorkspaceSummary? workspace,
    String? ownerUserId,
    Object? ownerEmail = _Undefined,
    _iwu19n1x.CloudWorkspaceCapabilities? capabilities,
  }) {
    return CloudWorkspaceDetail(
      workspace: workspace ?? this.workspace.copyWith(),
      ownerUserId: ownerUserId ?? this.ownerUserId,
      ownerEmail: ownerEmail is String? ? ownerEmail : this.ownerEmail,
      capabilities: capabilities ?? this.capabilities.copyWith(),
    );
  }
}
