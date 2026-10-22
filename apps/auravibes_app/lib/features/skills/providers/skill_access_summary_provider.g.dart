// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_access_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(assessSkillAccessUsecase)
final assessSkillAccessUsecaseProvider = AssessSkillAccessUsecaseFamily._();

final class AssessSkillAccessUsecaseProvider
    extends
        $FunctionalProvider<
          AssessSkillAccessUsecase,
          AssessSkillAccessUsecase,
          AssessSkillAccessUsecase
        >
    with $Provider<AssessSkillAccessUsecase> {
  AssessSkillAccessUsecaseProvider._({
    required AssessSkillAccessUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'assessSkillAccessUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$assessSkillAccessUsecaseHash();

  @override
  String toString() {
    return r'assessSkillAccessUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AssessSkillAccessUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AssessSkillAccessUsecase create(Ref ref) {
    final argument = this.argument as String;
    return assessSkillAccessUsecase(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssessSkillAccessUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssessSkillAccessUsecase>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AssessSkillAccessUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$assessSkillAccessUsecaseHash() =>
    r'3b129609f2f07d644d987184f682972c81079b08';

final class AssessSkillAccessUsecaseFamily extends $Family
    with $FunctionalFamilyOverride<AssessSkillAccessUsecase, String> {
  AssessSkillAccessUsecaseFamily._()
    : super(
        retry: null,
        name: r'assessSkillAccessUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AssessSkillAccessUsecaseProvider call(String workspaceId) =>
      AssessSkillAccessUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'assessSkillAccessUsecaseProvider';
}

@ProviderFor(skillAccessSummary)
final skillAccessSummaryProvider = SkillAccessSummaryFamily._();

final class SkillAccessSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<SkillAccessSummary?>,
          SkillAccessSummary?,
          FutureOr<SkillAccessSummary?>
        >
    with
        $FutureModifier<SkillAccessSummary?>,
        $FutureProvider<SkillAccessSummary?> {
  SkillAccessSummaryProvider._({
    required SkillAccessSummaryFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'skillAccessSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillAccessSummaryHash();

  @override
  String toString() {
    return r'skillAccessSummaryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SkillAccessSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SkillAccessSummary?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return skillAccessSummary(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SkillAccessSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillAccessSummaryHash() =>
    r'3f666a5ea4b0114f717621428ffdf60974a90daa';

final class SkillAccessSummaryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SkillAccessSummary?>,
          (String, String)
        > {
  SkillAccessSummaryFamily._()
    : super(
        retry: null,
        name: r'skillAccessSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SkillAccessSummaryProvider call(String workspaceId, String skillId) =>
      SkillAccessSummaryProvider._(
        argument: (workspaceId, skillId),
        from: this,
      );

  @override
  String toString() => r'skillAccessSummaryProvider';
}
