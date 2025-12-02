// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationToolsRepository)
const conversationToolsRepositoryProvider =
    ConversationToolsRepositoryProvider._();

final class ConversationToolsRepositoryProvider
    extends
        $FunctionalProvider<
          ConversationToolsRepository,
          ConversationToolsRepository,
          ConversationToolsRepository
        >
    with $Provider<ConversationToolsRepository> {
  const ConversationToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationToolsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationToolsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ConversationToolsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConversationToolsRepository create(Ref ref) {
    return conversationToolsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationToolsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationToolsRepository>(value),
    );
  }
}

String _$conversationToolsRepositoryHash() =>
    r'e3e65f8c9feab2c64ec51fc9ae9464e124258a26';

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

@ProviderFor(ConversationToolsNotifier)
const conversationToolsProvider = ConversationToolsNotifierFamily._();

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.
final class ConversationToolsNotifierProvider
    extends
        $AsyncNotifierProvider<
          ConversationToolsNotifier,
          List<ConversationToolState>
        > {
  /// Provider for managing conversation tool settings
  ///
  /// Returns a list of all workspace tools with their conversation-level states.
  const ConversationToolsNotifierProvider._({
    required ConversationToolsNotifierFamily super.from,
    required ({String workspaceId, String? conversationId}) super.argument,
  }) : super(
         retry: null,
         name: r'conversationToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationToolsNotifierHash();

  @override
  String toString() {
    return r'conversationToolsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConversationToolsNotifier create() => ConversationToolsNotifier();

  @override
  bool operator ==(Object other) {
    return other is ConversationToolsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationToolsNotifierHash() =>
    r'a21b2b8e607e818c5273be0e11471b21604c0a20';

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

final class ConversationToolsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationToolsNotifier,
          AsyncValue<List<ConversationToolState>>,
          List<ConversationToolState>,
          FutureOr<List<ConversationToolState>>,
          ({String workspaceId, String? conversationId})
        > {
  const ConversationToolsNotifierFamily._()
    : super(
        retry: null,
        name: r'conversationToolsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for managing conversation tool settings
  ///
  /// Returns a list of all workspace tools with their conversation-level states.

  ConversationToolsNotifierProvider call({
    required String workspaceId,
    String? conversationId,
  }) => ConversationToolsNotifierProvider._(
    argument: (workspaceId: workspaceId, conversationId: conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationToolsProvider';
}

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

abstract class _$ConversationToolsNotifier
    extends $AsyncNotifier<List<ConversationToolState>> {
  late final _$args =
      ref.$arg as ({String workspaceId, String? conversationId});
  String get workspaceId => _$args.workspaceId;
  String? get conversationId => _$args.conversationId;

  FutureOr<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      workspaceId: _$args.workspaceId,
      conversationId: _$args.conversationId,
    );
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ConversationToolState>>,
              List<ConversationToolState>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ConversationToolState>>,
                List<ConversationToolState>
              >,
              AsyncValue<List<ConversationToolState>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)

@ProviderFor(ContextAwareToolsNotifier)
const contextAwareToolsProvider = ContextAwareToolsNotifierFamily._();

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)
final class ContextAwareToolsNotifierProvider
    extends $AsyncNotifierProvider<ContextAwareToolsNotifier, List<String>> {
  /// Provider to get context-aware tools for chat
  /// (conversation -> workspace -> app defaults)
  const ContextAwareToolsNotifierProvider._({
    required ContextAwareToolsNotifierFamily super.from,
    required ({String conversationId, String workspaceId}) super.argument,
  }) : super(
         retry: null,
         name: r'contextAwareToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contextAwareToolsNotifierHash();

  @override
  String toString() {
    return r'contextAwareToolsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContextAwareToolsNotifier create() => ContextAwareToolsNotifier();

  @override
  bool operator ==(Object other) {
    return other is ContextAwareToolsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextAwareToolsNotifierHash() =>
    r'39112a1f954d004b0ddc41787f7d7c91b64cf73e';

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)

final class ContextAwareToolsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContextAwareToolsNotifier,
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>,
          ({String conversationId, String workspaceId})
        > {
  const ContextAwareToolsNotifierFamily._()
    : super(
        retry: null,
        name: r'contextAwareToolsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get context-aware tools for chat
  /// (conversation -> workspace -> app defaults)

  ContextAwareToolsNotifierProvider call({
    required String conversationId,
    required String workspaceId,
  }) => ContextAwareToolsNotifierProvider._(
    argument: (conversationId: conversationId, workspaceId: workspaceId),
    from: this,
  );

  @override
  String toString() => r'contextAwareToolsProvider';
}

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)

abstract class _$ContextAwareToolsNotifier
    extends $AsyncNotifier<List<String>> {
  late final _$args = ref.$arg as ({String conversationId, String workspaceId});
  String get conversationId => _$args.conversationId;
  String get workspaceId => _$args.workspaceId;

  FutureOr<List<String>> build({
    required String conversationId,
    required String workspaceId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      conversationId: _$args.conversationId,
      workspaceId: _$args.workspaceId,
    );
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
