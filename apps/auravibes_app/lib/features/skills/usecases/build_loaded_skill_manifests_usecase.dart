import 'dart:convert';

import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:crypto/crypto.dart';
import 'package:riverpod/riverpod.dart';

class BuildLoadedSkillManifestsUsecase {
  const BuildLoadedSkillManifestsUsecase(
    this._listAvailableSkillsUsecase,
    this._buildSkillTemplateToolSpecsUsecase,
    this._buildAppSkillNativeToolSpecsUsecase,
  );

  final ListAvailableSkillsUsecase Function(String workspaceId)
  _listAvailableSkillsUsecase;
  final BuildSkillTemplateToolSpecsUsecase _buildSkillTemplateToolSpecsUsecase;
  final BuildAppSkillNativeToolSpecsUsecase
  _buildAppSkillNativeToolSpecsUsecase;

  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );
    final identities = <String>{};
    final skills = [
      ...loadedSkills,
      ...extraSkills,
    ].where((skill) => identities.add(_identity(skill))).toList();
    final specs = [
      ...await _buildSkillTemplateToolSpecsUsecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        extraSkills: extraSkills,
      ),
      ...await _buildAppSkillNativeToolSpecsUsecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        extraSkills: extraSkills,
      ),
    ];
    final toolsBySlug = <String, List<SkillManifestTool>>{};
    const resolver = AgentToolNameResolver();
    for (final spec in specs) {
      final resolved = resolver.resolve(spec.name);
      if (resolved == null || !resolved.isSkill) continue;
      final skillSlug = resolved.skillSlug;
      if (skillSlug == null) continue;
      toolsBySlug
          .putIfAbsent(skillSlug, () => [])
          .add(
            SkillManifestTool(
              name: resolved.toolIdentifier,
              description: spec.description,
              inputJsonSchema: spec.inputJsonSchema,
            ),
          );
    }

    return [
      for (final skill in skills)
        _manifest(skill, toolsBySlug[skill.slug] ?? <SkillManifestTool>[]),
    ]..sort((left, right) => left.slug.compareTo(right.slug));
  }

  SkillManifest _manifest(
    AvailableSkill skill,
    List<SkillManifestTool> tools,
  ) {
    tools.sort((left, right) => left.name.compareTo(right.name));
    final revision = sha256
        .convert(
          utf8.encode(
            jsonEncode(
              _canonicalJson({
                'identity': _identity(skill),
                'slug': skill.slug,
                'title': skill.title,
                'instructions': skill.content,
                'tools': [for (final tool in tools) tool.toJson()],
              }),
            ),
          ),
        )
        .toString();

    return SkillManifest(
      slug: skill.slug,
      title: skill.title,
      instructions: skill.content,
      revision: revision,
      tools: tools,
    );
  }

  String _identity(AvailableSkill skill) => '${skill.source.name}:${skill.id}';
}

Object? _canonicalJson(Object? value) => switch (value) {
  final Map<Object?, Object?> map => {
    for (final key in map.keys.cast<String>().toList()..sort())
      key: _canonicalJson(map[key]),
  },
  final Iterable<Object?> values => [
    for (final value in values) _canonicalJson(value),
  ],
  _ => value,
};

final buildLoadedSkillManifestsUsecaseProvider =
    Provider<BuildLoadedSkillManifestsUsecase>((ref) {
      return BuildLoadedSkillManifestsUsecase(
        (workspaceId) =>
            ref.watch(listAvailableSkillsUsecaseProvider(workspaceId)),
        ref.watch(buildSkillTemplateToolSpecsUsecaseProvider),
        ref.watch(buildAppSkillNativeToolSpecsUsecaseProvider),
      );
    });
