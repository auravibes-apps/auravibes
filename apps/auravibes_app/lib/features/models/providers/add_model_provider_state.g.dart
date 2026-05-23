// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_model_provider_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddModelProviderState)
final addModelProviderStateProvider = AddModelProviderStateFamily._();

final class AddModelProviderStateProvider
    extends $NotifierProvider<AddModelProviderState, AddModelProviderModel> {
  AddModelProviderStateProvider._({
    required AddModelProviderStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addModelProviderStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addModelProviderStateHash();

  @override
  String toString() {
    return r'addModelProviderStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AddModelProviderState create() => AddModelProviderState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddModelProviderModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddModelProviderModel>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AddModelProviderStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addModelProviderStateHash() =>
    r'258c972c525bbbf96d3ca245e4142ef5d19bb39d';

final class AddModelProviderStateFamily extends $Family
    with
        $ClassFamilyOverride<
          AddModelProviderState,
          AddModelProviderModel,
          AddModelProviderModel,
          AddModelProviderModel,
          String
        > {
  AddModelProviderStateFamily._()
    : super(
        retry: null,
        name: r'addModelProviderStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AddModelProviderStateProvider call(String workspaceId) =>
      AddModelProviderStateProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'addModelProviderStateProvider';
}

abstract class _$AddModelProviderState
    extends $Notifier<AddModelProviderModel> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  AddModelProviderModel build(String workspaceId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddModelProviderModel, AddModelProviderModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddModelProviderModel, AddModelProviderModel>,
              AddModelProviderModel,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
