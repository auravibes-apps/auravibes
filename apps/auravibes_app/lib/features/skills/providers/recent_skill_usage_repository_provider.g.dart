// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_skill_usage_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentSkillUsageRepository)
final recentSkillUsageRepositoryProvider =
    RecentSkillUsageRepositoryProvider._();

final class RecentSkillUsageRepositoryProvider
    extends
        $FunctionalProvider<
          RecentSkillUsageRepository,
          RecentSkillUsageRepository,
          RecentSkillUsageRepository
        >
    with $Provider<RecentSkillUsageRepository> {
  RecentSkillUsageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSkillUsageRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSkillUsageRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecentSkillUsageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentSkillUsageRepository create(Ref ref) {
    return recentSkillUsageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentSkillUsageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentSkillUsageRepository>(value),
    );
  }
}

String _$recentSkillUsageRepositoryHash() =>
    r'205cc1bd63709441ffd9ab51e03df1aae5f07b32';
