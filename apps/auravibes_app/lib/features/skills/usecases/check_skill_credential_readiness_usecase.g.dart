// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_skill_credential_readiness_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkSkillCredentialReadinessUsecase)
final checkSkillCredentialReadinessUsecaseProvider =
    CheckSkillCredentialReadinessUsecaseFamily._();

final class CheckSkillCredentialReadinessUsecaseProvider
    extends
        $FunctionalProvider<
          CheckSkillCredentialReadinessUsecase,
          CheckSkillCredentialReadinessUsecase,
          CheckSkillCredentialReadinessUsecase
        >
    with $Provider<CheckSkillCredentialReadinessUsecase> {
  CheckSkillCredentialReadinessUsecaseProvider._({
    required CheckSkillCredentialReadinessUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'checkSkillCredentialReadinessUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$checkSkillCredentialReadinessUsecaseHash();

  @override
  String toString() {
    return r'checkSkillCredentialReadinessUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CheckSkillCredentialReadinessUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckSkillCredentialReadinessUsecase create(Ref ref) {
    final argument = this.argument as String;
    return checkSkillCredentialReadinessUsecase(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckSkillCredentialReadinessUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CheckSkillCredentialReadinessUsecase>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CheckSkillCredentialReadinessUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkSkillCredentialReadinessUsecaseHash() =>
    r'a6a0d38051ac77ec81f11eafdbb5e1e52c64cb9c';

final class CheckSkillCredentialReadinessUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          CheckSkillCredentialReadinessUsecase,
          String
        > {
  CheckSkillCredentialReadinessUsecaseFamily._()
    : super(
        retry: null,
        name: r'checkSkillCredentialReadinessUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CheckSkillCredentialReadinessUsecaseProvider call(String workspaceId) =>
      CheckSkillCredentialReadinessUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'checkSkillCredentialReadinessUsecaseProvider';
}
