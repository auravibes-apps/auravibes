// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceSession)
final workspaceSessionProvider = WorkspaceSessionFamily._();

final class WorkspaceSessionProvider
    extends
        $FunctionalProvider<
          WorkspaceSession,
          WorkspaceSession,
          WorkspaceSession
        >
    with $Provider<WorkspaceSession> {
  WorkspaceSessionProvider._({
    required WorkspaceSessionFamily super.from,
    required WorkspaceSession super.argument,
  }) : super(
         retry: null,
         name: r'workspaceSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceSessionHash();

  @override
  String toString() {
    return r'workspaceSessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<WorkspaceSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkspaceSession create(Ref ref) {
    final argument = this.argument as WorkspaceSession;
    return workspaceSession(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceSession>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceSessionHash() => r'c142049a5fb62dd4aa50aa84a69e2353ad2499b7';

final class WorkspaceSessionFamily extends $Family
    with $FunctionalFamilyOverride<WorkspaceSession, WorkspaceSession> {
  WorkspaceSessionFamily._()
    : super(
        retry: null,
        name: r'workspaceSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceSessionProvider call(WorkspaceSession session) =>
      WorkspaceSessionProvider._(argument: session, from: this);

  @override
  String toString() => r'workspaceSessionProvider';
}

@ProviderFor(workspaceSessionForRoute)
final workspaceSessionForRouteProvider = WorkspaceSessionForRouteFamily._();

final class WorkspaceSessionForRouteProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceSession>,
          WorkspaceSession,
          FutureOr<WorkspaceSession>
        >
    with $FutureModifier<WorkspaceSession>, $FutureProvider<WorkspaceSession> {
  WorkspaceSessionForRouteProvider._({
    required WorkspaceSessionForRouteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceSessionForRouteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceSessionForRouteHash();

  @override
  String toString() {
    return r'workspaceSessionForRouteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceSession> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceSession> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceSessionForRoute(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceSessionForRouteProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceSessionForRouteHash() =>
    r'fdbecb263fffd877c0a8994c9455c6aae55538de';

final class WorkspaceSessionForRouteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceSession>, String> {
  WorkspaceSessionForRouteFamily._()
    : super(
        retry: null,
        name: r'workspaceSessionForRouteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceSessionForRouteProvider call(String localWorkspaceId) =>
      WorkspaceSessionForRouteProvider._(
        argument: localWorkspaceId,
        from: this,
      );

  @override
  String toString() => r'workspaceSessionForRouteProvider';
}

@ProviderFor(workspaceAvailability)
final workspaceAvailabilityProvider = WorkspaceAvailabilityFamily._();

final class WorkspaceAvailabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceAvailability>,
          WorkspaceAvailability,
          FutureOr<WorkspaceAvailability>
        >
    with
        $FutureModifier<WorkspaceAvailability>,
        $FutureProvider<WorkspaceAvailability> {
  WorkspaceAvailabilityProvider._({
    required WorkspaceAvailabilityFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAvailabilityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAvailabilityHash();

  @override
  String toString() {
    return r'workspaceAvailabilityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceAvailability> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceAvailability> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceAvailability(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAvailabilityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAvailabilityHash() =>
    r'6a4feae18a02b6529ebbf993da3999a6570ae6a8';

final class WorkspaceAvailabilityFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceAvailability>, String> {
  WorkspaceAvailabilityFamily._()
    : super(
        retry: null,
        name: r'workspaceAvailabilityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceAvailabilityProvider call(String localWorkspaceId) =>
      WorkspaceAvailabilityProvider._(argument: localWorkspaceId, from: this);

  @override
  String toString() => r'workspaceAvailabilityProvider';
}

@ProviderFor(cloudWorkspaceStateGateway)
final cloudWorkspaceStateGatewayProvider = CloudWorkspaceStateGatewayFamily._();

final class CloudWorkspaceStateGatewayProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudWorkspaceStateGateway?>,
          CloudWorkspaceStateGateway?,
          FutureOr<CloudWorkspaceStateGateway?>
        >
    with
        $FutureModifier<CloudWorkspaceStateGateway?>,
        $FutureProvider<CloudWorkspaceStateGateway?> {
  CloudWorkspaceStateGatewayProvider._({
    required CloudWorkspaceStateGatewayFamily super.from,
    required WorkspaceSession super.argument,
  }) : super(
         retry: null,
         name: r'cloudWorkspaceStateGatewayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceStateGatewayHash();

  @override
  String toString() {
    return r'cloudWorkspaceStateGatewayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudWorkspaceStateGateway?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudWorkspaceStateGateway?> create(Ref ref) {
    final argument = this.argument as WorkspaceSession;
    return cloudWorkspaceStateGateway(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWorkspaceStateGatewayProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudWorkspaceStateGatewayHash() =>
    r'f7c66e77ab1860cc42ac428212ee4693ed31f9f3';

final class CloudWorkspaceStateGatewayFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudWorkspaceStateGateway?>,
          WorkspaceSession
        > {
  CloudWorkspaceStateGatewayFamily._()
    : super(
        retry: null,
        name: r'cloudWorkspaceStateGatewayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudWorkspaceStateGatewayProvider call(WorkspaceSession session) =>
      CloudWorkspaceStateGatewayProvider._(argument: session, from: this);

  @override
  String toString() => r'cloudWorkspaceStateGatewayProvider';
}

@ProviderFor(cloudWorkspaceStateGatewayForWorkspace)
final cloudWorkspaceStateGatewayForWorkspaceProvider =
    CloudWorkspaceStateGatewayForWorkspaceFamily._();

final class CloudWorkspaceStateGatewayForWorkspaceProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudWorkspaceStateGateway?>,
          CloudWorkspaceStateGateway?,
          FutureOr<CloudWorkspaceStateGateway?>
        >
    with
        $FutureModifier<CloudWorkspaceStateGateway?>,
        $FutureProvider<CloudWorkspaceStateGateway?> {
  CloudWorkspaceStateGatewayForWorkspaceProvider._({
    required CloudWorkspaceStateGatewayForWorkspaceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cloudWorkspaceStateGatewayForWorkspaceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$cloudWorkspaceStateGatewayForWorkspaceHash();

  @override
  String toString() {
    return r'cloudWorkspaceStateGatewayForWorkspaceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudWorkspaceStateGateway?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudWorkspaceStateGateway?> create(Ref ref) {
    final argument = this.argument as String;
    return cloudWorkspaceStateGatewayForWorkspace(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWorkspaceStateGatewayForWorkspaceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudWorkspaceStateGatewayForWorkspaceHash() =>
    r'878f83707ec41159d90752514f0aaff1f82734f2';

final class CloudWorkspaceStateGatewayForWorkspaceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudWorkspaceStateGateway?>,
          String
        > {
  CloudWorkspaceStateGatewayForWorkspaceFamily._()
    : super(
        retry: null,
        name: r'cloudWorkspaceStateGatewayForWorkspaceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudWorkspaceStateGatewayForWorkspaceProvider call(
    String localWorkspaceId,
  ) => CloudWorkspaceStateGatewayForWorkspaceProvider._(
    argument: localWorkspaceId,
    from: this,
  );

  @override
  String toString() => r'cloudWorkspaceStateGatewayForWorkspaceProvider';
}

@ProviderFor(cloudWorkspaceConfiguration)
final cloudWorkspaceConfigurationProvider =
    CloudWorkspaceConfigurationFamily._();

final class CloudWorkspaceConfigurationProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceResource>>,
          List<WorkspaceResource>,
          Stream<List<WorkspaceResource>>
        >
    with
        $FutureModifier<List<WorkspaceResource>>,
        $StreamProvider<List<WorkspaceResource>> {
  CloudWorkspaceConfigurationProvider._({
    required CloudWorkspaceConfigurationFamily super.from,
    required WorkspaceSession super.argument,
  }) : super(
         retry: null,
         name: r'cloudWorkspaceConfigurationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceConfigurationHash();

  @override
  String toString() {
    return r'cloudWorkspaceConfigurationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<WorkspaceResource>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkspaceResource>> create(Ref ref) {
    final argument = this.argument as WorkspaceSession;
    return cloudWorkspaceConfiguration(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWorkspaceConfigurationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudWorkspaceConfigurationHash() =>
    r'41996fd8d87a951802ff4d0c3fdfaed7b491a2c6';

final class CloudWorkspaceConfigurationFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<WorkspaceResource>>,
          WorkspaceSession
        > {
  CloudWorkspaceConfigurationFamily._()
    : super(
        retry: null,
        name: r'cloudWorkspaceConfigurationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudWorkspaceConfigurationProvider call(WorkspaceSession session) =>
      CloudWorkspaceConfigurationProvider._(argument: session, from: this);

  @override
  String toString() => r'cloudWorkspaceConfigurationProvider';
}
