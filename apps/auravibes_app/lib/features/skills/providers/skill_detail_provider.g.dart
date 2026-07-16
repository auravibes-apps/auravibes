// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillDetail)
final skillDetailProvider = SkillDetailFamily._();

final class SkillDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SkillDetail?>,
          SkillDetail?,
          FutureOr<SkillDetail?>
        >
    with $FutureModifier<SkillDetail?>, $FutureProvider<SkillDetail?> {
  SkillDetailProvider._({
    required SkillDetailFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'skillDetailProvider',
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
  String debugGetCreateSourceHash() => _$skillDetailHash();

  @override
  String toString() {
    return r'skillDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SkillDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkillDetail?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return skillDetail(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillDetailHash() => r'af294758ecb610c302b4163652db618114a2d469';

final class SkillDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SkillDetail?>, (String, String)> {
  SkillDetailFamily._()
    : super(
        retry: null,
        name: r'skillDetailProvider',
        dependencies: <ProviderOrFamily>[cloudSkillStoreProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          SkillDetailProvider.$allTransitiveDependencies0,
          SkillDetailProvider.$allTransitiveDependencies1,
          SkillDetailProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  SkillDetailProvider call(String workspaceId, String skillId) =>
      SkillDetailProvider._(argument: (workspaceId, skillId), from: this);

  @override
  String toString() => r'skillDetailProvider';
}
