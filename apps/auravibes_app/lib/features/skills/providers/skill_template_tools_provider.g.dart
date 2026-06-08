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
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SkillTemplateToolEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SkillTemplateToolEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return skillTemplateTools(ref, argument);
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
    r'c4d77eaa16fe5b1e5c853aec50824e80e69f0914';

final class SkillTemplateToolsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SkillTemplateToolEntity>>,
          String
        > {
  SkillTemplateToolsFamily._()
    : super(
        retry: null,
        name: r'skillTemplateToolsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillTemplateToolsProvider call(String skillId) =>
      SkillTemplateToolsProvider._(argument: skillId, from: this);

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
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SkillTemplateToolEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkillTemplateToolEntity?> create(Ref ref) {
    final argument = this.argument as String;
    return skillTemplateTool(ref, argument);
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

String _$skillTemplateToolHash() => r'02acc1ba17be393e767e51baae650c0ad876d98c';

final class SkillTemplateToolFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SkillTemplateToolEntity?>, String> {
  SkillTemplateToolFamily._()
    : super(
        retry: null,
        name: r'skillTemplateToolProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillTemplateToolProvider call(String toolId) =>
      SkillTemplateToolProvider._(argument: toolId, from: this);

  @override
  String toString() => r'skillTemplateToolProvider';
}
