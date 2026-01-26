// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationSelectedNotifier)
final conversationSelectedProvider = ConversationSelectedNotifierProvider._();

final class ConversationSelectedNotifierProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  ConversationSelectedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationSelectedProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
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
    r'30d28792df8d75acc432efeae609623be3e5c231';

@ProviderFor(ConversationChatNotifier)
final conversationChatProvider = ConversationChatNotifierProvider._();

final class ConversationChatNotifierProvider
    extends
        $AsyncNotifierProvider<ConversationChatNotifier, ConversationEntity?> {
  ConversationChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationChatProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationChatNotifierProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

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
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ChatMessages)
final chatMessagesProvider = ChatMessagesProvider._();

final class ChatMessagesProvider
    extends $AsyncNotifierProvider<ChatMessages, List<MessageEntity>> {
  ChatMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessagesProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ChatMessagesProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

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
    element.handleCreate(ref, build);
  }
}

@ProviderFor(messageList)
final messageListProvider = MessageListProvider._();

final class MessageListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  MessageListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageListProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[chatMessagesProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          MessageListProvider.$allTransitiveDependencies0,
          MessageListProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = chatMessagesProvider;
  static final $allTransitiveDependencies1 =
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
final messageIdProvider = MessageIdNotifierProvider._();

final class MessageIdNotifierProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  MessageIdNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageIdProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

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

String _$messageIdNotifierHash() => r'ca5c5d602ce2500fd6de1130348613aa34fc04ed';

@ProviderFor(messageConversation)
final messageConversationProvider = MessageConversationProvider._();

final class MessageConversationProvider
    extends $FunctionalProvider<MessageEntity?, MessageEntity?, MessageEntity?>
    with $Provider<MessageEntity?> {
  MessageConversationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageConversationProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          messageIdProvider,
          chatMessagesProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          MessageConversationProvider.$allTransitiveDependencies0,
          MessageConversationProvider.$allTransitiveDependencies1,
          MessageConversationProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = messageIdProvider;
  static final $allTransitiveDependencies1 = chatMessagesProvider;
  static final $allTransitiveDependencies2 =
      ChatMessagesProvider.$allTransitiveDependencies0;

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
    r'dac954de945e42e52623469502189a9e8015a8cf';

/// Provides the pending MCP server IDs for the current conversation.
///
/// Returns a list of MCP server IDs that are being waited on for connection,
/// or an empty list if not waiting.

@ProviderFor(pendingMcpConnections)
final pendingMcpConnectionsProvider = PendingMcpConnectionsProvider._();

/// Provides the pending MCP server IDs for the current conversation.
///
/// Returns a list of MCP server IDs that are being waited on for connection,
/// or an empty list if not waiting.

final class PendingMcpConnectionsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// Provides the pending MCP server IDs for the current conversation.
  ///
  /// Returns a list of MCP server IDs that are being waited on for connection,
  /// or an empty list if not waiting.
  PendingMcpConnectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingMcpConnectionsProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          PendingMcpConnectionsProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() => _$pendingMcpConnectionsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return pendingMcpConnections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$pendingMcpConnectionsHash() =>
    r'5592133c4118f304ea40f46c4eb669d69cbb833a';
