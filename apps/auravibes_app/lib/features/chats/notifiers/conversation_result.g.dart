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
  static final $allTransitiveDependencies1 = conversationByIdStreamProvider;
  static final $allTransitiveDependencies2 =
      ConversationByIdStreamProvider.$allTransitiveDependencies0;

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
    r'46fb29dbf89f2a125d8ba2b23c5ed37eeab61aef';

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
        dependencies: <ProviderOrFamily>[
          conversationSelectedProvider,
          conversationByIdStreamProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ConversationChatNotifierProvider.$allTransitiveDependencies0,
          ConversationChatNotifierProvider.$allTransitiveDependencies1,
          ConversationChatNotifierProvider.$allTransitiveDependencies2,
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
