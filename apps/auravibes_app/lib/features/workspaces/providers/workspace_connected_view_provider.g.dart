// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_connected_view_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceConnectedView)
final workspaceConnectedViewProvider = WorkspaceConnectedViewFamily._();

final class WorkspaceConnectedViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceConnectedResult>,
          WorkspaceConnectedResult,
          FutureOr<WorkspaceConnectedResult>
        >
    with
        $FutureModifier<WorkspaceConnectedResult>,
        $FutureProvider<WorkspaceConnectedResult> {
  WorkspaceConnectedViewProvider._({
    required WorkspaceConnectedViewFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: _connectedRetry,
         name: r'workspaceConnectedViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceConnectedViewHash();

  @override
  String toString() {
    return r'workspaceConnectedViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceConnectedResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceConnectedResult> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceConnectedView(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceConnectedViewProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceConnectedViewHash() =>
    r'f888e9674b118c195ef96bf65471a746d010c20b';

final class WorkspaceConnectedViewFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceConnectedResult>,
          (String, String)
        > {
  WorkspaceConnectedViewFamily._()
    : super(
        retry: _connectedRetry,
        name: r'workspaceConnectedViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceConnectedViewProvider call(String workspaceId, String viewId) =>
      WorkspaceConnectedViewProvider._(
        argument: (workspaceId, viewId),
        from: this,
      );

  @override
  String toString() => r'workspaceConnectedViewProvider';
}

@ProviderFor(workspaceConnectedAccess)
final workspaceConnectedAccessProvider = WorkspaceConnectedAccessFamily._();

final class WorkspaceConnectedAccessProvider
    extends $FunctionalProvider<AsyncValue<Object?>, Object?, Stream<Object?>>
    with $FutureModifier<Object?>, $StreamProvider<Object?> {
  WorkspaceConnectedAccessProvider._({
    required WorkspaceConnectedAccessFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceConnectedAccessProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceConnectedAccessHash();

  @override
  String toString() {
    return r'workspaceConnectedAccessProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Object?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Object?> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceConnectedAccess(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceConnectedAccessProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceConnectedAccessHash() =>
    r'a5b4dee06839f0d3328ebd7c93542ec4fe97a3f3';

final class WorkspaceConnectedAccessFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Object?>, String> {
  WorkspaceConnectedAccessFamily._()
    : super(
        retry: null,
        name: r'workspaceConnectedAccessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceConnectedAccessProvider call(String workspaceId) =>
      WorkspaceConnectedAccessProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceConnectedAccessProvider';
}

@ProviderFor(workspaceConnectedConnections)
final workspaceConnectedConnectionsProvider =
    WorkspaceConnectedConnectionsFamily._();

final class WorkspaceConnectedConnectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConnectorConnectionCandidate>>,
          List<ConnectorConnectionCandidate>,
          FutureOr<List<ConnectorConnectionCandidate>>
        >
    with
        $FutureModifier<List<ConnectorConnectionCandidate>>,
        $FutureProvider<List<ConnectorConnectionCandidate>> {
  WorkspaceConnectedConnectionsProvider._({
    required WorkspaceConnectedConnectionsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceConnectedConnectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceConnectedConnectionsHash();

  @override
  String toString() {
    return r'workspaceConnectedConnectionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ConnectorConnectionCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ConnectorConnectionCandidate>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceConnectedConnections(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceConnectedConnectionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceConnectedConnectionsHash() =>
    r'143aa7bf4c5eabdf3a8cb49c073eccaf20c7f029';

final class WorkspaceConnectedConnectionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ConnectorConnectionCandidate>>,
          (String, String)
        > {
  WorkspaceConnectedConnectionsFamily._()
    : super(
        retry: null,
        name: r'workspaceConnectedConnectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceConnectedConnectionsProvider call(
    String workspaceId,
    String connectorId,
  ) => WorkspaceConnectedConnectionsProvider._(
    argument: (workspaceId, connectorId),
    from: this,
  );

  @override
  String toString() => r'workspaceConnectedConnectionsProvider';
}
