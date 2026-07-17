// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceSession)
final workspaceSessionProvider = WorkspaceSessionProvider._();

final class WorkspaceSessionProvider
    extends
        $FunctionalProvider<
          WorkspaceSession,
          WorkspaceSession,
          WorkspaceSession
        >
    with $Provider<WorkspaceSession> {
  WorkspaceSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceSessionProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceSessionHash();

  @$internal
  @override
  $ProviderElement<WorkspaceSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkspaceSession create(Ref ref) {
    return workspaceSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceSession>(value),
    );
  }
}

String _$workspaceSessionHash() => r'428c5736e6311d04ef532bde19a741486b035826';

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
    r'8fc38222353456640586554b4a7e4b033e0ff0ce';

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
final cloudWorkspaceStateGatewayProvider =
    CloudWorkspaceStateGatewayProvider._();

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
  CloudWorkspaceStateGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudWorkspaceStateGatewayProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[workspaceSessionProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CloudWorkspaceStateGatewayProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceStateGatewayHash();

  @$internal
  @override
  $FutureProviderElement<CloudWorkspaceStateGateway?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudWorkspaceStateGateway?> create(Ref ref) {
    return cloudWorkspaceStateGateway(ref);
  }
}

String _$cloudWorkspaceStateGatewayHash() =>
    r'5107663e9c7282ae1eb3518954936b2b73237c87';

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
@Dependencies([cloudWorkspaceStateGateway])
final cloudWorkspaceConfigurationProvider =
    CloudWorkspaceConfigurationProvider._();

@Dependencies([cloudWorkspaceStateGateway])
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
  CloudWorkspaceConfigurationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudWorkspaceConfigurationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceConfigurationHash();

  @$internal
  @override
  $StreamProviderElement<List<WorkspaceResource>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkspaceResource>> create(Ref ref) {
    return cloudWorkspaceConfiguration(ref);
  }
}

String _$cloudWorkspaceConfigurationHash() =>
    r'408ba82e70735ec4c349107389ba914c4f88cc97';
