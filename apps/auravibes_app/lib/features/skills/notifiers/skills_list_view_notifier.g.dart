// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skills_list_view_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retains list choices across route replacement, independently per workspace.

@ProviderFor(SkillsListViewNotifier)
final skillsListViewProvider = SkillsListViewNotifierFamily._();

/// Retains list choices across route replacement, independently per workspace.
final class SkillsListViewNotifierProvider
    extends $NotifierProvider<SkillsListViewNotifier, SkillsListViewState> {
  /// Retains list choices across route replacement, independently per workspace.
  SkillsListViewNotifierProvider._({
    required SkillsListViewNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'skillsListViewProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillsListViewNotifierHash();

  @override
  String toString() {
    return r'skillsListViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SkillsListViewNotifier create() => SkillsListViewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SkillsListViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SkillsListViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SkillsListViewNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillsListViewNotifierHash() =>
    r'4b347a20e293f2e907d4038942b55135a7199168';

/// Retains list choices across route replacement, independently per workspace.

final class SkillsListViewNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SkillsListViewNotifier,
          SkillsListViewState,
          SkillsListViewState,
          SkillsListViewState,
          String
        > {
  SkillsListViewNotifierFamily._()
    : super(
        retry: null,
        name: r'skillsListViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Retains list choices across route replacement, independently per workspace.

  SkillsListViewNotifierProvider call(String workspaceId) =>
      SkillsListViewNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'skillsListViewProvider';
}

/// Retains list choices across route replacement, independently per workspace.

abstract class _$SkillsListViewNotifier extends $Notifier<SkillsListViewState> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  SkillsListViewState build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SkillsListViewState, SkillsListViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SkillsListViewState, SkillsListViewState>,
              SkillsListViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
