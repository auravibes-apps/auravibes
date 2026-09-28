// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_draft.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConversationDraft)
final conversationDraftProvider = ConversationDraftFamily._();

final class ConversationDraftProvider
    extends $NotifierProvider<ConversationDraft, ChatDraft?> {
  ConversationDraftProvider._({
    required ConversationDraftFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationDraftProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationDraftHash();

  @override
  String toString() {
    return r'conversationDraftProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConversationDraft create() => ConversationDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatDraft? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatDraft?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationDraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationDraftHash() => r'c475d71fc6d821d89eee58fc12de3313edf2abbf';

final class ConversationDraftFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationDraft,
          ChatDraft?,
          ChatDraft?,
          ChatDraft?,
          (String, String)
        > {
  ConversationDraftFamily._()
    : super(
        retry: null,
        name: r'conversationDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ConversationDraftProvider call(String workspaceId, String conversationId) =>
      ConversationDraftProvider._(
        argument: (workspaceId, conversationId),
        from: this,
      );

  @override
  String toString() => r'conversationDraftProvider';
}

abstract class _$ConversationDraft extends $Notifier<ChatDraft?> {
  late final _$args = ref.$arg as (String, String);
  String get workspaceId => _$args.$1;
  String get conversationId => _$args.$2;

  ChatDraft? build(String workspaceId, String conversationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChatDraft?, ChatDraft?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatDraft?, ChatDraft?>,
              ChatDraft?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
