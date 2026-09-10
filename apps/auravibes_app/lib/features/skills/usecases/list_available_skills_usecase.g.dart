// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_available_skills_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listAvailableSkillsUsecase)
final listAvailableSkillsUsecaseProvider = ListAvailableSkillsUsecaseFamily._();

final class ListAvailableSkillsUsecaseProvider
    extends
        $FunctionalProvider<
          ListAvailableSkillsUsecase,
          ListAvailableSkillsUsecase,
          ListAvailableSkillsUsecase
        >
    with $Provider<ListAvailableSkillsUsecase> {
  ListAvailableSkillsUsecaseProvider._({
    required ListAvailableSkillsUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listAvailableSkillsUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listAvailableSkillsUsecaseHash();

  @override
  String toString() {
    return r'listAvailableSkillsUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ListAvailableSkillsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ListAvailableSkillsUsecase create(Ref ref) {
    final argument = this.argument as String;
    return listAvailableSkillsUsecase(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListAvailableSkillsUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListAvailableSkillsUsecase>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ListAvailableSkillsUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listAvailableSkillsUsecaseHash() =>
    r'ba57cb81fac1db667584ebdb58b36a2bc5c1d3e9';

final class ListAvailableSkillsUsecaseFamily extends $Family
    with $FunctionalFamilyOverride<ListAvailableSkillsUsecase, String> {
  ListAvailableSkillsUsecaseFamily._()
    : super(
        retry: null,
        name: r'listAvailableSkillsUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ListAvailableSkillsUsecaseProvider call(String workspaceId) =>
      ListAvailableSkillsUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'listAvailableSkillsUsecaseProvider';
}
