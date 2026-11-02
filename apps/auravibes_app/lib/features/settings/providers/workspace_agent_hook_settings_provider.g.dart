// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_agent_hook_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceAgentHookSettings)
final workspaceAgentHookSettingsProvider = WorkspaceAgentHookSettingsFamily._();

final class WorkspaceAgentHookSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceAgentHookSettings>,
          WorkspaceAgentHookSettings,
          Stream<WorkspaceAgentHookSettings>
        >
    with
        $FutureModifier<WorkspaceAgentHookSettings>,
        $StreamProvider<WorkspaceAgentHookSettings> {
  WorkspaceAgentHookSettingsProvider._({
    required WorkspaceAgentHookSettingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAgentHookSettingsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAgentHookSettingsHash();

  @override
  String toString() {
    return r'workspaceAgentHookSettingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<WorkspaceAgentHookSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WorkspaceAgentHookSettings> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceAgentHookSettings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAgentHookSettingsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAgentHookSettingsHash() =>
    r'0282dc5fe7243b2c9f3b2541b08f7b3ddf0c658e';

final class WorkspaceAgentHookSettingsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<WorkspaceAgentHookSettings>, String> {
  WorkspaceAgentHookSettingsFamily._()
    : super(
        retry: null,
        name: r'workspaceAgentHookSettingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  WorkspaceAgentHookSettingsProvider call(String workspaceId) =>
      WorkspaceAgentHookSettingsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceAgentHookSettingsProvider';
}

@ProviderFor(workspaceAgentHookTrustStatus)
final workspaceAgentHookTrustStatusProvider =
    WorkspaceAgentHookTrustStatusFamily._();

final class WorkspaceAgentHookTrustStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceAgentHookTrustStatus>,
          WorkspaceAgentHookTrustStatus,
          FutureOr<WorkspaceAgentHookTrustStatus>
        >
    with
        $FutureModifier<WorkspaceAgentHookTrustStatus>,
        $FutureProvider<WorkspaceAgentHookTrustStatus> {
  WorkspaceAgentHookTrustStatusProvider._({
    required WorkspaceAgentHookTrustStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAgentHookTrustStatusProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAgentHookTrustStatusHash();

  @override
  String toString() {
    return r'workspaceAgentHookTrustStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceAgentHookTrustStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceAgentHookTrustStatus> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceAgentHookTrustStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAgentHookTrustStatusProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAgentHookTrustStatusHash() =>
    r'1e56bab17cce58c6e668174c2f2250781df63d97';

final class WorkspaceAgentHookTrustStatusFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceAgentHookTrustStatus>,
          String
        > {
  WorkspaceAgentHookTrustStatusFamily._()
    : super(
        retry: null,
        name: r'workspaceAgentHookTrustStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  WorkspaceAgentHookTrustStatusProvider call(String workspaceId) =>
      WorkspaceAgentHookTrustStatusProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'workspaceAgentHookTrustStatusProvider';
}
