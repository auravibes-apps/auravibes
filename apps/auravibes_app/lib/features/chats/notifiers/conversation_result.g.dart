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
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = conversationSelectedProvider;

  @override
  String debugGetCreateSourceHash() => _$conversationChatNotifierHash();

  @override
  String toString() {
    return r'conversationChatProvider'
        ''
        '($argument)';
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
    r'526ee62ff4de77408824af7343c34c84d43d4744';

final class ConversationChatNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationChatNotifier,
          AsyncValue<ConversationResult>,
          ConversationResult,
          FutureOr<ConversationResult>,
          String
        > {
  ConversationChatNotifierFamily._()
    : super(
        retry: null,
        name: r'conversationChatProvider',
        dependencies: <ProviderOrFamily>[conversationSelectedProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationChatNotifierProvider.$allTransitiveDependencies0,
        ],
        isAutoDispose: true,
      );

  ConversationChatNotifierProvider call(String workspaceId) =>
      ConversationChatNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'conversationChatProvider';
}

abstract class _$ConversationChatNotifier
    extends $AsyncNotifier<ConversationResult> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  FutureOr<ConversationResult> build(String workspaceId);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
