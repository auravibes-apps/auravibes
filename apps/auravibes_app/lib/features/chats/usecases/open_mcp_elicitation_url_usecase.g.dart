// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_mcp_elicitation_url_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openMcpElicitationUrlUsecase)
final openMcpElicitationUrlUsecaseProvider =
    OpenMcpElicitationUrlUsecaseProvider._();

final class OpenMcpElicitationUrlUsecaseProvider
    extends
        $FunctionalProvider<
          OpenMcpElicitationUrlUsecase,
          OpenMcpElicitationUrlUsecase,
          OpenMcpElicitationUrlUsecase
        >
    with $Provider<OpenMcpElicitationUrlUsecase> {
  OpenMcpElicitationUrlUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openMcpElicitationUrlUsecaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openMcpElicitationUrlUsecaseHash();

  @$internal
  @override
  $ProviderElement<OpenMcpElicitationUrlUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OpenMcpElicitationUrlUsecase create(Ref ref) {
    return openMcpElicitationUrlUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenMcpElicitationUrlUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenMcpElicitationUrlUsecase>(value),
    );
  }
}

String _$openMcpElicitationUrlUsecaseHash() =>
    r'217806d4d3074ebbb1ae1dd5b5d11a4028a3881c';
