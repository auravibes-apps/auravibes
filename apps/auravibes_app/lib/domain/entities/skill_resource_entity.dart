import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_resource_entity.freezed.dart';

@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const SkillResourceEntity._() with _$SkillResourceEntity {
  const factory({
    required String id,
    required String skillId,
    required String title,
    required String slug,
    required String description,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(1) int revision,
  }) = _SkillResourceEntity;
}

@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const SkillResourceToCreate._() with _$SkillResourceToCreate {
  const factory({
    required String title,
    required String description,
    required String content,
  }) = _SkillResourceToCreate;
}

@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const SkillResourceToUpdate._() with _$SkillResourceToUpdate {
  const factory({String? title, String? description, String? content}) =
      _SkillResourceToUpdate;
}
