// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_conversation_context_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceConversationContextUsecase)
final workspaceConversationContextUsecaseProvider =
    WorkspaceConversationContextUsecaseFamily._();

final class WorkspaceConversationContextUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ManageWorkspaceChatContextUsecase>,
          ManageWorkspaceChatContextUsecase,
          FutureOr<ManageWorkspaceChatContextUsecase>
        >
    with
        $FutureModifier<ManageWorkspaceChatContextUsecase>,
        $FutureProvider<ManageWorkspaceChatContextUsecase> {
  WorkspaceConversationContextUsecaseProvider._({
    required WorkspaceConversationContextUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceConversationContextUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$workspaceConversationContextUsecaseHash();

  @override
  String toString() {
    return r'workspaceConversationContextUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ManageWorkspaceChatContextUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ManageWorkspaceChatContextUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceConversationContextUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceConversationContextUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceConversationContextUsecaseHash() =>
    r'1cd3911f87ace4a4c0a8f7ced9040ff194ede402';

final class WorkspaceConversationContextUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ManageWorkspaceChatContextUsecase>,
          String
        > {
  WorkspaceConversationContextUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceConversationContextUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceConversationContextUsecaseProvider call(String workspaceId) =>
      WorkspaceConversationContextUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'workspaceConversationContextUsecaseProvider';
}

@ProviderFor(workspaceConversationContext)
final workspaceConversationContextProvider =
    WorkspaceConversationContextFamily._();

final class WorkspaceConversationContextProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceConversationContext>,
          WorkspaceConversationContext,
          FutureOr<WorkspaceConversationContext>
        >
    with
        $FutureModifier<WorkspaceConversationContext>,
        $FutureProvider<WorkspaceConversationContext> {
  WorkspaceConversationContextProvider._({
    required WorkspaceConversationContextFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceConversationContextProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceConversationContextHash();

  @override
  String toString() {
    return r'workspaceConversationContextProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceConversationContext> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceConversationContext> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceConversationContext(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceConversationContextProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceConversationContextHash() =>
    r'b8c151f3b336ebdbb2c2996988eafe58752af84c';

final class WorkspaceConversationContextFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceConversationContext>,
          (String, String)
        > {
  WorkspaceConversationContextFamily._()
    : super(
        retry: null,
        name: r'workspaceConversationContextProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceConversationContextProvider call(
    String workspaceId,
    String conversationId,
  ) => WorkspaceConversationContextProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'workspaceConversationContextProvider';
}
