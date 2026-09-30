// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_skill_context_runtime.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConversationSkillContextRuntime)
final conversationSkillContextRuntimeProvider =
    ConversationSkillContextRuntimeProvider._();

final class ConversationSkillContextRuntimeProvider
    extends
        $NotifierProvider<
          ConversationSkillContextRuntime,
          Map<String, ConversationSkillContextSnapshot>
        > {
  ConversationSkillContextRuntimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationSkillContextRuntimeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationSkillContextRuntimeHash();

  @$internal
  @override
  ConversationSkillContextRuntime create() => ConversationSkillContextRuntime();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Map<String, ConversationSkillContextSnapshot> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, ConversationSkillContextSnapshot>>(
            value,
          ),
    );
  }
}

String _$conversationSkillContextRuntimeHash() =>
    r'7b515616cdaea61f97d26083a2083cc2291b6c81';

abstract class _$ConversationSkillContextRuntime
    extends $Notifier<Map<String, ConversationSkillContextSnapshot>> {
  Map<String, ConversationSkillContextSnapshot> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, ConversationSkillContextSnapshot>,
              Map<String, ConversationSkillContextSnapshot>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, ConversationSkillContextSnapshot>,
                Map<String, ConversationSkillContextSnapshot>
              >,
              Map<String, ConversationSkillContextSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
