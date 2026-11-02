// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_appearance_profile_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appAppearanceProfileUsecase)
final appAppearanceProfileUsecaseProvider =
    AppAppearanceProfileUsecaseProvider._();

final class AppAppearanceProfileUsecaseProvider
    extends
        $FunctionalProvider<
          AppAppearanceProfileUsecase,
          AppAppearanceProfileUsecase,
          AppAppearanceProfileUsecase
        >
    with $Provider<AppAppearanceProfileUsecase> {
  AppAppearanceProfileUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appAppearanceProfileUsecaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appAppearanceProfileUsecaseHash();

  @$internal
  @override
  $ProviderElement<AppAppearanceProfileUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppAppearanceProfileUsecase create(Ref ref) {
    return appAppearanceProfileUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAppearanceProfileUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAppearanceProfileUsecase>(value),
    );
  }
}

String _$appAppearanceProfileUsecaseHash() =>
    r'54694dbaf9049757bb2d1a288b78ec4dd1b075f8';
