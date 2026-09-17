// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_model_selections_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecentModelSelectionsNotifier)
final recentModelSelectionsProvider = RecentModelSelectionsNotifierFamily._();

final class RecentModelSelectionsNotifierProvider
    extends
        $AsyncNotifierProvider<RecentModelSelectionsNotifier, List<String>> {
  RecentModelSelectionsNotifierProvider._({
    required RecentModelSelectionsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recentModelSelectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentModelSelectionsNotifierHash();

  @override
  String toString() {
    return r'recentModelSelectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecentModelSelectionsNotifier create() => RecentModelSelectionsNotifier();

  @override
  bool operator ==(Object other) {
    return other is RecentModelSelectionsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentModelSelectionsNotifierHash() =>
    r'66e17da28b68f2f4e2d6fd7662b9ec426dcdc75f';

final class RecentModelSelectionsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RecentModelSelectionsNotifier,
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>,
          String
        > {
  RecentModelSelectionsNotifierFamily._()
    : super(
        retry: null,
        name: r'recentModelSelectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecentModelSelectionsNotifierProvider call(String workspaceId) =>
      RecentModelSelectionsNotifierProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'recentModelSelectionsProvider';
}

abstract class _$RecentModelSelectionsNotifier
    extends $AsyncNotifier<List<String>> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  FutureOr<List<String>> build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
