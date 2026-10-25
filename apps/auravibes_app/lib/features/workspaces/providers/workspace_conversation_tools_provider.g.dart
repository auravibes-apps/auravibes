// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_conversation_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceConversationTools)
final workspaceConversationToolsProvider =
    WorkspaceConversationToolsProvider._();

final class WorkspaceConversationToolsProvider
    extends
        $FunctionalProvider<
          WorkspaceConversationToolsUsecase,
          WorkspaceConversationToolsUsecase,
          WorkspaceConversationToolsUsecase
        >
    with $Provider<WorkspaceConversationToolsUsecase> {
  WorkspaceConversationToolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceConversationToolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceConversationToolsHash();

  @$internal
  @override
  $ProviderElement<WorkspaceConversationToolsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceConversationToolsUsecase create(Ref ref) {
    return workspaceConversationTools(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceConversationToolsUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceConversationToolsUsecase>(
        value,
      ),
    );
  }
}

String _$workspaceConversationToolsHash() =>
    r'6a5fad32215797b64f7339f1054366d1f6d50b4b';
