// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_workspace_name_use_case.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [ValidateWorkspaceNameUseCase] instance.

@ProviderFor(validateWorkspaceNameUseCase)
final validateWorkspaceNameUseCaseProvider =
    ValidateWorkspaceNameUseCaseProvider._();

/// Provides a [ValidateWorkspaceNameUseCase] instance.

final class ValidateWorkspaceNameUseCaseProvider
    extends
        $FunctionalProvider<
          ValidateWorkspaceNameUseCase,
          ValidateWorkspaceNameUseCase,
          ValidateWorkspaceNameUseCase
        >
    with $Provider<ValidateWorkspaceNameUseCase> {
  /// Provides a [ValidateWorkspaceNameUseCase] instance.
  ValidateWorkspaceNameUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'validateWorkspaceNameUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$validateWorkspaceNameUseCaseHash();

  @$internal
  @override
  $ProviderElement<ValidateWorkspaceNameUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ValidateWorkspaceNameUseCase create(Ref ref) {
    return validateWorkspaceNameUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ValidateWorkspaceNameUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ValidateWorkspaceNameUseCase>(value),
    );
  }
}

String _$validateWorkspaceNameUseCaseHash() =>
    r'6652bcd7822a7e97a1216be67faed8b9778bb983';
