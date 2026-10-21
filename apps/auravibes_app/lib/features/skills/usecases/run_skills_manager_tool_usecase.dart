// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/clone_app_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/resolved_skill_resource.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:riverpod/src/providers/provider.dart';

const Set<String> _userSkillToolSlugs = {
  SkillToolSlugs.listUserSkills,
  SkillToolSlugs.getUserSkill,
  SkillToolSlugs.createUserSkill,
  SkillToolSlugs.updateUserSkill,
  SkillToolSlugs.deleteUserSkill,
};
const Set<String> _resourceToolSlugs = {
  SkillToolSlugs.listSkillResources,
  SkillToolSlugs.getSkillResource,
  SkillToolSlugs.createSkillResource,
  SkillToolSlugs.updateSkillResource,
  SkillToolSlugs.deleteSkillResource,
};
const Set<String> _appSkillToolSlugs = {SkillToolSlugs.cloneAppSkill};

class const RunSkillsManagerToolUsecase(
  final SkillsRepository? _skillsRepository,
  final CreateSkillUsecase _createSkillUsecase,
  final UpdateSkillUsecase _updateSkillUsecase, {
  final CloudSkillStore? cloudStore,
  final CloneAppSkillUsecase? cloneAppSkillUsecase,
  final SkillResourcesRepository? resourceRepository,
  final CreateSkillResourceUsecase? createSkillResourceUsecase,
  final UpdateSkillResourceUsecase? updateSkillResourceUsecase,
}) {
  Future<Object> call({
    required String workspaceId,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) => _run(workspaceId, toolSlug, arguments);

  Future<Object> _run(
    String workspaceId,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) {
    if (_userSkillToolSlugs.contains(toolSlug)) {
      return _callUserSkillTool(workspaceId, toolSlug, arguments);
    }
    if (_resourceToolSlugs.contains(toolSlug)) {
      return _callResourceTool(workspaceId, toolSlug, arguments);
    }
    if (_appSkillToolSlugs.contains(toolSlug)) {
      return _cloneAppSkill(workspaceId, arguments);
    }

    throw UnsupportedError('Unsupported skills manager tool: $toolSlug');
  }
}

extension _RunSkillsManagerAppSkills on RunSkillsManagerToolUsecase {
  Future<Object> _cloneAppSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final clone = cloneAppSkillUsecase;
    if (clone == null) throw StateError('App skill cloning is unavailable.');
    final skill = await clone.call(
      workspaceId,
      _requiredString(arguments, 'appSkillSlug'),
    );

    return _skillResult('cloned', skill, includeDetails: true);
  }
}

extension _RunSkillsManagerRouting on RunSkillsManagerToolUsecase {
  Future<Object> _callResourceTool(
    String workspaceId,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) => switch (toolSlug) {
    SkillToolSlugs.listSkillResources => _listSkillResources(
      workspaceId,
      arguments,
    ),
    SkillToolSlugs.getSkillResource => _getSkillResourceResult(
      workspaceId,
      arguments,
    ),
    SkillToolSlugs.createSkillResource => _createSkillResource(
      workspaceId,
      arguments,
    ),
    SkillToolSlugs.updateSkillResource => _updateSkillResource(
      workspaceId,
      arguments,
    ),
    SkillToolSlugs.deleteSkillResource => _deleteSkillResource(
      workspaceId,
      arguments,
    ),
    _ => throw UnsupportedError('Unsupported skills manager tool: $toolSlug'),
  };

  Future<Object> _callUserSkillTool(
    String workspaceId,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) => switch (toolSlug) {
    SkillToolSlugs.listUserSkills => _listUserSkills(workspaceId),
    SkillToolSlugs.getUserSkill => _getUserSkillResult(workspaceId, arguments),
    SkillToolSlugs.createUserSkill => _createUserSkill(workspaceId, arguments),
    SkillToolSlugs.updateUserSkill => _updateUserSkill(workspaceId, arguments),
    SkillToolSlugs.deleteUserSkill => _deleteUserSkill(workspaceId, arguments),
    _ => throw UnsupportedError('Unsupported skills manager tool: $toolSlug'),
  };
}

extension _RunSkillsManagerMutations on RunSkillsManagerToolUsecase {
  SkillToUpdate _userSkillUpdateValue(Map<String, dynamic> arguments) => .new(
    title: _optionalString(arguments, 'title'),
    description: _optionalString(arguments, 'description'),
    content: _optionalString(arguments, 'content'),
    connectorToolIds: _optionalStringList(arguments, 'connectorToolIds'),
    isEnabled: _optionalBool(arguments, 'isEnabled'),
  );

  SkillToCreate _userSkillCreateValue(Map<String, dynamic> arguments) => .new(
    kind: SkillKind.template,
    title: _requiredString(arguments, 'title'),
    description: _requiredString(arguments, 'description'),
    content: _requiredString(arguments, 'content'),
    connectorToolIds:
        _optionalStringList(arguments, 'connectorToolIds') ?? const [],
    isEnabled: _optionalBool(arguments, 'isEnabled') ?? true,
  );

  Future<Object> _updateUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final updated = await _updateSkillUsecase.call(
      skill.id,
      _userSkillUpdateValue(arguments),
    );

    return _skillResult('updated', updated, includeDetails: true);
  }

  Future<List<SkillEntity>> _userSkills(String workspaceId) async {
    final cloud = cloudStore;
    if (cloud != null) return await cloud.skills();

    return await _skillsRepositoryOrThrow().getWorkspaceSkills(workspaceId);
  }

  Future<bool> _deleteUserSkillData(SkillEntity skill) async {
    final cloud = cloudStore;
    if (cloud != null) return await _deleteSkill(cloud, skill.id);

    return await _skillsRepositoryOrThrow().deleteSkill(skill.id);
  }
}

extension _RunSkillsManagerUserSkills on RunSkillsManagerToolUsecase {
  Future<Object> _getUserSkillResult(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );

    return _skillResult('found', skill, includeDetails: true);
  }

  Future<Object> _createUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _createSkillUsecase.call(
      workspaceId,
      _userSkillCreateValue(arguments),
    );

    return _skillResult('created', skill, includeDetails: true);
  }

  Future<Object> _listUserSkills(String workspaceId) async {
    final skills = await _userSkills(workspaceId);

    return {'skills': _userSkillResults(skills)};
  }

  List<Map<String, Object?>> _userSkillResults(List<SkillEntity> skills) => [
    for (final skill in skills.where(
      (skill) => skill.source == SkillSource.user,
    ))
      _skillResult('found', skill),
  ];

  Future<Object> _deleteUserSkill(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final deleted = await _deleteUserSkillData(skill);

    return _skillDeletionResult(deleted, skill);
  }
}

extension _RunSkillsManagerResources on RunSkillsManagerToolUsecase {
  Future<List<SkillResourceEntity>> _skillResources(String skillId) {
    final cloud = cloudStore;
    if (cloud != null) return cloud.resources(skillId);
    final repository = resourceRepository;
    if (repository == null) {
      throw StateError('Skill resource store is unavailable');
    }

    return repository.getSkillResources(skillId);
  }

  Future<SkillResourceEntity> _getSkillResource(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final resourceSlug = _requiredString(arguments, 'resourceSlug');
    final resource = (await _skillResources(skill.id))
        .where((candidate) => candidate.slug == resourceSlug)
        .firstOrNull;
    if (resource == null) {
      throw StateError('Skill resource not found: $resourceSlug');
    }

    return resource;
  }

  Future<Object> _listSkillResources(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );

    return {
      'skillSlug': skill.slug,
      'resources': [
        for (final resource in await _skillResources(skill.id))
          _resourceResult('found', resource),
      ],
    };
  }

  Future<Object> _getSkillResourceResult(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async => _resourceResult(
    'found',
    await _getSkillResource(workspaceId, arguments),
    includeDetails: true,
  );

  Future<Object> _createSkillResource(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final skill = await _getUserSkill(
      workspaceId,
      _requiredString(arguments, 'skillSlug'),
    );
    final usecase = createSkillResourceUsecase;
    if (usecase == null) {
      throw StateError('Skill resource creation is unavailable.');
    }
    final resource = await usecase.call(
      skill.id,
      .new(
        title: _requiredString(arguments, 'title'),
        description: _requiredString(arguments, 'description'),
        content: _requiredString(arguments, 'content'),
      ),
    );

    return _resourceResult('created', resource, includeDetails: true);
  }

  Future<Object> _updateSkillResource(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final resource = await _getSkillResource(workspaceId, arguments);
    final usecase = updateSkillResourceUsecase;
    if (usecase == null) {
      throw StateError('Skill resource updates are unavailable.');
    }
    final updated = await usecase.call(
      resource.id,
      .new(
        title: _optionalString(arguments, 'title'),
        description: _optionalString(arguments, 'description'),
        content: _optionalString(arguments, 'content'),
      ),
    );

    return _resourceResult('updated', updated, includeDetails: true);
  }

  Future<Object> _deleteSkillResource(
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final resource = await _getSkillResource(workspaceId, arguments);
    final deleted = await SkillResourceOperations.delete(
      resource.id,
      resourcesRepository: resourceRepository,
      cloudStore: cloudStore,
    );

    return {
      'status': deleted ? 'deleted' : 'not_deleted',
      'resourceId': resource.id,
      'skillId': resource.skillId,
      'slug': resource.slug,
    };
  }
}

extension _RunSkillsManagerLookups on RunSkillsManagerToolUsecase {
  Future<SkillEntity> _getUserSkill(String workspaceId, String slug) async {
    final skill = await _loadUserSkill(workspaceId, slug);
    if (skill == null || skill.source != SkillSource.user) {
      throw StateError('User skill not found: $slug');
    }

    return skill;
  }

  Future<SkillEntity?> _loadUserSkill(String workspaceId, String slug) async {
    final cloud = cloudStore;
    if (cloud != null) {
      return (await cloud.skills())
          .where((item) => item.slug == slug)
          .firstOrNull;
    }
    final repository = _skillsRepository;
    if (repository != null) {
      return await repository.getSkillBySlug(workspaceId, slug);
    }

    throw StateError('Skill store is unavailable');
  }
}

extension _RunSkillsManagerRepositories on RunSkillsManagerToolUsecase {
  SkillsRepository _skillsRepositoryOrThrow() {
    final repository = _skillsRepository;
    if (repository == null) throw StateError('Skill store is unavailable');

    return repository;
  }

  Future<bool> _deleteSkill(CloudSkillStore cloud, String skillId) async {
    await cloud.deleteSkill(skillId);

    return true;
  }
}

extension _RunSkillsManagerResults on RunSkillsManagerToolUsecase {
  Map<String, Object?> _skillResult(
    String status,
    SkillEntity skill, {
    bool includeDetails = false,
  }) {
    return {
      'status': status,
      'skillId': skill.id,
      'slug': skill.slug,
      'title': skill.title,
      if (includeDetails) ..._skillDetails(skill),
    };
  }

  Map<String, Object?> _resourceResult(
    String status,
    SkillResourceEntity resource, {
    bool includeDetails = false,
  }) => {
    'status': status,
    'resourceId': resource.id,
    'skillId': resource.skillId,
    'slug': resource.slug,
    'title': resource.title,
    if (includeDetails) ...{
      'description': resource.description,
      'content': resource.content,
    },
  };
}

extension _RunSkillsManagerResultDetails on RunSkillsManagerToolUsecase {
  Map<String, Object?> _skillDetails(SkillEntity skill) => {
    'description': skill.description,
    'content': skill.content,
    'connectorToolIds': skill.connectorToolIds,
    'isEnabled': skill.isEnabled,
  };

  Map<String, Object?> _skillDeletionResult(bool deleted, SkillEntity skill) =>
      {
        'status': deleted ? 'deleted' : 'not_deleted',
        'skillId': skill.id,
        'slug': skill.slug,
      };
}

extension _RunSkillsManagerInputValidation on RunSkillsManagerToolUsecase {
  String _requiredString(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key is required.');
    }

    return value.trim();
  }

  String? _optionalString(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('$key must be a string.');

    return value.trim();
  }

  List<String>? _optionalStringList(
    Map<String, dynamic> arguments,
    String key,
  ) {
    final value = arguments[key];
    if (value == null) return null;
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('$key must be an array of strings.');
    }

    return value
        .cast<String>()
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  bool? _optionalBool(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    if (value == null) return null;
    if (value is! bool) throw FormatException('$key must be a boolean.');

    return value;
  }
}

final ProviderFamily<RunSkillsManagerToolUsecase, String>
runSkillsManagerToolUsecaseProvider =
    Provider.family<RunSkillsManagerToolUsecase, String>((ref, workspaceId) {
      final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

      return RunSkillsManagerToolUsecase(
        cloud == null ? ref.watch(skillsRepositoryProvider) : null,
        ref.watch(createSkillUsecaseProvider(workspaceId)),
        ref.watch(updateSkillUsecaseProvider(workspaceId)),
        cloudStore: cloud,
        cloneAppSkillUsecase: ref.watch(
          cloneAppSkillUsecaseProvider(workspaceId),
        ),
        resourceRepository: cloud == null
            ? ref.watch(skillResourcesRepositoryProvider)
            : null,
        createSkillResourceUsecase: ref.watch(
          createSkillResourceUsecaseProvider(workspaceId),
        ),
        updateSkillResourceUsecase: ref.watch(
          updateSkillResourceUsecaseProvider(workspaceId),
        ),
      );
    });
