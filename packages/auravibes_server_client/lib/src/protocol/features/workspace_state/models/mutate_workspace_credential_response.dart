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

abstract class MutateWorkspaceCredentialResponse
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MutateWorkspaceCredentialResponse._({
    required this.resource,
    required this.configured,
    this.displaySuffix,
    this.secretRevision,
    required this.sequence,
  });

  factory MutateWorkspaceCredentialResponse({
    required _i4gad2ja.WorkspaceResource resource,
    required bool configured,
    String? displaySuffix,
    int? secretRevision,
    required int sequence,
  }) = _MutateWorkspaceCredentialResponseImpl;

  factory MutateWorkspaceCredentialResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MutateWorkspaceCredentialResponse(
      resource: _isctvzjc.Protocol().deserialize<_i4gad2ja.WorkspaceResource>(
        jsonSerialization['resource'],
      ),
      configured: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['configured'],
      ),
      displaySuffix: jsonSerialization['displaySuffix'] as String?,
      secretRevision: jsonSerialization['secretRevision'] as int?,
      sequence: jsonSerialization['sequence'] as int,
    );
  }

  _i4gad2ja.WorkspaceResource resource;

  bool configured;

  String? displaySuffix;

  int? secretRevision;

  int sequence;

  /// Returns a shallow copy of this [MutateWorkspaceCredentialResponse]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MutateWorkspaceCredentialResponse copyWith({
    _i4gad2ja.WorkspaceResource? resource,
    bool? configured,
    String? displaySuffix,
    int? secretRevision,
    int? sequence,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MutateWorkspaceCredentialResponse',
      'resource': resource.toJson(),
      'configured': configured,
      if (displaySuffix != null) 'displaySuffix': displaySuffix,
      if (secretRevision != null) 'secretRevision': secretRevision,
      'sequence': sequence,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MutateWorkspaceCredentialResponse',
      'resource': resource.toJsonForProtocol(),
      'configured': configured,
      if (displaySuffix != null) 'displaySuffix': displaySuffix,
      if (secretRevision != null) 'secretRevision': secretRevision,
      'sequence': sequence,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MutateWorkspaceCredentialResponseImpl
    extends MutateWorkspaceCredentialResponse {
  _MutateWorkspaceCredentialResponseImpl({
    required _i4gad2ja.WorkspaceResource resource,
    required bool configured,
    String? displaySuffix,
    int? secretRevision,
    required int sequence,
  }) : super._(
         resource: resource,
         configured: configured,
         displaySuffix: displaySuffix,
         secretRevision: secretRevision,
         sequence: sequence,
       );

  /// Returns a shallow copy of this [MutateWorkspaceCredentialResponse]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MutateWorkspaceCredentialResponse copyWith({
    _i4gad2ja.WorkspaceResource? resource,
    bool? configured,
    Object? displaySuffix = _Undefined,
    Object? secretRevision = _Undefined,
    int? sequence,
  }) {
    return MutateWorkspaceCredentialResponse(
      resource: resource ?? this.resource.copyWith(),
      configured: configured ?? this.configured,
      displaySuffix: displaySuffix is String?
          ? displaySuffix
          : this.displaySuffix,
      secretRevision: secretRevision is int?
          ? secretRevision
          : this.secretRevision,
      sequence: sequence ?? this.sequence,
    );
  }
}
