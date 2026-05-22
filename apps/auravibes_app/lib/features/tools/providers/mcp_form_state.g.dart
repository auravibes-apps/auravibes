// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_form_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing MCP form state

@ProviderFor(McpFormNotifier)
final mcpFormProvider = McpFormNotifierFamily._();

/// Notifier for managing MCP form state
final class McpFormNotifierProvider
    extends $NotifierProvider<McpFormNotifier, McpFormState> {
  /// Notifier for managing MCP form state
  McpFormNotifierProvider._({
    required McpFormNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mcpFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mcpFormNotifierHash();

  @override
  String toString() {
    return r'mcpFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  McpFormNotifier create() => McpFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is McpFormNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mcpFormNotifierHash() => r'2b5f986f9d82800fd4edeba71e14236b6c80c49e';

/// Notifier for managing MCP form state

final class McpFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          McpFormNotifier,
          McpFormState,
          McpFormState,
          McpFormState,
          String
        > {
  McpFormNotifierFamily._()
    : super(
        retry: null,
        name: r'mcpFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing MCP form state

  McpFormNotifierProvider call(String workspaceId) =>
      McpFormNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'mcpFormProvider';
}

/// Notifier for managing MCP form state

abstract class _$McpFormNotifier extends $Notifier<McpFormState> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  McpFormState build(String workspaceId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<McpFormState, McpFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<McpFormState, McpFormState>,
              McpFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
