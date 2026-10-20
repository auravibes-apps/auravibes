// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_elicitation_form_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mcpElicitationFormUsecase)
final mcpElicitationFormUsecaseProvider = McpElicitationFormUsecaseProvider._();

final class McpElicitationFormUsecaseProvider
    extends
        $FunctionalProvider<
          McpElicitationFormUsecase,
          McpElicitationFormUsecase,
          McpElicitationFormUsecase
        >
    with $Provider<McpElicitationFormUsecase> {
  McpElicitationFormUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpElicitationFormUsecaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpElicitationFormUsecaseHash();

  @$internal
  @override
  $ProviderElement<McpElicitationFormUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  McpElicitationFormUsecase create(Ref ref) {
    return mcpElicitationFormUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpElicitationFormUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpElicitationFormUsecase>(value),
    );
  }
}

String _$mcpElicitationFormUsecaseHash() =>
    r'4fd5dcfaca898e0cd64d71dd6ffcb6de7e4151c3';
