// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatMessagesByConversation)
final chatMessagesByConversationProvider = ChatMessagesByConversationFamily._();

final class ChatMessagesByConversationProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageEntity>>,
          List<MessageEntity>,
          Stream<List<MessageEntity>>
        >
    with
        $FutureModifier<List<MessageEntity>>,
        $StreamProvider<List<MessageEntity>> {
  ChatMessagesByConversationProvider._({
    required ChatMessagesByConversationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatMessagesByConversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesByConversationHash();

  @override
  String toString() {
    return r'chatMessagesByConversationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return chatMessagesByConversation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesByConversationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesByConversationHash() =>
    r'54763fab85d6b59ff879bb683f74130b15cc4924';

final class ChatMessagesByConversationFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MessageEntity>>, String> {
  ChatMessagesByConversationFamily._()
    : super(
        retry: null,
        name: r'chatMessagesByConversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessagesByConversationProvider call(String conversationId) =>
      ChatMessagesByConversationProvider._(
        argument: conversationId,
        from: this,
      );

  @override
  String toString() => r'chatMessagesByConversationProvider';
}

@ProviderFor(chatMessages)
final chatMessagesProvider = ChatMessagesProvider._();

final class ChatMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageEntity>>,
          List<MessageEntity>,
          FutureOr<List<MessageEntity>>
        >
    with
        $FutureModifier<List<MessageEntity>>,
        $FutureProvider<List<MessageEntity>> {
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
  $FutureProviderElement<List<MessageEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MessageEntity>> create(Ref ref) {
    return chatMessages(ref);
  }
}

String _$chatMessagesHash() => r'be90a05db8f6af583a2d0ba5a71d933f1b66b6f7';

@ProviderFor(chatMessageIds)
final chatMessageIdsProvider = ChatMessageIdsProvider._();

final class ChatMessageIdsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  ChatMessageIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatMessageIdsProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[chatMessagesProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ChatMessageIdsProvider.$allTransitiveDependencies0,
          ChatMessageIdsProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = chatMessagesProvider;
  static final $allTransitiveDependencies1 =
      ChatMessagesProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$chatMessageIdsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return chatMessageIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$chatMessageIdsHash() => r'3d15c6497c6d4f965f843647065c5f04204832cc';

@ProviderFor(messageConversationById)
final messageConversationByIdProvider = MessageConversationByIdFamily._();

final class MessageConversationByIdProvider
    extends $FunctionalProvider<MessageEntity?, MessageEntity?, MessageEntity?>
    with $Provider<MessageEntity?> {
  MessageConversationByIdProvider._({
    required MessageConversationByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageConversationByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = chatMessagesProvider;
  static final $allTransitiveDependencies1 =
      ChatMessagesProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = messagesStreamingProvider;

  @override
  String debugGetCreateSourceHash() => _$messageConversationByIdHash();

  @override
  String toString() {
    return r'messageConversationByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<MessageEntity?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageEntity? create(Ref ref) {
    final argument = this.argument as String;
    return messageConversationById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageEntity?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageConversationByIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageConversationByIdHash() =>
    r'7f36d6aa8c2245180e9fe420a0a4009de56e71bd';

final class MessageConversationByIdFamily extends $Family
    with $FunctionalFamilyOverride<MessageEntity?, String> {
  MessageConversationByIdFamily._()
    : super(
        retry: null,
        name: r'messageConversationByIdProvider',
        dependencies: <ProviderOrFamily>[
          chatMessagesProvider,
          messagesStreamingProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          MessageConversationByIdProvider.$allTransitiveDependencies0,
          MessageConversationByIdProvider.$allTransitiveDependencies1,
          MessageConversationByIdProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  MessageConversationByIdProvider call(String messageId) =>
      MessageConversationByIdProvider._(argument: messageId, from: this);

  @override
  String toString() => r'messageConversationByIdProvider';
}

@ProviderFor(isMessageStreaming)
final isMessageStreamingProvider = IsMessageStreamingFamily._();

final class IsMessageStreamingProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsMessageStreamingProvider._({
    required IsMessageStreamingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isMessageStreamingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = messagesStreamingProvider;

  @override
  String debugGetCreateSourceHash() => _$isMessageStreamingHash();

  @override
  String toString() {
    return r'isMessageStreamingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isMessageStreaming(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsMessageStreamingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isMessageStreamingHash() =>
    r'060b0ab87cea0121ad17df4c0d7d8540ba9926ed';

final class IsMessageStreamingFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsMessageStreamingFamily._()
    : super(
        retry: null,
        name: r'isMessageStreamingProvider',
        dependencies: <ProviderOrFamily>[messagesStreamingProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          IsMessageStreamingProvider.$allTransitiveDependencies0,
        ],
        isAutoDispose: true,
      );

  IsMessageStreamingProvider call(String messageId) =>
      IsMessageStreamingProvider._(argument: messageId, from: this);

  @override
  String toString() => r'isMessageStreamingProvider';
}

@ProviderFor(conversationBusyState)
final conversationBusyStateProvider = ConversationBusyStateProvider._();

final class ConversationBusyStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConversationBusyState>,
          ConversationBusyState,
          FutureOr<ConversationBusyState>
        >
    with
        $FutureModifier<ConversationBusyState>,
        $FutureProvider<ConversationBusyState> {
  ConversationBusyStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationBusyStateProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          conversationSelectedProvider,
          chatMessagesProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationBusyStateProvider.$allTransitiveDependencies0,
          ConversationBusyStateProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;
  static final $allTransitiveDependencies1 = chatMessagesProvider;

  @override
  String debugGetCreateSourceHash() => _$conversationBusyStateHash();

  @$internal
  @override
  $FutureProviderElement<ConversationBusyState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConversationBusyState> create(Ref ref) {
    return conversationBusyState(ref);
  }
}

String _$conversationBusyStateHash() =>
    r'8143fd429918c4de2ca489ac18e5adbe3775537d';

@ProviderFor(conversationQueuedDrafts)
final conversationQueuedDraftsProvider = ConversationQueuedDraftsProvider._();

final class ConversationQueuedDraftsProvider
    extends
        $FunctionalProvider<
          List<ConversationQueuedDraft>,
          List<ConversationQueuedDraft>,
          List<ConversationQueuedDraft>
        >
    with $Provider<List<ConversationQueuedDraft>> {
  ConversationQueuedDraftsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationQueuedDraftsProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationQueuedDraftsProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() => _$conversationQueuedDraftsHash();

  @$internal
  @override
  $ProviderElement<List<ConversationQueuedDraft>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ConversationQueuedDraft> create(Ref ref) {
    return conversationQueuedDrafts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ConversationQueuedDraft> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ConversationQueuedDraft>>(
        value,
      ),
    );
  }
}

String _$conversationQueuedDraftsHash() =>
    r'7d2c31a851b4b67b2239e180f10a8d6f2bb5d9d9';

@ProviderFor(conversationCompactionExecutionState)
final conversationCompactionExecutionStateProvider =
    ConversationCompactionExecutionStateProvider._();

final class ConversationCompactionExecutionStateProvider
    extends
        $FunctionalProvider<
          CompactionExecutionState?,
          CompactionExecutionState?,
          CompactionExecutionState?
        >
    with $Provider<CompactionExecutionState?> {
  ConversationCompactionExecutionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationCompactionExecutionStateProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationCompactionExecutionStateProvider
              .$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() =>
      _$conversationCompactionExecutionStateHash();

  @$internal
  @override
  $ProviderElement<CompactionExecutionState?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompactionExecutionState? create(Ref ref) {
    return conversationCompactionExecutionState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompactionExecutionState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompactionExecutionState?>(value),
    );
  }
}

String _$conversationCompactionExecutionStateHash() =>
    r'4c9ceb397968d65fffdf98fa866da936210dd803';

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
    r'5b6294cc874c79b7f7ba586e39f6aa5a234b37c1';

@ProviderFor(conversationUsedTokens)
final conversationUsedTokensProvider = ConversationUsedTokensProvider._();

final class ConversationUsedTokensProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  ConversationUsedTokensProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationUsedTokensProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          chatMessagesProvider,
          messagesStreamingProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationUsedTokensProvider.$allTransitiveDependencies0,
          ConversationUsedTokensProvider.$allTransitiveDependencies1,
          ConversationUsedTokensProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = chatMessagesProvider;
  static final $allTransitiveDependencies1 =
      ChatMessagesProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = messagesStreamingProvider;

  @override
  String debugGetCreateSourceHash() => _$conversationUsedTokensHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return conversationUsedTokens(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$conversationUsedTokensHash() =>
    r'c14b6ff48489c0e7716849f58f36b2a34d5cf69f';

@ProviderFor(conversationContextLimit)
final conversationContextLimitProvider = ConversationContextLimitProvider._();

final class ConversationContextLimitProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  ConversationContextLimitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationContextLimitProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          conversationSelectedProvider,
          conversationByIdStreamProvider,
          modelContextLimitProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ConversationContextLimitProvider.$allTransitiveDependencies0,
          ConversationContextLimitProvider.$allTransitiveDependencies1,
          ConversationContextLimitProvider.$allTransitiveDependencies2,
          ConversationContextLimitProvider.$allTransitiveDependencies3,
          ConversationContextLimitProvider.$allTransitiveDependencies4,
          ConversationContextLimitProvider.$allTransitiveDependencies5,
        },
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;
  static final $allTransitiveDependencies1 = conversationByIdStreamProvider;
  static final $allTransitiveDependencies2 = modelContextLimitProvider;
  static final $allTransitiveDependencies3 =
      ModelContextLimitProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies4 =
      ModelContextLimitProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies5 =
      ModelContextLimitProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$conversationContextLimitHash();

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    return conversationContextLimit(ref);
  }
}

String _$conversationContextLimitHash() =>
    r'aac733245a054f2361851780eee60d742b6db20b';

@ProviderFor(pendingToolCalls)
final pendingToolCallsProvider = PendingToolCallsProvider._();

final class PendingToolCallsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PendingToolCall>>,
          List<PendingToolCall>,
          FutureOr<List<PendingToolCall>>
        >
    with
        $FutureModifier<List<PendingToolCall>>,
        $FutureProvider<List<PendingToolCall>> {
  PendingToolCallsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingToolCallsProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          conversationSelectedProvider,
          chatMessagesProvider,
          conversationByIdStreamProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          PendingToolCallsProvider.$allTransitiveDependencies0,
          PendingToolCallsProvider.$allTransitiveDependencies1,
          PendingToolCallsProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;
  static final $allTransitiveDependencies1 = chatMessagesProvider;
  static final $allTransitiveDependencies2 = conversationByIdStreamProvider;

  @override
  String debugGetCreateSourceHash() => _$pendingToolCallsHash();

  @$internal
  @override
  $FutureProviderElement<List<PendingToolCall>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PendingToolCall>> create(Ref ref) {
    return pendingToolCalls(ref);
  }
}

String _$pendingToolCallsHash() => r'fbbe70350d0a7160e27d286cf865fccb3aeb6f99';
