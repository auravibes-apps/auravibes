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
import 'package:serverpod/serverpod.dart' as _is;

abstract class CreateSkillResourceRequest
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CreateSkillResourceRequest._({
    required this.workspaceId,
    required this.requestId,
    required this.skillId,
    required this.resourceId,
    required this.title,
    required this.description,
    required this.content,
  });

  factory CreateSkillResourceRequest({
    required int workspaceId,
    required String requestId,
    required String skillId,
    required String resourceId,
    required String title,
    required String description,
    required String content,
  }) = _CreateSkillResourceRequestImpl;

  factory CreateSkillResourceRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CreateSkillResourceRequest(
      workspaceId: jsonSerialization['workspaceId'] as int,
      requestId: jsonSerialization['requestId'] as String,
      skillId: jsonSerialization['skillId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      content: jsonSerialization['content'] as String,
    );
  }

  int workspaceId;

  String requestId;

  String skillId;

  String resourceId;

  String title;

  String description;

  String content;

  /// Returns a shallow copy of this [CreateSkillResourceRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CreateSkillResourceRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? skillId,
    String? resourceId,
    String? title,
    String? description,
    String? content,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreateSkillResourceRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'skillId': skillId,
      'resourceId': resourceId,
      'title': title,
      'description': description,
      'content': content,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreateSkillResourceRequest',
      'workspaceId': workspaceId,
      'requestId': requestId,
      'skillId': skillId,
      'resourceId': resourceId,
      'title': title,
      'description': description,
      'content': content,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _CreateSkillResourceRequestImpl extends CreateSkillResourceRequest {
  _CreateSkillResourceRequestImpl({
    required int workspaceId,
    required String requestId,
    required String skillId,
    required String resourceId,
    required String title,
    required String description,
    required String content,
  }) : super._(
         workspaceId: workspaceId,
         requestId: requestId,
         skillId: skillId,
         resourceId: resourceId,
         title: title,
         description: description,
         content: content,
       );

  /// Returns a shallow copy of this [CreateSkillResourceRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CreateSkillResourceRequest copyWith({
    int? workspaceId,
    String? requestId,
    String? skillId,
    String? resourceId,
    String? title,
    String? description,
    String? content,
  }) {
    return CreateSkillResourceRequest(
      workspaceId: workspaceId ?? this.workspaceId,
      requestId: requestId ?? this.requestId,
      skillId: skillId ?? this.skillId,
      resourceId: resourceId ?? this.resourceId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
    );
  }
}
