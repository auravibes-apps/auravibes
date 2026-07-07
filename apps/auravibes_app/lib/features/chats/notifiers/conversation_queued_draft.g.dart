// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_queued_draft.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConversationSendQueue)
final conversationSendQueueProvider = ConversationSendQueueProvider._();

final class ConversationSendQueueProvider
    extends
        $NotifierProvider<
          ConversationSendQueue,
          Map<String, List<ConversationQueuedDraft>>
        > {
  ConversationSendQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationSendQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationSendQueueHash();

  @$internal
  @override
  ConversationSendQueue create() => ConversationSendQueue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<ConversationQueuedDraft>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, List<ConversationQueuedDraft>>>(value),
    );
  }
}

String _$conversationSendQueueHash() =>
    r'2031f2a6b04f64d5a3fde1b90ffc0a0b8c03cc56';

abstract class _$ConversationSendQueue
    extends $Notifier<Map<String, List<ConversationQueuedDraft>>> {
  Map<String, List<ConversationQueuedDraft>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, List<ConversationQueuedDraft>>,
              Map<String, List<ConversationQueuedDraft>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, List<ConversationQueuedDraft>>,
                Map<String, List<ConversationQueuedDraft>>
              >,
              Map<String, List<ConversationQueuedDraft>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
