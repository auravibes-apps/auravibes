import 'dart:convert';

import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:crypto/crypto.dart';
import 'package:riverpod/riverpod.dart';

class const BuildLoadedSkillManifestsUsecase(
  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase,
  final BuildSkillTemplateToolSpecsUsecase _buildSkillTemplateToolSpecsUsecase,
  final BuildAppSkillNativeToolSpecsUsecase
  _buildAppSkillNativeToolSpecsUsecase,
) {
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    final skills = await _loadedSkills(
      conversationId: conversationId,
      workspaceId: workspaceId,
      extraSkills: extraSkills,
    );
    final specs = await _toolSpecs(
      conversationId: conversationId,
      workspaceId: workspaceId,
      extraSkills: extraSkills,
    );

    return _manifests(skills, _toolsBySlug(specs));
  }
}

extension on BuildLoadedSkillManifestsUsecase {
  List<SkillManifest> _manifests(
    List<AvailableSkill> skills,
    Map<String, List<SkillManifestTool>> toolsBySlug,
  ) {
    return _sortManifests(_manifestList(skills, toolsBySlug));
  }

  List<SkillManifest> _manifestList(
    List<AvailableSkill> skills,
    Map<String, List<SkillManifestTool>> toolsBySlug,
  ) => [
    for (final skill in skills)
      _manifest(skill, toolsBySlug[skill.slug] ?? <SkillManifestTool>[]),
  ];

  List<SkillManifest> _sortManifests(List<SkillManifest> manifests) {
    manifests.sort((left, right) => left.slug.compareTo(right.slug));

    return manifests;
  }

  Future<List<AvailableSkill>> _loadedSkills({
    required String conversationId,
    required String workspaceId,
    required List<AvailableSkill> extraSkills,
  }) async {
    final loadedSkills = await _loadLoadedSkills(conversationId, workspaceId);
    return _uniqueSkills(loadedSkills, extraSkills);
  }

  Future<List<AvailableSkill>> _loadLoadedSkills(
    String conversationId,
    String workspaceId,
  ) => _listAvailableSkillsUsecase(workspaceId).call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: .loaded,
  );

  List<AvailableSkill> _uniqueSkills(
    List<AvailableSkill> loadedSkills,
    List<AvailableSkill> extraSkills,
  ) {
    final identities = <String>{};

    return [
      ...loadedSkills,
      ...extraSkills,
    ].where((skill) => identities.add(_identity(skill))).toList();
  }

  Future<List<ToolSpec>> _toolSpecs({
    required String conversationId,
    required String workspaceId,
    required List<AvailableSkill> extraSkills,
  }) async {
    final templateSpecs = await _templateToolSpecs(
      conversationId: conversationId,
      workspaceId: workspaceId,
      extraSkills: extraSkills,
    );
    final nativeSpecs = await _nativeToolSpecs(
      conversationId: conversationId,
      workspaceId: workspaceId,
      extraSkills: extraSkills,
    );

    return [...templateSpecs, ...nativeSpecs];
  }

  Future<List<ToolSpec>> _templateToolSpecs({
    required String conversationId,
    required String workspaceId,
    required List<AvailableSkill> extraSkills,
  }) => _buildSkillTemplateToolSpecsUsecase.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    extraSkills: extraSkills,
  );

  Future<List<ToolSpec>> _nativeToolSpecs({
    required String conversationId,
    required String workspaceId,
    required List<AvailableSkill> extraSkills,
  }) => _buildAppSkillNativeToolSpecsUsecase.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    extraSkills: extraSkills,
  );

  Map<String, List<SkillManifestTool>> _toolsBySlug(List<ToolSpec> specs) {
    final toolsBySlug = <String, List<SkillManifestTool>>{};
    const resolver = AgentToolNameResolver();
    for (final spec in specs) {
      final tool = _manifestTool(resolver, spec);
      if (tool == null) continue;
      toolsBySlug.putIfAbsent(tool.skillSlug, () => []).add(tool.tool);
    }

    return toolsBySlug;
  }

  ({String skillSlug, SkillManifestTool tool})? _manifestTool(
    AgentToolNameResolver resolver,
    ToolSpec spec,
  ) {
    final resolved = resolver.resolve(spec.name);
    if (resolved == null || !resolved.isSkill) return null;
    final skillSlug = resolved.skillSlug;
    if (skillSlug == null) return null;

    return _manifestToolValue(resolved, spec, skillSlug);
  }

  ({String skillSlug, SkillManifestTool tool}) _manifestToolValue(
    AgentResolvedToolName resolved,
    ToolSpec spec,
    String skillSlug,
  ) => (
    skillSlug: skillSlug,
    tool: SkillManifestTool(
      name: resolved.toolIdentifier,
      description: spec.description,
      inputJsonSchema: spec.inputJsonSchema,
    ),
  );

  SkillManifest _manifest(AvailableSkill skill, List<SkillManifestTool> tools) {
    final sortedTools = _sortedTools(tools);

    return _buildManifest(skill, sortedTools);
  }

  SkillManifest _buildManifest(
    AvailableSkill skill,
    List<SkillManifestTool> tools,
  ) {
    return SkillManifest(
      slug: skill.slug,
      title: skill.title,
      instructions: skill.content,
      revision: _manifestRevision(skill, tools),
      tools: tools,
    );
  }

  List<SkillManifestTool> _sortedTools(List<SkillManifestTool> tools) {
    tools.sort((left, right) => left.name.compareTo(right.name));

    return tools;
  }
}

extension on BuildLoadedSkillManifestsUsecase {
  String _manifestRevision(
    AvailableSkill skill,
    List<SkillManifestTool> tools,
  ) => sha256
      .convert(utf8.encode(jsonEncode(_manifestPayload(skill, tools))))
      .toString();

  Map<String, Object?> _manifestPayload(
    AvailableSkill skill,
    List<SkillManifestTool> tools,
  ) =>
      _canonicalJson({
            'identity': _identity(skill),
            'slug': skill.slug,
            'title': skill.title,
            'instructions': skill.content,
            'tools': [for (final tool in tools) tool.toJson()],
          })!
          as Map<String, Object?>;

  String _identity(AvailableSkill skill) => '${skill.source.name}:${skill.id}';
}

Object? _canonicalJson(Object? value) => switch (value) {
  final Map<Object?, Object?> map => _canonicalMap(map),
  final Iterable<Object?> values => _canonicalList(values),
  _ => value,
};

Map<String, Object?> _canonicalMap(Map<Object?, Object?> map) {
  final keys = map.keys.cast<String>().toList()..sort();

  return {for (final key in keys) key: _canonicalJson(map[key])};
}

List<Object?> _canonicalList(Iterable<Object?> values) => [
  for (final value in values) _canonicalJson(value),
];

final buildLoadedSkillManifestsUsecaseProvider =
    Provider<BuildLoadedSkillManifestsUsecase>((ref) {
      return BuildLoadedSkillManifestsUsecase(
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
        ref.watch(buildSkillTemplateToolSpecsUsecaseProvider),
        ref.watch(buildAppSkillNativeToolSpecsUsecaseProvider),
      );
    });
