// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_resources_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillResources)
final skillResourcesProvider = SkillResourcesFamily._();

final class SkillResourcesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SkillResourceEntity>>,
          List<SkillResourceEntity>,
          FutureOr<List<SkillResourceEntity>>
        >
    with
        $FutureModifier<List<SkillResourceEntity>>,
        $FutureProvider<List<SkillResourceEntity>> {
  SkillResourcesProvider._({
    required SkillResourcesFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'skillResourcesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillResourcesHash();

  @override
  String toString() {
    return r'skillResourcesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<SkillResourceEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SkillResourceEntity>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return skillResources(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillResourcesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillResourcesHash() => r'116aa3e9608bd8abd3d957685fd05eae618bf70a';

final class SkillResourcesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SkillResourceEntity>>,
          (String, String)
        > {
  SkillResourcesFamily._()
    : super(
        retry: null,
        name: r'skillResourcesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillResourcesProvider call(String workspaceId, String skillId) =>
      SkillResourcesProvider._(argument: (workspaceId, skillId), from: this);

  @override
  String toString() => r'skillResourcesProvider';
}

@ProviderFor(skillResource)
final skillResourceProvider = SkillResourceFamily._();

final class SkillResourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<SkillResourceEntity?>,
          SkillResourceEntity?,
          FutureOr<SkillResourceEntity?>
        >
    with
        $FutureModifier<SkillResourceEntity?>,
        $FutureProvider<SkillResourceEntity?> {
  SkillResourceProvider._({
    required SkillResourceFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'skillResourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillResourceHash();

  @override
  String toString() {
    return r'skillResourceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SkillResourceEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkillResourceEntity?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return skillResource(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillResourceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillResourceHash() => r'150a727cc05277948d9717cf8bb1655a01290672';

final class SkillResourceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SkillResourceEntity?>,
          (String, String)
        > {
  SkillResourceFamily._()
    : super(
        retry: null,
        name: r'skillResourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillResourceProvider call(String workspaceId, String resourceId) =>
      SkillResourceProvider._(argument: (workspaceId, resourceId), from: this);

  @override
  String toString() => r'skillResourceProvider';
}
