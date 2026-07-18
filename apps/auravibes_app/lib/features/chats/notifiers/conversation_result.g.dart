// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_result.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConversationChatNotifier)
final conversationChatProvider = ConversationChatNotifierFamily._();

final class ConversationChatNotifierProvider
    extends
        $AsyncNotifierProvider<ConversationChatNotifier, ConversationResult> {
  ConversationChatNotifierProvider._({
    required ConversationChatNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationChatNotifierHash();

  @override
  String toString() {
    return r'conversationChatProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConversationChatNotifier create() => ConversationChatNotifier();

  @override
  bool operator ==(Object other) {
    return other is ConversationChatNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationChatNotifierHash() =>
    r'484de31a01243d58f961f0d826aebc17b0099cda';

final class ConversationChatNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationChatNotifier,
          AsyncValue<ConversationResult>,
          ConversationResult,
          FutureOr<ConversationResult>,
          (String, String)
        > {
  ConversationChatNotifierFamily._()
    : super(
        retry: null,
        name: r'conversationChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationChatNotifierProvider call(
    String workspaceId,
    String conversationId,
  ) => ConversationChatNotifierProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationChatProvider';
}

abstract class _$ConversationChatNotifier
    extends $AsyncNotifier<ConversationResult> {
  late final _$args = ref.$arg as (String, String);
  String get workspaceId => _$args.$1;
  String get conversationId => _$args.$2;

  FutureOr<ConversationResult> build(String workspaceId, String conversationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ConversationResult>, ConversationResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ConversationResult>, ConversationResult>,
              AsyncValue<ConversationResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
