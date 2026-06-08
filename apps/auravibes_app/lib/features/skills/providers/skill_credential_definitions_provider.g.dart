// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_credential_definitions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillCredentialDefinitions)
final skillCredentialDefinitionsProvider = SkillCredentialDefinitionsFamily._();

final class SkillCredentialDefinitionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SkillCredentialDefinitionEntity>>,
          List<SkillCredentialDefinitionEntity>,
          FutureOr<List<SkillCredentialDefinitionEntity>>
        >
    with
        $FutureModifier<List<SkillCredentialDefinitionEntity>>,
        $FutureProvider<List<SkillCredentialDefinitionEntity>> {
  SkillCredentialDefinitionsProvider._({
    required SkillCredentialDefinitionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'skillCredentialDefinitionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillCredentialDefinitionsHash();

  @override
  String toString() {
    return r'skillCredentialDefinitionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SkillCredentialDefinitionEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SkillCredentialDefinitionEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return skillCredentialDefinitions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillCredentialDefinitionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillCredentialDefinitionsHash() =>
    r'a5a176138bc188b6169cb9e6f477854dc01abe4f';

final class SkillCredentialDefinitionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SkillCredentialDefinitionEntity>>,
          String
        > {
  SkillCredentialDefinitionsFamily._()
    : super(
        retry: null,
        name: r'skillCredentialDefinitionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillCredentialDefinitionsProvider call(String workspaceId) =>
      SkillCredentialDefinitionsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'skillCredentialDefinitionsProvider';
}

@ProviderFor(skillCredentialDefinition)
final skillCredentialDefinitionProvider = SkillCredentialDefinitionFamily._();

final class SkillCredentialDefinitionProvider
    extends
        $FunctionalProvider<
          AsyncValue<SkillCredentialDefinitionEntity?>,
          SkillCredentialDefinitionEntity?,
          FutureOr<SkillCredentialDefinitionEntity?>
        >
    with
        $FutureModifier<SkillCredentialDefinitionEntity?>,
        $FutureProvider<SkillCredentialDefinitionEntity?> {
  SkillCredentialDefinitionProvider._({
    required SkillCredentialDefinitionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'skillCredentialDefinitionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillCredentialDefinitionHash();

  @override
  String toString() {
    return r'skillCredentialDefinitionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SkillCredentialDefinitionEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkillCredentialDefinitionEntity?> create(Ref ref) {
    final argument = this.argument as String;
    return skillCredentialDefinition(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillCredentialDefinitionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillCredentialDefinitionHash() =>
    r'3d2e8128b7082067fcdaf29ac723f09f1f1ee9b7';

final class SkillCredentialDefinitionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SkillCredentialDefinitionEntity?>,
          String
        > {
  SkillCredentialDefinitionFamily._()
    : super(
        retry: null,
        name: r'skillCredentialDefinitionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillCredentialDefinitionProvider call(String definitionId) =>
      SkillCredentialDefinitionProvider._(argument: definitionId, from: this);

  @override
  String toString() => r'skillCredentialDefinitionProvider';
}
