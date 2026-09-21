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

abstract class SkillResource
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SkillResource._({
    this.id,
    required this.workspaceId,
    required this.skillId,
    required this.resourceId,
    required this.title,
    required this.slug,
    required this.description,
    required this.content,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SkillResource({
    int? id,
    required int workspaceId,
    required String skillId,
    required String resourceId,
    required String title,
    required String slug,
    required String description,
    required String content,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _SkillResourceImpl;

  factory SkillResource.fromJson(Map<String, dynamic> jsonSerialization) {
    return SkillResource(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      skillId: jsonSerialization['skillId'] as String,
      resourceId: jsonSerialization['resourceId'] as String,
      title: jsonSerialization['title'] as String,
      slug: jsonSerialization['slug'] as String,
      description: jsonSerialization['description'] as String,
      content: jsonSerialization['content'] as String,
      revision: jsonSerialization['revision'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int workspaceId;

  String skillId;

  String resourceId;

  String title;

  String slug;

  String description;

  String content;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [SkillResource]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SkillResource copyWith({
    int? id,
    int? workspaceId,
    String? skillId,
    String? resourceId,
    String? title,
    String? slug,
    String? description,
    String? content,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SkillResource',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'skillId': skillId,
      'resourceId': resourceId,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SkillResource',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'skillId': skillId,
      'resourceId': resourceId,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SkillResourceImpl extends SkillResource {
  _SkillResourceImpl({
    int? id,
    required int workspaceId,
    required String skillId,
    required String resourceId,
    required String title,
    required String slug,
    required String description,
    required String content,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         skillId: skillId,
         resourceId: resourceId,
         title: title,
         slug: slug,
         description: description,
         content: content,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [SkillResource]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SkillResource copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? skillId,
    String? resourceId,
    String? title,
    String? slug,
    String? description,
    String? content,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return SkillResource(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      skillId: skillId ?? this.skillId,
      resourceId: resourceId ?? this.resourceId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      content: content ?? this.content,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
