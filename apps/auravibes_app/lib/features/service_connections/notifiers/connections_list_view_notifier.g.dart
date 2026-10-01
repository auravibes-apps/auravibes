// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connections_list_view_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retains list choices across route replacement, independently per workspace.

@ProviderFor(ConnectionsListViewNotifier)
final connectionsListViewProvider = ConnectionsListViewNotifierFamily._();

/// Retains list choices across route replacement, independently per workspace.
final class ConnectionsListViewNotifierProvider
    extends
        $NotifierProvider<
          ConnectionsListViewNotifier,
          ConnectionsListViewState
        > {
  /// Retains list choices across route replacement, independently per workspace.
  ConnectionsListViewNotifierProvider._({
    required ConnectionsListViewNotifierFamily super.from,
    required (String, ConnectionDestination) super.argument,
  }) : super(
         retry: null,
         name: r'connectionsListViewProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectionsListViewNotifierHash();

  @override
  String toString() {
    return r'connectionsListViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConnectionsListViewNotifier create() => ConnectionsListViewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionsListViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionsListViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionsListViewNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectionsListViewNotifierHash() =>
    r'a6b2eb869e4545179a56a54672422e49b385a81a';

/// Retains list choices across route replacement, independently per workspace.

final class ConnectionsListViewNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConnectionsListViewNotifier,
          ConnectionsListViewState,
          ConnectionsListViewState,
          ConnectionsListViewState,
          (String, ConnectionDestination)
        > {
  ConnectionsListViewNotifierFamily._()
    : super(
        retry: null,
        name: r'connectionsListViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Retains list choices across route replacement, independently per workspace.

  ConnectionsListViewNotifierProvider call(
    String workspaceId,
    ConnectionDestination view,
  ) => ConnectionsListViewNotifierProvider._(
    argument: (workspaceId, view),
    from: this,
  );

  @override
  String toString() => r'connectionsListViewProvider';
}

/// Retains list choices across route replacement, independently per workspace.

abstract class _$ConnectionsListViewNotifier
    extends $Notifier<ConnectionsListViewState> {
  late final _$args = ref.$arg as (String, ConnectionDestination);
  String get workspaceId => _$args.$1;
  ConnectionDestination get view => _$args.$2;

  ConnectionsListViewState build(
    String workspaceId,
    ConnectionDestination view,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ConnectionsListViewState, ConnectionsListViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConnectionsListViewState, ConnectionsListViewState>,
              ConnectionsListViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
