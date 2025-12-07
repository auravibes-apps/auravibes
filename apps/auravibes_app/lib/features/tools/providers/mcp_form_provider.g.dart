// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing MCP form state

@ProviderFor(McpFormNotifier)
const mcpFormProvider = McpFormNotifierProvider._();

/// Notifier for managing MCP form state
final class McpFormNotifierProvider
    extends $NotifierProvider<McpFormNotifier, McpFormState> {
  /// Notifier for managing MCP form state
  const McpFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpFormNotifierHash();

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
}

String _$mcpFormNotifierHash() => r'f86cd18a0c0093be6e0cfa0847e6693b51050690';

/// Notifier for managing MCP form state

abstract class _$McpFormNotifier extends $Notifier<McpFormState> {
  McpFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<McpFormState, McpFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<McpFormState, McpFormState>,
              McpFormState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
