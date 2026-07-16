// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_credentials_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillCredentialsForDefinition)
final skillCredentialsForDefinitionProvider =
    SkillCredentialsForDefinitionFamily._();

final class SkillCredentialsForDefinitionProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SkillCredentialEntity>>,
          List<SkillCredentialEntity>,
          FutureOr<List<SkillCredentialEntity>>
        >
    with
        $FutureModifier<List<SkillCredentialEntity>>,
        $FutureProvider<List<SkillCredentialEntity>> {
  SkillCredentialsForDefinitionProvider._({
    required SkillCredentialsForDefinitionFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'skillCredentialsForDefinitionProvider',
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
  String debugGetCreateSourceHash() => _$skillCredentialsForDefinitionHash();

  @override
  String toString() {
    return r'skillCredentialsForDefinitionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<SkillCredentialEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SkillCredentialEntity>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return skillCredentialsForDefinition(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillCredentialsForDefinitionProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillCredentialsForDefinitionHash() =>
    r'31becf8fbbcf2003f1eeec91ce3caa928cc1c4f1';

final class SkillCredentialsForDefinitionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SkillCredentialEntity>>,
          (String, String)
        > {
  SkillCredentialsForDefinitionFamily._()
    : super(
        retry: null,
        name: r'skillCredentialsForDefinitionProvider',
        dependencies: <ProviderOrFamily>[cloudSkillStoreProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          SkillCredentialsForDefinitionProvider.$allTransitiveDependencies0,
          SkillCredentialsForDefinitionProvider.$allTransitiveDependencies1,
          SkillCredentialsForDefinitionProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  SkillCredentialsForDefinitionProvider call(
    String workspaceId,
    String credentialDefinitionId,
  ) => SkillCredentialsForDefinitionProvider._(
    argument: (workspaceId, credentialDefinitionId),
    from: this,
  );

  @override
  String toString() => r'skillCredentialsForDefinitionProvider';
}
