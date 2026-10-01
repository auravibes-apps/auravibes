// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tools_list_view_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retains list choices across route replacement, independently per workspace.

@ProviderFor(ToolsListViewNotifier)
final toolsListViewProvider = ToolsListViewNotifierFamily._();

/// Retains list choices across route replacement, independently per workspace.
final class ToolsListViewNotifierProvider
    extends $NotifierProvider<ToolsListViewNotifier, ToolsListViewState> {
  /// Retains list choices across route replacement, independently per workspace.
  ToolsListViewNotifierProvider._({
    required ToolsListViewNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'toolsListViewProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$toolsListViewNotifierHash();

  @override
  String toString() {
    return r'toolsListViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ToolsListViewNotifier create() => ToolsListViewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToolsListViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToolsListViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ToolsListViewNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$toolsListViewNotifierHash() =>
    r'cfd242a91584cce44ec78bbf5c0a9a4d49f9a47f';

/// Retains list choices across route replacement, independently per workspace.

final class ToolsListViewNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ToolsListViewNotifier,
          ToolsListViewState,
          ToolsListViewState,
          ToolsListViewState,
          String
        > {
  ToolsListViewNotifierFamily._()
    : super(
        retry: null,
        name: r'toolsListViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Retains list choices across route replacement, independently per workspace.

  ToolsListViewNotifierProvider call(String workspaceId) =>
      ToolsListViewNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'toolsListViewProvider';
}

/// Retains list choices across route replacement, independently per workspace.

abstract class _$ToolsListViewNotifier extends $Notifier<ToolsListViewState> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  ToolsListViewState build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ToolsListViewState, ToolsListViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ToolsListViewState, ToolsListViewState>,
              ToolsListViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
