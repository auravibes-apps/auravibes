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

abstract class SkillResourceView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SkillResourceView._({
    required this.id,
    required this.skillId,
    required this.title,
    required this.slug,
    required this.description,
    required this.content,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SkillResourceView({
    required String id,
    required String skillId,
    required String title,
    required String slug,
    required String description,
    required String content,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SkillResourceViewImpl;

  factory SkillResourceView.fromJson(Map<String, dynamic> jsonSerialization) {
    return SkillResourceView(
      id: jsonSerialization['id'] as String,
      skillId: jsonSerialization['skillId'] as String,
      title: jsonSerialization['title'] as String,
      slug: jsonSerialization['slug'] as String,
      description: jsonSerialization['description'] as String,
      content: jsonSerialization['content'] as String,
      revision: jsonSerialization['revision'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  String id;

  String skillId;

  String title;

  String slug;

  String description;

  String content;

  int revision;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [SkillResourceView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SkillResourceView copyWith({
    String? id,
    String? skillId,
    String? title,
    String? slug,
    String? description,
    String? content,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SkillResourceView',
      'id': id,
      'skillId': skillId,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SkillResourceView',
      'id': id,
      'skillId': skillId,
      'title': title,
      'slug': slug,
      'description': description,
      'content': content,
      'revision': revision,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SkillResourceViewImpl extends SkillResourceView {
  _SkillResourceViewImpl({
    required String id,
    required String skillId,
    required String title,
    required String slug,
    required String description,
    required String content,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         skillId: skillId,
         title: title,
         slug: slug,
         description: description,
         content: content,
         revision: revision,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SkillResourceView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SkillResourceView copyWith({
    String? id,
    String? skillId,
    String? title,
    String? slug,
    String? description,
    String? content,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkillResourceView(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      content: content ?? this.content,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
