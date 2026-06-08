// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_skill_selector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationSkillSelector)
final conversationSkillSelectorProvider = ConversationSkillSelectorFamily._();

final class ConversationSkillSelectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConversationSkillSelectorState>,
          ConversationSkillSelectorState,
          FutureOr<ConversationSkillSelectorState>
        >
    with
        $FutureModifier<ConversationSkillSelectorState>,
        $FutureProvider<ConversationSkillSelectorState> {
  ConversationSkillSelectorProvider._({
    required ConversationSkillSelectorFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationSkillSelectorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationSkillSelectorHash();

  @override
  String toString() {
    return r'conversationSkillSelectorProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ConversationSkillSelectorState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConversationSkillSelectorState> create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationSkillSelector(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationSkillSelectorProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationSkillSelectorHash() =>
    r'a558da41d8f55c1d2802b505f6df357312be326f';

final class ConversationSkillSelectorFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ConversationSkillSelectorState>,
          (String, String)
        > {
  ConversationSkillSelectorFamily._()
    : super(
        retry: null,
        name: r'conversationSkillSelectorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConversationSkillSelectorProvider call(
    String workspaceId,
    String conversationId,
  ) => ConversationSkillSelectorProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationSkillSelectorProvider';
}
