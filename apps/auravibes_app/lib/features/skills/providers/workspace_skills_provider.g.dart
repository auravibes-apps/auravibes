// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_skills_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceSkills)
final workspaceSkillsProvider = WorkspaceSkillsFamily._();

final class WorkspaceSkillsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceSkill>>,
          List<WorkspaceSkill>,
          FutureOr<List<WorkspaceSkill>>
        >
    with
        $FutureModifier<List<WorkspaceSkill>>,
        $FutureProvider<List<WorkspaceSkill>> {
  WorkspaceSkillsProvider._({
    required WorkspaceSkillsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceSkillsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceSkillsHash();

  @override
  String toString() {
    return r'workspaceSkillsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceSkill>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceSkill>> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceSkills(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceSkillsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceSkillsHash() => r'56ad93852d6b749a8c30c09c0282ab5c1d98b194';

final class WorkspaceSkillsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<WorkspaceSkill>>, String> {
  WorkspaceSkillsFamily._()
    : super(
        retry: null,
        name: r'workspaceSkillsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceSkillsProvider call(String workspaceId) =>
      WorkspaceSkillsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceSkillsProvider';
}
