import 'package:auravibes_app/data/repositories/app_skill_workspace_settings_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_app/features/skills/usecases/check_skill_credential_readiness_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_available_skills_usecase.g.dart';

class const ListAvailableSkillsUsecase(
  final SkillsRepository? _skillsRepository,
  final ConversationSkillsRepository? _conversationSkillsRepository,
  final AppSkillWorkspaceSettingsRepository? _appSkillSettingsRepository,
  final AppSkillRegistry _appSkillRegistry, [
  final CheckSkillCredentialReadinessUsecase?
  _checkSkillCredentialReadinessUsecase,
  final ListAppSkillCredentialCandidatesUsecase?
  _listAppSkillCredentialCandidatesUsecase,
  final CloudSkillStore? cloudStore,
]);

typedef _UserSkillListRequest = ({
  CloudSkillStore? cloud,
  List<SkillEntity> userSkills,
  Set<String> loadedUserIds,
  String workspaceId,
  SkillLoadFilter filter,
});

typedef _UserSkillAvailabilityRequest = ({
  CloudSkillStore? cloud,
  SkillEntity skill,
  Set<String> loadedUserIds,
  String workspaceId,
  SkillLoadFilter filter,
});

typedef _AppSkillAvailabilityRequest = ({
  CloudSkillStore? cloud,
  AppSkillDefinition skill,
  Set<String> loadedAppIds,
  String workspaceId,
  SkillLoadFilter filter,
});

typedef _LoadedSkillInputs = ({
  List<SkillEntity> userSkills,
  Set<String> loadedUserIds,
  Set<String> loadedAppIds,
});

typedef _AvailableSkillsRequest = ({
  CloudSkillStore? cloud,
  _LoadedSkillInputs inputs,
  String workspaceId,
  SkillLoadFilter filter,
});

typedef _LocalSkillDependencies = ({
  SkillsRepository skillsRepository,
  ConversationSkillsRepository conversationSkillsRepository,
  AppSkillWorkspaceSettingsRepository appSkillSettingsRepository,
});

typedef _SharedSkillDependencies = ({
  AppSkillRegistry appSkillRegistry,
  CheckSkillCredentialReadinessUsecase? credentialReadiness,
  ListAppSkillCredentialCandidatesUsecase? credentialCandidates,
});

typedef _ListAvailableSkillsProviderRequest = ({
  CloudSkillStore? cloud,
  _LocalSkillDependencies? local,
  _SharedSkillDependencies shared,
});

extension ListAvailableSkillsUsecaseCall on ListAvailableSkillsUsecase {
  ConversationSkillsRepository get _requiredConversationSkillsRepository {
    final repository = _conversationSkillsRepository;
    if (repository == null) {
      throw StateError('Conversation skill store is unavailable');
    }

    return repository;
  }

  AppSkillWorkspaceSettingsRepository get _requiredAppSkillSettingsRepository {
    final repository = _appSkillSettingsRepository;
    if (repository == null) {
      throw StateError('App skill settings store is unavailable');
    }

    return repository;
  }

  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final cloud = cloudStore;
    final inputs = await _loadInputs(cloud, conversationId, workspaceId);

    return await _collectAvailableSkills((
      cloud: cloud,
      inputs: inputs,
      workspaceId: workspaceId,
      filter: filter,
    ));
  }

  Future<_LoadedSkillInputs> _loadInputs(
    CloudSkillStore? cloud,
    String conversationId,
    String workspaceId,
  ) async {
    final userSkills = await _loadUserSkills(cloud, workspaceId);
    final conversationSkills = await _loadConversationSkills(
      cloud,
      conversationId,
    );
    final cloudSelections = await _loadCloudSelections(cloud, conversationId);

    return _loadedSkillInputs(
      userSkills: userSkills,
      conversationSkills: conversationSkills,
      cloudSelections: cloudSelections,
    );
  }

  _LoadedSkillInputs _loadedSkillInputs({
    required List<SkillEntity> userSkills,
    required List<ConversationSkillEntity> conversationSkills,
    required List<({String skillId})> cloudSelections,
  }) {
    final loadedUserSkillIds = conversationSkills.loadedUserSkillIds;
    final loadedAppSkillIdentifiers =
        conversationSkills.loadedAppSkillIdentifiers;
    final selectedSkillIds = cloudSelections.map((item) => item.skillId);

    return (
      userSkills: userSkills,
      loadedUserIds: {...loadedUserSkillIds, ...selectedSkillIds},
      loadedAppIds: {...loadedAppSkillIdentifiers, ...selectedSkillIds},
    );
  }

  Future<List<AvailableSkill>> _collectAvailableSkills(
    _AvailableSkillsRequest request,
  ) async {
    final userSkills = await _collectAvailableUserSkills(request);
    final appSkills = await _collectAvailableAppSkills(request);

    return [...userSkills, ...appSkills];
  }

  Future<List<AvailableSkill>> _collectAvailableUserSkills(
    _AvailableSkillsRequest request,
  ) => _collectUserSkills((
    cloud: request.cloud,
    userSkills: request.inputs.userSkills,
    loadedUserIds: request.inputs.loadedUserIds,
    workspaceId: request.workspaceId,
    filter: request.filter,
  ));

  Future<List<AvailableSkill>> _collectAvailableAppSkills(
    _AvailableSkillsRequest request,
  ) => _listAppSkills(request);
}

extension ListAvailableSkillsUsecaseLoading on ListAvailableSkillsUsecase {
  Future<List<SkillEntity>> _loadUserSkills(
    CloudSkillStore? cloud,
    String workspaceId,
  ) async {
    return switch ((cloud: cloud, repository: _skillsRepository)) {
      (cloud: final cloud?, repository: _) => await cloud.skills(),
      (cloud: _, repository: final repository?) =>
        await repository.getWorkspaceSkills(workspaceId),
      _ => throw StateError('Skill store is unavailable'),
    };
  }

  Future<List<ConversationSkillEntity>> _loadConversationSkills(
    CloudSkillStore? cloud,
    String conversationId,
  ) async {
    if (cloud != null) return const [];

    return await _requiredConversationSkillsRepository.getConversationSkills(
      conversationId,
    );
  }

  Future<List<({String skillId})>> _loadCloudSelections(
    CloudSkillStore? cloud,
    String conversationId,
  ) async {
    if (cloud == null) return const [];

    return await cloud.selectionResources(conversationId);
  }
}

extension ListAvailableSkillsUsecaseUserSkills on ListAvailableSkillsUsecase {
  Future<List<AvailableSkill>> _collectUserSkills(
    _UserSkillListRequest request,
  ) async {
    final result = <AvailableSkill>[];
    for (final skill in request.userSkills.where(_isUserSkill)) {
      await _addUserSkill(request, result, skill);
    }

    return result;
  }

  Future<void> _addUserSkill(
    _UserSkillListRequest request,
    List<AvailableSkill> result,
    SkillEntity skill,
  ) => _addAvailableUserSkill((
    cloud: request.cloud,
    skill: skill,
    loadedUserIds: request.loadedUserIds,
    workspaceId: request.workspaceId,
    filter: request.filter,
    result: result,
  ));

  bool _isUserSkill(SkillEntity skill) => skill.source == SkillSource.user;

  Future<void> _addAvailableUserSkill(
    ({
      CloudSkillStore? cloud,
      SkillEntity skill,
      Set<String> loadedUserIds,
      String workspaceId,
      SkillLoadFilter filter,
      List<AvailableSkill> result,
    })
    request,
  ) async {
    final availableSkill = await _toAvailableUserSkill((
      cloud: request.cloud,
      skill: request.skill,
      loadedUserIds: request.loadedUserIds,
      workspaceId: request.workspaceId,
      filter: request.filter,
    ));
    if (availableSkill != null) request.result.add(availableSkill);
  }

  Future<AvailableSkill?> _toAvailableUserSkill(
    _UserSkillAvailabilityRequest request,
  ) async {
    final skill = request.skill;
    if (!skill.isEnabled) return null;

    final isLoaded = request.loadedUserIds.contains(skill.id);
    if (!await _isUserSkillAvailable(request, isLoaded)) return null;

    return skill.toAvailableSkill();
  }

  Future<bool> _isUserSkillAvailable(
    _UserSkillAvailabilityRequest request,
    bool isLoaded,
  ) async {
    final isCredentialReady = await _isUserSkillCredentialReady(
      request,
      isLoaded,
    );

    return _isUserSkillLoadable(request.skill, isLoaded, isCredentialReady) &&
        request.filter.matches(isLoaded: isLoaded);
  }

  bool _isUserSkillLoadable(
    SkillEntity skill,
    bool isLoaded,
    bool isCredentialReady,
  ) =>
      isLoaded ||
      isSkillLoadable(
        isEnabled: skill.isEnabled,
        isLoaded: isLoaded,
        isCredentialReady: isCredentialReady,
      );

  Future<bool> _isUserSkillCredentialReady(
    _UserSkillAvailabilityRequest request,
    bool isLoaded,
  ) {
    final cloud = request.cloud;
    if (cloud != null) {
      return cloud.userSkillReady(request.skill);
    }

    return isLoaded
        ? Future.value(true)
        : _isCredentialReady(request.workspaceId, request.skill);
  }
}

extension ListAvailableSkillsUsecaseAppSkills on ListAvailableSkillsUsecase {
  Future<List<AvailableSkill>> _listAppSkills(
    _AvailableSkillsRequest request,
  ) async {
    final result = <AvailableSkill>[];
    for (final skill in _appSkillRegistry.getAll()) {
      final availableSkill = await _availableAppSkillForRequest(request, skill);
      if (availableSkill == null) continue;

      result.add(availableSkill);
    }

    return result;
  }

  Future<AvailableSkill?> _availableAppSkillForRequest(
    _AvailableSkillsRequest request,
    AppSkillDefinition skill,
  ) => _toAvailableAppSkill((
    cloud: request.cloud,
    skill: skill,
    loadedAppIds: request.inputs.loadedAppIds,
    workspaceId: request.workspaceId,
    filter: request.filter,
  ));

  Future<AvailableSkill?> _toAvailableAppSkill(
    _AppSkillAvailabilityRequest request,
  ) async {
    if (!await _isAppSkillEnabled(
      request.cloud,
      request.workspaceId,
      request.skill,
    )) {
      return null;
    }

    final isLoaded = request.loadedAppIds.contains(request.skill.identifier);
    if (!await _isAppSkillAvailable(request, isLoaded)) return null;

    return _availableAppSkill(request.skill);
  }

  Future<bool> _isAppSkillAvailable(
    _AppSkillAvailabilityRequest request,
    bool isLoaded,
  ) async {
    final hasUsableTool = await _hasUsableAppSkillToolForRuntime(
      request.cloud,
      request.workspaceId,
      request.skill,
    );

    return _isAppSkillLoadable(isLoaded, hasUsableTool) &&
        request.filter.matches(isLoaded: isLoaded);
  }

  Future<bool> _isAppSkillEnabled(
    CloudSkillStore? cloud,
    String workspaceId,
    AppSkillDefinition skill,
  ) {
    if (cloud != null) return cloud.isAppSkillEnabled(skill.identifier);

    return _requiredAppSkillSettingsRepository.isAppSkillEnabled(
      workspaceId,
      skill.identifier,
    );
  }

  Future<bool> _hasUsableAppSkillToolForRuntime(
    CloudSkillStore? cloud,
    String workspaceId,
    AppSkillDefinition skill,
  ) => cloud == null
      ? _hasLocallyUsableAppSkillTool(workspaceId, skill)
      : _hasUsableAppSkillTool(workspaceId, skill);
}

extension ListAvailableSkillsAppSupport on ListAvailableSkillsUsecase {
  bool _isAppSkillLoadable(bool isLoaded, bool hasUsableTool) =>
      isLoaded || hasUsableTool;

  AvailableSkill _availableAppSkill(AppSkillDefinition skill) => AvailableSkill(
    source: SkillSource.app,
    id: skill.identifier,
    slug: skill.slug,
    title: skill.title,
    description: skill.description,
    content: skill.content,
    kind: .native,
  );

  Future<bool> _isCredentialReady(String workspaceId, SkillEntity skill) {
    final usecase = _checkSkillCredentialReadinessUsecase;
    if (usecase == null) return Future.value(true);

    return usecase.call(workspaceId: workspaceId, skill: skill);
  }

  Future<bool> _hasLocallyUsableAppSkillTool(
    String workspaceId,
    AppSkillDefinition skill,
  ) async {
    final usecase = _listAppSkillCredentialCandidatesUsecase;
    if (usecase == null ||
        skill.nativeTools.any((tool) => !tool.requiresCredential) ||
        !usecase.isCredentialRequired(skill)) {
      return true;
    }

    return (await usecase.call(
      workspaceId: workspaceId,
      skill: skill,
    )).isNotEmpty;
  }

  Future<bool> _hasUsableAppSkillTool(
    String workspaceId,
    AppSkillDefinition skill,
  ) {
    final usecase = _listAppSkillCredentialCandidatesUsecase;
    if (usecase == null) return Future.value(true);

    return usecase.hasUsableNativeTool(workspaceId: workspaceId, skill: skill);
  }
}

@riverpod
ListAvailableSkillsUsecase listAvailableSkillsUsecase(
  Ref ref,
  String workspaceId,
) {
  return _buildListAvailableSkillsUsecase(
    _listAvailableSkillsProviderRequest(ref, workspaceId),
  );
}

_ListAvailableSkillsProviderRequest _listAvailableSkillsProviderRequest(
  Ref ref,
  String workspaceId,
) {
  final cloud = ref.watch(cloudSkillStoreProvider(workspaceId));

  return (
    cloud: cloud,
    local: cloud == null ? _localSkillDependencies(ref) : null,
    shared: _sharedSkillDependencies(ref, workspaceId),
  );
}

ListAvailableSkillsUsecase _buildListAvailableSkillsUsecase(
  _ListAvailableSkillsProviderRequest request,
) {
  final local = request.local;
  final shared = request.shared;

  return ListAvailableSkillsUsecase(
    local?.skillsRepository,
    local?.conversationSkillsRepository,
    local?.appSkillSettingsRepository,
    shared.appSkillRegistry,
    shared.credentialReadiness,
    shared.credentialCandidates,
    request.cloud,
  );
}

_LocalSkillDependencies _localSkillDependencies(Ref ref) => (
  skillsRepository: ref.watch(skillsRepositoryProvider),
  conversationSkillsRepository: ref.watch(conversationSkillsRepositoryProvider),
  appSkillSettingsRepository: ref.watch(
    appSkillWorkspaceSettingsRepositoryProvider,
  ),
);

_SharedSkillDependencies _sharedSkillDependencies(
  Ref ref,
  String workspaceId,
) => (
  appSkillRegistry: ref.watch(appSkillRegistryProvider),
  credentialReadiness: ref.watch(
    checkSkillCredentialReadinessUsecaseProvider(workspaceId),
  ),
  credentialCandidates: ref.watch(
    listAppSkillCredentialCandidatesUsecaseProvider,
  ),
);

enum SkillLoadFilter {
  loadable,
  loaded;

  bool matches({required bool isLoaded}) {
    return switch (this) {
      .loadable => !isLoaded,
      .loaded => isLoaded,
    };
  }
}

extension on List<ConversationSkillEntity> {
  Set<String> get loadedUserSkillIds {
    return where((skill) => skill.isLoaded)
        .map((skill) => skill.workspaceSkillId)
        .nonNulls
        .toSet();
  }

  Set<String> get loadedAppSkillIdentifiers {
    return where((skill) => skill.isLoaded)
        .map((skill) => skill.appSkillIdentifier)
        .nonNulls
        .toSet();
  }
}

extension on SkillEntity {
  AvailableSkill toAvailableSkill() {
    return AvailableSkill(
      source: source,
      id: id,
      slug: slug,
      title: title,
      description: description,
      content: content,
      kind: kind,
      isCredentialOptional: isCredentialOptional,
      credentialDefinitionId: credentialDefinitionId,
    );
  }
}
