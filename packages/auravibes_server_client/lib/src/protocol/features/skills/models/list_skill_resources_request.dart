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

abstract class ListSkillResourcesRequest
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ListSkillResourcesRequest._({
    required this.workspaceId,
    required this.skillId,
  });

  factory ListSkillResourcesRequest({
    required int workspaceId,
    required String skillId,
  }) = _ListSkillResourcesRequestImpl;

  factory ListSkillResourcesRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ListSkillResourcesRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      skillId: jsonSerialization['skillId'] as String,
    );
  }

  int workspaceId;

  String skillId;

  /// Returns a shallow copy of this [ListSkillResourcesRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ListSkillResourcesRequest copyWith({
    int? workspaceId,
    String? skillId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListSkillResourcesRequest',
      'workspaceId': workspaceId,
      'skillId': skillId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ListSkillResourcesRequest',
      'workspaceId': workspaceId,
      'skillId': skillId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _ListSkillResourcesRequestImpl extends ListSkillResourcesRequest {
  _ListSkillResourcesRequestImpl({
    required int workspaceId,
    required String skillId,
  }) : super._(
         workspaceId: workspaceId,
         skillId: skillId,
       );

  /// Returns a shallow copy of this [ListSkillResourcesRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ListSkillResourcesRequest copyWith({
    int? workspaceId,
    String? skillId,
  }) {
    return ListSkillResourcesRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      skillId: skillId ?? this.skillId,
    );
  }
}
