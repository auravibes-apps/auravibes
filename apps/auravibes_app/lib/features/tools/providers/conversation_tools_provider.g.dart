// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversationToolsRepository)
final conversationToolsRepositoryProvider =
    ConversationToolsRepositoryProvider._();

final class ConversationToolsRepositoryProvider
    extends
        $FunctionalProvider<
          ConversationToolsRepository,
          ConversationToolsRepository,
          ConversationToolsRepository
        >
    with $Provider<ConversationToolsRepository> {
  ConversationToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationToolsRepositoryProvider',
        isAutoDispose: false,
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
    r'f01d06fe031c840ef6a9cc8ca75fd0dd30303eca';

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

@ProviderFor(ConversationToolsNotifier)
final conversationToolsProvider = ConversationToolsNotifierFamily._();

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
  ConversationToolsNotifierProvider._({
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
    r'18a60fa37809157827a1bf41b800ca13f060c81d';

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
  ConversationToolsNotifierFamily._()
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
    element.handleCreate(
      ref,
      () => build(
        workspaceId: _$args.workspaceId,
        conversationId: _$args.conversationId,
      ),
    );
  }
}

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)

@ProviderFor(ContextAwareToolsNotifier)
final contextAwareToolsProvider = ContextAwareToolsNotifierFamily._();

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)
final class ContextAwareToolsNotifierProvider
    extends $AsyncNotifierProvider<ContextAwareToolsNotifier, List<String>> {
  /// Provider to get context-aware tools for chat
  /// (conversation -> workspace -> app defaults)
  ContextAwareToolsNotifierProvider._({
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
  ContextAwareToolsNotifierFamily._()
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
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        conversationId: _$args.conversationId,
        workspaceId: _$args.workspaceId,
      ),
    );
  }
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

@ProviderFor(ContextAwareToolEntitiesNotifier)
final contextAwareToolEntitiesProvider =
    ContextAwareToolEntitiesNotifierFamily._();

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)
final class ContextAwareToolEntitiesNotifierProvider
    extends
        $AsyncNotifierProvider<
          ContextAwareToolEntitiesNotifier,
          List<WorkspaceToolEntity>
        > {
  /// Provider to get context-aware tools as full entities for chat.
  ///
  /// Returns [WorkspaceToolEntity] list with table IDs needed for
  /// generating composite tool IDs.
  /// (conversation -> workspace -> app defaults)
  ContextAwareToolEntitiesNotifierProvider._({
    required ContextAwareToolEntitiesNotifierFamily super.from,
    required ({String conversationId, String workspaceId}) super.argument,
  }) : super(
         retry: null,
         name: r'contextAwareToolEntitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contextAwareToolEntitiesNotifierHash();

  @override
  String toString() {
    return r'contextAwareToolEntitiesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContextAwareToolEntitiesNotifier create() =>
      ContextAwareToolEntitiesNotifier();

  @override
  bool operator ==(Object other) {
    return other is ContextAwareToolEntitiesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextAwareToolEntitiesNotifierHash() =>
    r'c8abafcf7f10b05d6b8c54e4ea92f44bac02a99b';

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

final class ContextAwareToolEntitiesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ContextAwareToolEntitiesNotifier,
          AsyncValue<List<WorkspaceToolEntity>>,
          List<WorkspaceToolEntity>,
          FutureOr<List<WorkspaceToolEntity>>,
          ({String conversationId, String workspaceId})
        > {
  ContextAwareToolEntitiesNotifierFamily._()
    : super(
        retry: null,
        name: r'contextAwareToolEntitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get context-aware tools as full entities for chat.
  ///
  /// Returns [WorkspaceToolEntity] list with table IDs needed for
  /// generating composite tool IDs.
  /// (conversation -> workspace -> app defaults)

  ContextAwareToolEntitiesNotifierProvider call({
    required String conversationId,
    required String workspaceId,
  }) => ContextAwareToolEntitiesNotifierProvider._(
    argument: (conversationId: conversationId, workspaceId: workspaceId),
    from: this,
  );

  @override
  String toString() => r'contextAwareToolEntitiesProvider';
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

abstract class _$ContextAwareToolEntitiesNotifier
    extends $AsyncNotifier<List<WorkspaceToolEntity>> {
  late final _$args = ref.$arg as ({String conversationId, String workspaceId});
  String get conversationId => _$args.conversationId;
  String get workspaceId => _$args.workspaceId;

  FutureOr<List<WorkspaceToolEntity>> build({
    required String conversationId,
    required String workspaceId,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<WorkspaceToolEntity>>,
              List<WorkspaceToolEntity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<WorkspaceToolEntity>>,
                List<WorkspaceToolEntity>
              >,
              AsyncValue<List<WorkspaceToolEntity>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        conversationId: _$args.conversationId,
        workspaceId: _$args.workspaceId,
      ),
    );
  }
}
