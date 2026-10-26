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
    r'2fb28a708491102852ec40ee64a683fc68ca28e7';

@ProviderFor(workspaceConversationCommandUsecase)
final workspaceConversationCommandUsecaseProvider =
    WorkspaceConversationCommandUsecaseFamily._();

final class WorkspaceConversationCommandUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceConversationCommandUsecase>,
          WorkspaceConversationCommandUsecase,
          FutureOr<WorkspaceConversationCommandUsecase>
        >
    with
        $FutureModifier<WorkspaceConversationCommandUsecase>,
        $FutureProvider<WorkspaceConversationCommandUsecase> {
  WorkspaceConversationCommandUsecaseProvider._({
    required WorkspaceConversationCommandUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceConversationCommandUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$workspaceConversationCommandUsecaseHash();

  @override
  String toString() {
    return r'workspaceConversationCommandUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceConversationCommandUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceConversationCommandUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceConversationCommandUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceConversationCommandUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceConversationCommandUsecaseHash() =>
    r'b810e0120c8b9e60d3b99af02b62639aadb6506d';

final class WorkspaceConversationCommandUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceConversationCommandUsecase>,
          String
        > {
  WorkspaceConversationCommandUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceConversationCommandUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceConversationCommandUsecaseProvider call(String workspaceId) =>
      WorkspaceConversationCommandUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'workspaceConversationCommandUsecaseProvider';
}
