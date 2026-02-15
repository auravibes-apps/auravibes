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

@ProviderFor(ConversationChatController)
final conversationChatControllerProvider =
    ConversationChatControllerProvider._();

final class ConversationChatControllerProvider
    extends
        $AsyncNotifierProvider<
          ConversationChatController,
          ConversationEntity?
        > {
  ConversationChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationChatControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationChatControllerProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() => _$conversationChatControllerHash();

  @$internal
  @override
  ConversationChatController create() => ConversationChatController();
}

String _$conversationChatControllerHash() =>
    r'27c5641da382c8d14e9b4f3dd945072ece937de4';

abstract class _$ConversationChatController
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

@ProviderFor(ChatMessagesController)
final chatMessagesControllerProvider = ChatMessagesControllerProvider._();

final class ChatMessagesControllerProvider
    extends
        $AsyncNotifierProvider<ChatMessagesController, List<MessageEntity>> {
  ChatMessagesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessagesControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ChatMessagesControllerProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() => _$chatMessagesControllerHash();

  @$internal
  @override
  ChatMessagesController create() => ChatMessagesController();
}

String _$chatMessagesControllerHash() =>
    r'acd1cb925d11b836d9295627723cad13a0d5d39e';

abstract class _$ChatMessagesController
    extends $AsyncNotifier<List<MessageEntity>> {
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
        dependencies: <ProviderOrFamily>[chatMessagesControllerProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          MessageListProvider.$allTransitiveDependencies0,
          MessageListProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = chatMessagesControllerProvider;
  static final $allTransitiveDependencies1 =
      ChatMessagesControllerProvider.$allTransitiveDependencies0;

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

String _$messageListHash() => r'18865ef1f24212dd3e47c709f81acf1fbc933257';

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
          chatMessagesControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          MessageConversationProvider.$allTransitiveDependencies0,
          MessageConversationProvider.$allTransitiveDependencies1,
          MessageConversationProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = messageIdProvider;
  static final $allTransitiveDependencies1 = chatMessagesControllerProvider;
  static final $allTransitiveDependencies2 =
      ChatMessagesControllerProvider.$allTransitiveDependencies0;

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
    r'6c7a48761d743bbe14ff65861800c25f78c748d0';

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
    r'c1dd2ebe5471ac9723a1e90f4f99a332ff26c427';
