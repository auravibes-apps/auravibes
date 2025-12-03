// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationSelectedNotifier)
const conversationSelectedProvider = ConversationSelectedNotifierProvider._();

final class ConversationSelectedNotifierProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  const ConversationSelectedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationSelectedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationSelectedNotifierHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return conversationSelectedNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$conversationSelectedNotifierHash() =>
    r'54748a3e8db30c85e1c6305f967878aa4dc83be0';

@ProviderFor(ConversationChatNotifier)
const conversationChatProvider = ConversationChatNotifierProvider._();

final class ConversationChatNotifierProvider
    extends
        $AsyncNotifierProvider<ConversationChatNotifier, ConversationEntity?> {
  const ConversationChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationChatProvider',
        isAutoDispose: true,
        dependencies: const <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: const <ProviderOrFamily>[
          ConversationChatNotifierProvider.$allTransitiveDependencies0,
        ],
      );

  static const $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() => _$conversationChatNotifierHash();

  @$internal
  @override
  ConversationChatNotifier create() => ConversationChatNotifier();
}

String _$conversationChatNotifierHash() =>
    r'1f1fb14eca5f6e98e85a2725875cebded5fb7ca0';

abstract class _$ConversationChatNotifier
    extends $AsyncNotifier<ConversationEntity?> {
  FutureOr<ConversationEntity?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<ConversationEntity?>, ConversationEntity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ConversationEntity?>, ConversationEntity?>,
              AsyncValue<ConversationEntity?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatMessages)
const chatMessagesProvider = ChatMessagesProvider._();

final class ChatMessagesProvider
    extends $AsyncNotifierProvider<ChatMessages, List<MessageEntity>> {
  const ChatMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessagesProvider',
        isAutoDispose: true,
        dependencies: const <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: const <ProviderOrFamily>[
          ChatMessagesProvider.$allTransitiveDependencies0,
        ],
      );

  static const $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @$internal
  @override
  ChatMessages create() => ChatMessages();
}

String _$chatMessagesHash() => r'71b0e2817a082b3c5ebce184da6b57bafe206b58';

abstract class _$ChatMessages extends $AsyncNotifier<List<MessageEntity>> {
  FutureOr<List<MessageEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<MessageEntity>>, List<MessageEntity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MessageEntity>>, List<MessageEntity>>,
              AsyncValue<List<MessageEntity>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(messageList)
const messageListProvider = MessageListProvider._();

final class MessageListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  const MessageListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageListProvider',
        isAutoDispose: true,
        dependencies: const <ProviderOrFamily>[chatMessagesProvider],
        $allTransitiveDependencies: const <ProviderOrFamily>[
          MessageListProvider.$allTransitiveDependencies0,
          MessageListProvider.$allTransitiveDependencies1,
        ],
      );

  static const $allTransitiveDependencies0 = chatMessagesProvider;
  static const $allTransitiveDependencies1 =
      ChatMessagesProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$messageListHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return messageList(ref);
  }
}

String _$messageListHash() => r'57066aa84a313090aad3d3d0f1601dec58b2ef69';

@ProviderFor(messageIdNotifier)
const messageIdProvider = MessageIdNotifierProvider._();

final class MessageIdNotifierProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  const MessageIdNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageIdProvider',
        isAutoDispose: true,
        dependencies: const <ProviderOrFamily>[chatMessagesProvider],
        $allTransitiveDependencies: const <ProviderOrFamily>[
          MessageIdNotifierProvider.$allTransitiveDependencies0,
          MessageIdNotifierProvider.$allTransitiveDependencies1,
        ],
      );

  static const $allTransitiveDependencies0 = chatMessagesProvider;
  static const $allTransitiveDependencies1 =
      ChatMessagesProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$messageIdNotifierHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return messageIdNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$messageIdNotifierHash() => r'f7c3dc6b42482a1be42673d362f74081840a66e1';

@ProviderFor(messageConversation)
const messageConversationProvider = MessageConversationProvider._();

final class MessageConversationProvider
    extends $FunctionalProvider<MessageEntity?, MessageEntity?, MessageEntity?>
    with $Provider<MessageEntity?> {
  const MessageConversationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageConversationProvider',
        isAutoDispose: true,
        dependencies: const <ProviderOrFamily>[
          messageIdProvider,
          chatMessagesProvider,
        ],
        $allTransitiveDependencies: const <ProviderOrFamily>[
          MessageConversationProvider.$allTransitiveDependencies0,
          MessageConversationProvider.$allTransitiveDependencies1,
          MessageConversationProvider.$allTransitiveDependencies2,
        ],
      );

  static const $allTransitiveDependencies0 = messageIdProvider;
  static const $allTransitiveDependencies1 =
      MessageIdNotifierProvider.$allTransitiveDependencies0;
  static const $allTransitiveDependencies2 =
      MessageIdNotifierProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$messageConversationHash();

  @$internal
  @override
  $ProviderElement<MessageEntity?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageEntity? create(Ref ref) {
    return messageConversation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageEntity?>(value),
    );
  }
}

String _$messageConversationHash() =>
    r'77d5537987da903337a62ccacc21a1adde5985cc';
