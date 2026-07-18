// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_usage_level.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contextUsage)
final contextUsageProvider = ContextUsageFamily._();

final class ContextUsageProvider
    extends
        $FunctionalProvider<
          ContextUsageData,
          ContextUsageData,
          ContextUsageData
        >
    with $Provider<ContextUsageData> {
  ContextUsageProvider._({
    required ContextUsageFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'contextUsageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contextUsageHash();

  @override
  String toString() {
    return r'contextUsageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<ContextUsageData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ContextUsageData create(Ref ref) {
    final argument = this.argument as (String, String);
    return contextUsage(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContextUsageData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContextUsageData>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ContextUsageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextUsageHash() => r'8c422e9b62c4ee4be63a2f74cb6c6a2a15ba1604';

final class ContextUsageFamily extends $Family
    with $FunctionalFamilyOverride<ContextUsageData, (String, String)> {
  ContextUsageFamily._()
    : super(
        retry: null,
        name: r'contextUsageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContextUsageProvider call(String workspaceId, String conversationId) =>
      ContextUsageProvider._(
        argument: (workspaceId, conversationId),
        from: this,
      );

  @override
  String toString() => r'contextUsageProvider';
}
