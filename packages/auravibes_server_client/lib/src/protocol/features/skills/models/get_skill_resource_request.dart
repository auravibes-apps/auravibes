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

abstract class GetSkillResourceRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  GetSkillResourceRequest._({
    required this.workspaceId,
    required this.resourceId,
  });

  factory GetSkillResourceRequest({
    required int workspaceId,
    required String resourceId,
  }) = _GetSkillResourceRequestImpl;

  factory GetSkillResourceRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GetSkillResourceRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      resourceId: jsonSerialization['resourceId'] as String,
    );
  }

  int workspaceId;

  String resourceId;

  /// Returns a shallow copy of this [GetSkillResourceRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  GetSkillResourceRequest copyWith({
    int? workspaceId,
    String? resourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GetSkillResourceRequest',
      'workspaceId': workspaceId,
      'resourceId': resourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GetSkillResourceRequest',
      'workspaceId': workspaceId,
      'resourceId': resourceId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _GetSkillResourceRequestImpl extends GetSkillResourceRequest {
  _GetSkillResourceRequestImpl({
    required int workspaceId,
    required String resourceId,
  }) : super._(
         workspaceId: workspaceId,
         resourceId: resourceId,
       );

  /// Returns a shallow copy of this [GetSkillResourceRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  GetSkillResourceRequest copyWith({
    int? workspaceId,
    String? resourceId,
  }) {
    return GetSkillResourceRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      resourceId: resourceId ?? this.resourceId,
    );
  }
}
