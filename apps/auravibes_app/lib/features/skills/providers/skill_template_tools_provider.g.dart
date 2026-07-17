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

  static final $allTransitiveDependencies0 = cloudSkillStoreProvider;
  static final $allTransitiveDependencies1 =
      CloudSkillStoreProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      CloudSkillStoreProvider.$allTransitiveDependencies1;

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
    r'1350e42726539d666293e6d8520a721f7a3e7d7f';

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
        dependencies: <ProviderOrFamily>[cloudSkillStoreProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          SkillTemplateToolsProvider.$allTransitiveDependencies0,
          SkillTemplateToolsProvider.$allTransitiveDependencies1,
          SkillTemplateToolsProvider.$allTransitiveDependencies2,
        ],
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

  static final $allTransitiveDependencies0 = cloudSkillStoreProvider;
  static final $allTransitiveDependencies1 =
      CloudSkillStoreProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      CloudSkillStoreProvider.$allTransitiveDependencies1;

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

String _$skillTemplateToolHash() => r'3814d2bc8990144b3e29988f304ad99b944b8a0d';

final class SkillTemplateToolFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SkillTemplateToolEntity?>, String> {
  SkillTemplateToolFamily._()
    : super(
        retry: null,
        name: r'skillTemplateToolProvider',
        dependencies: <ProviderOrFamily>[cloudSkillStoreProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          SkillTemplateToolProvider.$allTransitiveDependencies0,
          SkillTemplateToolProvider.$allTransitiveDependencies1,
          SkillTemplateToolProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  SkillTemplateToolProvider call(String toolId) =>
      SkillTemplateToolProvider._(argument: toolId, from: this);

  @override
  String toString() => r'skillTemplateToolProvider';
}
