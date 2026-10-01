// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_definition_usage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(credentialDefinitionUsage)
final credentialDefinitionUsageProvider = CredentialDefinitionUsageFamily._();

final class CredentialDefinitionUsageProvider
    extends
        $FunctionalProvider<
          AsyncValue<CredentialDefinitionUsage>,
          CredentialDefinitionUsage,
          FutureOr<CredentialDefinitionUsage>
        >
    with
        $FutureModifier<CredentialDefinitionUsage>,
        $FutureProvider<CredentialDefinitionUsage> {
  CredentialDefinitionUsageProvider._({
    required CredentialDefinitionUsageFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'credentialDefinitionUsageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$credentialDefinitionUsageHash();

  @override
  String toString() {
    return r'credentialDefinitionUsageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<CredentialDefinitionUsage> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CredentialDefinitionUsage> create(Ref ref) {
    final argument = this.argument as (String, String);
    return credentialDefinitionUsage(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CredentialDefinitionUsageProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$credentialDefinitionUsageHash() =>
    r'18c866ce72d67f9dc510890464c29ac81e33382f';

final class CredentialDefinitionUsageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CredentialDefinitionUsage>,
          (String, String)
        > {
  CredentialDefinitionUsageFamily._()
    : super(
        retry: null,
        name: r'credentialDefinitionUsageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CredentialDefinitionUsageProvider call(
    String workspaceId,
    String definitionId,
  ) => CredentialDefinitionUsageProvider._(
    argument: (workspaceId, definitionId),
    from: this,
  );

  @override
  String toString() => r'credentialDefinitionUsageProvider';
}
