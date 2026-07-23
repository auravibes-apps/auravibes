// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'select_workspace_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(selectWorkspaceUsecase)
final selectWorkspaceUsecaseProvider = SelectWorkspaceUsecaseProvider._();

final class SelectWorkspaceUsecaseProvider
    extends
        $FunctionalProvider<
          SelectWorkspaceUsecase,
          SelectWorkspaceUsecase,
          SelectWorkspaceUsecase
        >
    with $Provider<SelectWorkspaceUsecase> {
  SelectWorkspaceUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectWorkspaceUsecaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectWorkspaceUsecaseHash();

  @$internal
  @override
  $ProviderElement<SelectWorkspaceUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SelectWorkspaceUsecase create(Ref ref) {
    return selectWorkspaceUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SelectWorkspaceUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SelectWorkspaceUsecase>(value),
    );
  }
}

String _$selectWorkspaceUsecaseHash() =>
    r'994fc52db4ded05cd6a7455839ab56b5d72a8752';
