import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_resources_dao.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:uuid/v7.dart';

class SkillResourcesRepository(AppDatabase database) {
  final SkillResourcesDao _dao = database.skillResourcesDao;

  Future<List<SkillResourceEntity>> getSkillResources(String skillId) async =>
      (await _dao.getSkillResources(skillId)).map(_toEntity).toList();

  Future<SkillResourceEntity?> getResourceById(String resourceId) async {
    final row = await _dao.getResourceById(resourceId);

    return _toNullableEntity(row);
  }

  Future<SkillResourceEntity?> getResourceBySlug(
    String skillId,
    String slug,
  ) async {
    final row = await _dao.getResourceBySlug(skillId, slug);

    return _toNullableEntity(row);
  }

  Future<SkillResourceEntity> createResource(
    String skillId,
    SkillResourceToCreate value,
  ) async => _toEntity(
    await _dao.createResource(
      .new(
        id: .new(const UuidV7().generate()),
        skillId: .new(skillId),
        title: .new(value.title.trim()),
        slug: .new(generateSkillSlug(value.title)),
        description: .new(value.description.trim()),
        content: .new(value.content),
      ),
    ),
  );

  Future<SkillResourceEntity> updateResource(
    String resourceId,
    SkillResourceToUpdate value,
  ) async => _toEntity(
    await _dao.updateResource(
      resourceId,
      .new(
        updatedAt: .new(DateTime.now().toUtc()),
        title: .absentIfNull(value.title?.trim()),
        description: .absentIfNull(value.description?.trim()),
        content: .absentIfNull(value.content),
      ),
    ),
  );

  Future<bool> deleteResource(String resourceId) =>
      _dao.deleteResource(resourceId);
}

extension on SkillResourcesRepository {
  SkillResourceEntity? _toNullableEntity(SkillResourcesTable? value) =>
      value == null ? null : _toEntity(value);

  SkillResourceEntity _toEntity(SkillResourcesTable value) =>
      SkillResourceEntity(
        id: value.id,
        skillId: value.skillId,
        title: value.title,
        slug: value.slug,
        description: value.description,
        content: value.content,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
      );
}
