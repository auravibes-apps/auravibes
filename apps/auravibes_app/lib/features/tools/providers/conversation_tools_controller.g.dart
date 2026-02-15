// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_tools_controller.dart';

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

@ProviderFor(ConversationToolsController)
final conversationToolsControllerProvider =
    ConversationToolsControllerFamily._();

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.
final class ConversationToolsControllerProvider
    extends
        $AsyncNotifierProvider<
          ConversationToolsController,
          List<ConversationToolState>
        > {
  /// Provider for managing conversation tool settings
  ///
  /// Returns a list of all workspace tools with their conversation-level states.
  ConversationToolsControllerProvider._({
    required ConversationToolsControllerFamily super.from,
    required ({String workspaceId, String? conversationId}) super.argument,
  }) : super(
         retry: null,
         name: r'conversationToolsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationToolsControllerHash();

  @override
  String toString() {
    return r'conversationToolsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConversationToolsController create() => ConversationToolsController();

  @override
  bool operator ==(Object other) {
    return other is ConversationToolsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationToolsControllerHash() =>
    r'dd50a8725479c0aeb6bc78ad33df2198700a39c8';

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

final class ConversationToolsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationToolsController,
          AsyncValue<List<ConversationToolState>>,
          List<ConversationToolState>,
          FutureOr<List<ConversationToolState>>,
          ({String workspaceId, String? conversationId})
        > {
  ConversationToolsControllerFamily._()
    : super(
        retry: null,
        name: r'conversationToolsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for managing conversation tool settings
  ///
  /// Returns a list of all workspace tools with their conversation-level states.

  ConversationToolsControllerProvider call({
    required String workspaceId,
    String? conversationId,
  }) => ConversationToolsControllerProvider._(
    argument: (workspaceId: workspaceId, conversationId: conversationId),
    from: this,
  );

  @override
  String toString() => r'conversationToolsControllerProvider';
}

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.

abstract class _$ConversationToolsController
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

@ProviderFor(ContextAwareToolsController)
final contextAwareToolsControllerProvider =
    ContextAwareToolsControllerFamily._();

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)
final class ContextAwareToolsControllerProvider
    extends $AsyncNotifierProvider<ContextAwareToolsController, List<String>> {
  /// Provider to get context-aware tools for chat
  /// (conversation -> workspace -> app defaults)
  ContextAwareToolsControllerProvider._({
    required ContextAwareToolsControllerFamily super.from,
    required ({String conversationId, String workspaceId}) super.argument,
  }) : super(
         retry: null,
         name: r'contextAwareToolsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contextAwareToolsControllerHash();

  @override
  String toString() {
    return r'contextAwareToolsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContextAwareToolsController create() => ContextAwareToolsController();

  @override
  bool operator ==(Object other) {
    return other is ContextAwareToolsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextAwareToolsControllerHash() =>
    r'7a81e090490e04333ef54471fcceed01b3c11895';

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)

final class ContextAwareToolsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ContextAwareToolsController,
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>,
          ({String conversationId, String workspaceId})
        > {
  ContextAwareToolsControllerFamily._()
    : super(
        retry: null,
        name: r'contextAwareToolsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get context-aware tools for chat
  /// (conversation -> workspace -> app defaults)

  ContextAwareToolsControllerProvider call({
    required String conversationId,
    required String workspaceId,
  }) => ContextAwareToolsControllerProvider._(
    argument: (conversationId: conversationId, workspaceId: workspaceId),
    from: this,
  );

  @override
  String toString() => r'contextAwareToolsControllerProvider';
}

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)

abstract class _$ContextAwareToolsController
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

@ProviderFor(ContextAwareToolEntitiesController)
final contextAwareToolEntitiesControllerProvider =
    ContextAwareToolEntitiesControllerFamily._();

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)
final class ContextAwareToolEntitiesControllerProvider
    extends
        $AsyncNotifierProvider<
          ContextAwareToolEntitiesController,
          List<WorkspaceToolEntity>
        > {
  /// Provider to get context-aware tools as full entities for chat.
  ///
  /// Returns [WorkspaceToolEntity] list with table IDs needed for
  /// generating composite tool IDs.
  /// (conversation -> workspace -> app defaults)
  ContextAwareToolEntitiesControllerProvider._({
    required ContextAwareToolEntitiesControllerFamily super.from,
    required ({String conversationId, String workspaceId}) super.argument,
  }) : super(
         retry: null,
         name: r'contextAwareToolEntitiesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$contextAwareToolEntitiesControllerHash();

  @override
  String toString() {
    return r'contextAwareToolEntitiesControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContextAwareToolEntitiesController create() =>
      ContextAwareToolEntitiesController();

  @override
  bool operator ==(Object other) {
    return other is ContextAwareToolEntitiesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contextAwareToolEntitiesControllerHash() =>
    r'c90990ef82f84448a0767d147f262aa2b898ec51';

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

final class ContextAwareToolEntitiesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ContextAwareToolEntitiesController,
          AsyncValue<List<WorkspaceToolEntity>>,
          List<WorkspaceToolEntity>,
          FutureOr<List<WorkspaceToolEntity>>,
          ({String conversationId, String workspaceId})
        > {
  ContextAwareToolEntitiesControllerFamily._()
    : super(
        retry: null,
        name: r'contextAwareToolEntitiesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get context-aware tools as full entities for chat.
  ///
  /// Returns [WorkspaceToolEntity] list with table IDs needed for
  /// generating composite tool IDs.
  /// (conversation -> workspace -> app defaults)

  ContextAwareToolEntitiesControllerProvider call({
    required String conversationId,
    required String workspaceId,
  }) => ContextAwareToolEntitiesControllerProvider._(
    argument: (conversationId: conversationId, workspaceId: workspaceId),
    from: this,
  );

  @override
  String toString() => r'contextAwareToolEntitiesControllerProvider';
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)

abstract class _$ContextAwareToolEntitiesController
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
