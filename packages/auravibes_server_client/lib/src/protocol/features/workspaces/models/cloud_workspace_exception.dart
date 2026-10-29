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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

import '../../../features/workspaces/models/cloud_workspace_error_code.dart'
    as _ipvhvodq;

abstract class CloudWorkspaceException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  CloudWorkspaceException._({
    required this.code,
    this.blockingResourcesJson,
  });

  factory CloudWorkspaceException({
    required _ipvhvodq.CloudWorkspaceErrorCode code,
    String? blockingResourcesJson,
  }) = _CloudWorkspaceExceptionImpl;

  factory CloudWorkspaceException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudWorkspaceException(
      code: _ipvhvodq.CloudWorkspaceErrorCode.fromJson(
        (jsonSerialization['code'] as String),
      ),
      blockingResourcesJson:
          jsonSerialization['blockingResourcesJson'] as String?,
    );
  }

  _ipvhvodq.CloudWorkspaceErrorCode code;

  String? blockingResourcesJson;

  /// Returns a shallow copy of this [CloudWorkspaceException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CloudWorkspaceException copyWith({
    _ipvhvodq.CloudWorkspaceErrorCode? code,
    String? blockingResourcesJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudWorkspaceException',
      'code': code.toJson(),
      if (blockingResourcesJson != null)
        'blockingResourcesJson': blockingResourcesJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CloudWorkspaceException',
      'code': code.toJson(),
      if (blockingResourcesJson != null)
        'blockingResourcesJson': blockingResourcesJson,
    };
  }

  @override
  String toString() {
    return 'CloudWorkspaceException(code: $code, blockingResourcesJson: $blockingResourcesJson)';
  }
}

class _Undefined {}

class _CloudWorkspaceExceptionImpl extends CloudWorkspaceException {
  _CloudWorkspaceExceptionImpl({
    required _ipvhvodq.CloudWorkspaceErrorCode code,
    String? blockingResourcesJson,
  }) : super._(
         code: code,
         blockingResourcesJson: blockingResourcesJson,
       );

  /// Returns a shallow copy of this [CloudWorkspaceException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CloudWorkspaceException copyWith({
    _ipvhvodq.CloudWorkspaceErrorCode? code,
    Object? blockingResourcesJson = _Undefined,
  }) {
    return CloudWorkspaceException(
      code: code ?? this.code,
      blockingResourcesJson: blockingResourcesJson is String?
          ? blockingResourcesJson
          : this.blockingResourcesJson,
    );
  }
}
