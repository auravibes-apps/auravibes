// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_usage_level.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contextUsage)
final contextUsageProvider = ContextUsageProvider._();

final class ContextUsageProvider
    extends
        $FunctionalProvider<
          ContextUsageData,
          ContextUsageData,
          ContextUsageData
        >
    with $Provider<ContextUsageData> {
  ContextUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contextUsageProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          conversationUsedTokensProvider,
          conversationContextLimitProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ContextUsageProvider.$allTransitiveDependencies0,
          ContextUsageProvider.$allTransitiveDependencies1,
          ContextUsageProvider.$allTransitiveDependencies2,
          ContextUsageProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = conversationUsedTokensProvider;
  static final $allTransitiveDependencies1 =
      ConversationUsedTokensProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      ConversationUsedTokensProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = conversationContextLimitProvider;

  @override
  String debugGetCreateSourceHash() => _$contextUsageHash();

  @$internal
  @override
  $ProviderElement<ContextUsageData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ContextUsageData create(Ref ref) {
    return contextUsage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContextUsageData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContextUsageData>(value),
    );
  }
}

String _$contextUsageHash() => r'6a79a66532a6bedbaf4bcd998f997a75201704fd';
