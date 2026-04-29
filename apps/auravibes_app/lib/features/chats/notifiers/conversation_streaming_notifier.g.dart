// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_streaming_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConversationStreamingNotifier)
final conversationStreamingProvider = ConversationStreamingNotifierProvider._();

final class ConversationStreamingNotifierProvider
    extends $NotifierProvider<ConversationStreamingNotifier, Set<String>> {
  ConversationStreamingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationStreamingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationStreamingNotifierHash();

  @$internal
  @override
  ConversationStreamingNotifier create() => ConversationStreamingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$conversationStreamingNotifierHash() =>
    r'9eba06d10057dee1ec9565f57a678e367de75962';

abstract class _$ConversationStreamingNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
