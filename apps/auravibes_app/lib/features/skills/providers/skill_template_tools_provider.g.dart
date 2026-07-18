// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_template_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillTemplateTools)
final skillTemplateToolsProvider = SkillTemplateToolsFamily._();

final class SkillTemplateToolsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SkillTemplateToolEntity>>,
          List<SkillTemplateToolEntity>,
          FutureOr<List<SkillTemplateToolEntity>>
        >
    with
        $FutureModifier<List<SkillTemplateToolEntity>>,
        $FutureProvider<List<SkillTemplateToolEntity>> {
  SkillTemplateToolsProvider._({
    required SkillTemplateToolsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'skillTemplateToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillTemplateToolsHash();

  @override
  String toString() {
    return r'skillTemplateToolsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<SkillTemplateToolEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SkillTemplateToolEntity>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return skillTemplateTools(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillTemplateToolsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillTemplateToolsHash() =>
    r'd45878787dfebed34bda0c50273fefde31d74104';

final class SkillTemplateToolsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SkillTemplateToolEntity>>,
          (String, String)
        > {
  SkillTemplateToolsFamily._()
    : super(
        retry: null,
        name: r'skillTemplateToolsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillTemplateToolsProvider call(String workspaceId, String skillId) =>
      SkillTemplateToolsProvider._(
        argument: (workspaceId, skillId),
        from: this,
      );

  @override
  String toString() => r'skillTemplateToolsProvider';
}

@ProviderFor(skillTemplateTool)
final skillTemplateToolProvider = SkillTemplateToolFamily._();

final class SkillTemplateToolProvider
    extends
        $FunctionalProvider<
          AsyncValue<SkillTemplateToolEntity?>,
          SkillTemplateToolEntity?,
          FutureOr<SkillTemplateToolEntity?>
        >
    with
        $FutureModifier<SkillTemplateToolEntity?>,
        $FutureProvider<SkillTemplateToolEntity?> {
  SkillTemplateToolProvider._({
    required SkillTemplateToolFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'skillTemplateToolProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillTemplateToolHash();

  @override
  String toString() {
    return r'skillTemplateToolProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SkillTemplateToolEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkillTemplateToolEntity?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return skillTemplateTool(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillTemplateToolProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillTemplateToolHash() => r'97ae19654ce0204f49fe72d3453e25a20a84aacc';

final class SkillTemplateToolFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SkillTemplateToolEntity?>,
          (String, String)
        > {
  SkillTemplateToolFamily._()
    : super(
        retry: null,
        name: r'skillTemplateToolProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillTemplateToolProvider call(String workspaceId, String toolId) =>
      SkillTemplateToolProvider._(argument: (workspaceId, toolId), from: this);

  @override
  String toString() => r'skillTemplateToolProvider';
}
