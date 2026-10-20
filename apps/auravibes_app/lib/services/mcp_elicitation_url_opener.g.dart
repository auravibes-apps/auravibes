// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_elicitation_url_opener.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mcpElicitationUrlOpener)
final mcpElicitationUrlOpenerProvider = McpElicitationUrlOpenerProvider._();

final class McpElicitationUrlOpenerProvider
    extends
        $FunctionalProvider<
          McpElicitationUrlOpener,
          McpElicitationUrlOpener,
          McpElicitationUrlOpener
        >
    with $Provider<McpElicitationUrlOpener> {
  McpElicitationUrlOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpElicitationUrlOpenerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpElicitationUrlOpenerHash();

  @$internal
  @override
  $ProviderElement<McpElicitationUrlOpener> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  McpElicitationUrlOpener create(Ref ref) {
    return mcpElicitationUrlOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpElicitationUrlOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpElicitationUrlOpener>(value),
    );
  }
}

String _$mcpElicitationUrlOpenerHash() =>
    r'f22aa8590349d10930baa74c6005d26aed9289a0';
