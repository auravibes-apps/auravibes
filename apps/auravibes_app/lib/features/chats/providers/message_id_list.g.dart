// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_id_list.dart';

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
    required (String, String) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageEntity>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return chatMessagesByConversation(ref, argument.$1, argument.$2);
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
    r'b014de623241f467421706f18302ba0b552c6ab7';

final class ChatMessagesByConversationFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<MessageEntity>>,
          (String, String)
        > {
  ChatMessagesByConversationFamily._()
    : super(
        retry: null,
        name: r'chatMessagesByConversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessagesByConversationProvider call(
    String workspaceId,
    String conversationId,
  ) => ChatMessagesByConversationProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'chatMessagesByConversationProvider';
}

@ProviderFor(latestAssistantMessageByConversation)
final latestAssistantMessageByConversationProvider =
    LatestAssistantMessageByConversationFamily._();

final class LatestAssistantMessageByConversationProvider
    extends
        $FunctionalProvider<
          AsyncValue<MessageEntity?>,
          MessageEntity?,
          Stream<MessageEntity?>
        >
    with $FutureModifier<MessageEntity?>, $StreamProvider<MessageEntity?> {
  LatestAssistantMessageByConversationProvider._({
    required LatestAssistantMessageByConversationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'latestAssistantMessageByConversationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$latestAssistantMessageByConversationHash();

  @override
  String toString() {
    return r'latestAssistantMessageByConversationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<MessageEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MessageEntity?> create(Ref ref) {
    final argument = this.argument as String;
    return latestAssistantMessageByConversation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LatestAssistantMessageByConversationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$latestAssistantMessageByConversationHash() =>
    r'30326a1f9e549e7654a95dcd0a6ff95245f7a47b';

final class LatestAssistantMessageByConversationFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MessageEntity?>, String> {
  LatestAssistantMessageByConversationFamily._()
    : super(
        retry: null,
        name: r'latestAssistantMessageByConversationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LatestAssistantMessageByConversationProvider call(String conversationId) =>
      LatestAssistantMessageByConversationProvider._(
        argument: conversationId,
        from: this,
      );

  @override
  String toString() => r'latestAssistantMessageByConversationProvider';
}

@ProviderFor(chatMessages)
final chatMessagesProvider = ChatMessagesFamily._();

final class ChatMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageEntity>>,
          List<MessageEntity>,
          Stream<List<MessageEntity>>
        >
    with
        $FutureModifier<List<MessageEntity>>,
        $StreamProvider<List<MessageEntity>> {
  ChatMessagesProvider._({
    required ChatMessagesFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'chatMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @override
  String toString() {
    return r'chatMessagesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageEntity>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return chatMessages(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesHash() => r'a4ce67ca9d5b070ad6f3f4ee0d660213df143ab5';

final class ChatMessagesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<MessageEntity>>,
          (String, String)
        > {
  ChatMessagesFamily._()
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessagesProvider call(String workspaceId, String conversationId) =>
      ChatMessagesProvider._(
        argument: (workspaceId, conversationId),
        from: this,
      );

  @override
  String toString() => r'chatMessagesProvider';
}

@ProviderFor(chatMessageIds)
final chatMessageIdsProvider = ChatMessageIdsFamily._();

final class ChatMessageIdsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  ChatMessageIdsProvider._({
    required ChatMessageIdsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'chatMessageIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMessageIdsHash();

  @override
  String toString() {
    return r'chatMessageIdsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    final argument = this.argument as (String, String);
    return chatMessageIds(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessageIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessageIdsHash() => r'398810cfca2c18c843b5400606c088cc74388a52';

final class ChatMessageIdsFamily extends $Family
    with $FunctionalFamilyOverride<List<String>, (String, String)> {
  ChatMessageIdsFamily._()
    : super(
        retry: null,
        name: r'chatMessageIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessageIdsProvider call(String workspaceId, String conversationId) =>
      ChatMessageIdsProvider._(
        argument: (workspaceId, conversationId),
        from: this,
      );

  @override
  String toString() => r'chatMessageIdsProvider';
}

@ProviderFor(messageConversationById)
final messageConversationByIdProvider = MessageConversationByIdFamily._();

final class MessageConversationByIdProvider
    extends $FunctionalProvider<MessageEntity?, MessageEntity?, MessageEntity?>
    with $Provider<MessageEntity?> {
  MessageConversationByIdProvider._({
    required MessageConversationByIdFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'messageConversationByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageConversationByIdHash();

  @override
  String toString() {
    return r'messageConversationByIdProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<MessageEntity?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageEntity? create(Ref ref) {
    final argument = this.argument as (String, String, String);
    return messageConversationById(ref, argument.$1, argument.$2, argument.$3);
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
    r'0db0999ea1c75f1d0ac51132767ec9d1a3029098';

final class MessageConversationByIdFamily extends $Family
    with $FunctionalFamilyOverride<MessageEntity?, (String, String, String)> {
  MessageConversationByIdFamily._()
    : super(
        retry: null,
        name: r'messageConversationByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MessageConversationByIdProvider call(
    String workspaceId,
    String conversationId,
    String messageId,
  ) => MessageConversationByIdProvider._(
    argument: (workspaceId, conversationId, messageId),
    from: this,
  );

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
    r'b3ad448813470d5bd7e581b2a83d212609f23dc2';

final class IsMessageStreamingFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsMessageStreamingFamily._()
    : super(
        retry: null,
        name: r'isMessageStreamingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsMessageStreamingProvider call(String messageId) =>
      IsMessageStreamingProvider._(argument: messageId, from: this);

  @override
  String toString() => r'isMessageStreamingProvider';
}

@ProviderFor(conversationBusyState)
final conversationBusyStateProvider = ConversationBusyStateFamily._();

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
  ConversationBusyStateProvider._({
    required ConversationBusyStateFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationBusyStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationBusyStateHash();

  @override
  String toString() {
    return r'conversationBusyStateProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ConversationBusyState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConversationBusyState> create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationBusyState(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationBusyStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationBusyStateHash() =>
    r'2ccd444f8c0f64261bb91b714fac7bc685193e3a';

final class ConversationBusyStateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ConversationBusyState>,
          (String, String)
        > {
  ConversationBusyStateFamily._()
    : super(
        retry: null,
        name: r'conversationBusyStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationBusyStateProvider call(
    String workspaceId,
    String conversationId,
  ) => ConversationBusyStateProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationBusyStateProvider';
}

@ProviderFor(conversationQueuedDrafts)
final conversationQueuedDraftsProvider = ConversationQueuedDraftsFamily._();

final class ConversationQueuedDraftsProvider
    extends
        $FunctionalProvider<
          List<ConversationQueuedDraft>,
          List<ConversationQueuedDraft>,
          List<ConversationQueuedDraft>
        >
    with $Provider<List<ConversationQueuedDraft>> {
  ConversationQueuedDraftsProvider._({
    required ConversationQueuedDraftsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationQueuedDraftsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationQueuedDraftsHash();

  @override
  String toString() {
    return r'conversationQueuedDraftsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<ConversationQueuedDraft>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ConversationQueuedDraft> create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationQueuedDrafts(ref, argument.$1, argument.$2);
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

  @override
  bool operator ==(Object other) {
    return other is ConversationQueuedDraftsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationQueuedDraftsHash() =>
    r'b1ef0979c72f465d5e777ee0d17d66c7b6aeae91';

final class ConversationQueuedDraftsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<ConversationQueuedDraft>,
          (String, String)
        > {
  ConversationQueuedDraftsFamily._()
    : super(
        retry: null,
        name: r'conversationQueuedDraftsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationQueuedDraftsProvider call(
    String _workspaceId,
    String conversationId,
  ) => ConversationQueuedDraftsProvider._(
    argument: (_workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationQueuedDraftsProvider';
}

@ProviderFor(conversationCompactionExecutionState)
final conversationCompactionExecutionStateProvider =
    ConversationCompactionExecutionStateFamily._();

final class ConversationCompactionExecutionStateProvider
    extends
        $FunctionalProvider<
          CompactionExecutionState?,
          CompactionExecutionState?,
          CompactionExecutionState?
        >
    with $Provider<CompactionExecutionState?> {
  ConversationCompactionExecutionStateProvider._({
    required ConversationCompactionExecutionStateFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationCompactionExecutionStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$conversationCompactionExecutionStateHash();

  @override
  String toString() {
    return r'conversationCompactionExecutionStateProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<CompactionExecutionState?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompactionExecutionState? create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationCompactionExecutionState(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompactionExecutionState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompactionExecutionState?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationCompactionExecutionStateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationCompactionExecutionStateHash() =>
    r'0b844c87eeb0566fb0a5c1e557c23877dbe25062';

final class ConversationCompactionExecutionStateFamily extends $Family
    with
        $FunctionalFamilyOverride<CompactionExecutionState?, (String, String)> {
  ConversationCompactionExecutionStateFamily._()
    : super(
        retry: null,
        name: r'conversationCompactionExecutionStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationCompactionExecutionStateProvider call(
    String _workspaceId,
    String conversationId,
  ) => ConversationCompactionExecutionStateProvider._(
    argument: (_workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationCompactionExecutionStateProvider';
}

@ProviderFor(conversationUsedTokens)
final conversationUsedTokensProvider = ConversationUsedTokensFamily._();

final class ConversationUsedTokensProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  ConversationUsedTokensProvider._({
    required ConversationUsedTokensFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationUsedTokensProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationUsedTokensHash();

  @override
  String toString() {
    return r'conversationUsedTokensProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationUsedTokens(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationUsedTokensProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationUsedTokensHash() =>
    r'f51bcf227a52727e2c61b2b9965805ebac5fb42e';

final class ConversationUsedTokensFamily extends $Family
    with $FunctionalFamilyOverride<int, (String, String)> {
  ConversationUsedTokensFamily._()
    : super(
        retry: null,
        name: r'conversationUsedTokensProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationUsedTokensProvider call(
    String workspaceId,
    String conversationId,
  ) => ConversationUsedTokensProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationUsedTokensProvider';
}

@ProviderFor(conversationContextLimit)
final conversationContextLimitProvider = ConversationContextLimitFamily._();

final class ConversationContextLimitProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  ConversationContextLimitProvider._({
    required ConversationContextLimitFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationContextLimitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationContextLimitHash();

  @override
  String toString() {
    return r'conversationContextLimitProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationContextLimit(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationContextLimitProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationContextLimitHash() =>
    r'f1f4331faf73756615c717d818e3fd7c67fc3a42';

final class ConversationContextLimitFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, (String, String)> {
  ConversationContextLimitFamily._()
    : super(
        retry: null,
        name: r'conversationContextLimitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationContextLimitProvider call(
    String workspaceId,
    String conversationId,
  ) => ConversationContextLimitProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationContextLimitProvider';
}

@ProviderFor(pendingToolCalls)
final pendingToolCallsProvider = PendingToolCallsFamily._();

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
  PendingToolCallsProvider._({
    required PendingToolCallsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'pendingToolCallsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingToolCallsHash();

  @override
  String toString() {
    return r'pendingToolCallsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PendingToolCall>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PendingToolCall>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return pendingToolCalls(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingToolCallsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingToolCallsHash() => r'14af85a9fb3c354b535d70c03d0fda8b93c6abb3';

final class PendingToolCallsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PendingToolCall>>,
          (String, String)
        > {
  PendingToolCallsFamily._()
    : super(
        retry: null,
        name: r'pendingToolCallsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PendingToolCallsProvider call(String workspaceId, String conversationId) =>
      PendingToolCallsProvider._(
        argument: (workspaceId, conversationId),
        from: this,
      );

  @override
  String toString() => r'pendingToolCallsProvider';
}
