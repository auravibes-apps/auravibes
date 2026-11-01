import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ConversationBranchNavigationButton({
  required final String workspaceId,
  required final ConversationEntity conversation,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = 'chats_screens.chat_conversation.branch_navigation'.tr();

    return AuraIconButton(
      key: key ?? const ValueKey<String>('conversation-branch-navigation'),
      icon: Icons.account_tree_outlined,
      size: .large,
      onPressed: () => _showBranchNavigation(context),
      semanticLabel: label,
      tooltip: label,
    );
  }

  void _showBranchNavigation(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    _presentBranchNavigation(context);
  }

  void _presentBranchNavigation(BuildContext context) {
    final _ = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _ConversationBranchNavigationSheet(
        workspaceId: workspaceId,
        conversation: conversation,
        onOpenConversation: (target) =>
            _openConversation(context, sheetContext, target),
      ),
    );
  }

  void _openConversation(
    BuildContext screenContext,
    BuildContext sheetContext,
    ConversationEntity target,
  ) {
    Navigator.of(sheetContext).pop();
    if (!screenContext.mounted) return;
    ConversationRoute(
      workspaceId: target.workspaceId,
      chatId: target.id,
    ).go(screenContext);
  }
}

typedef _BranchNavigationState = ({
  AsyncValue<List<ConversationEntity>> childBranches,
  AsyncValue<ConversationEntity?>? parentConversation,
  AsyncValue<List<ConversationEntity>>? siblingBranches,
  VoidCallback onRetryChildren,
  VoidCallback? onRetryParent,
  VoidCallback? onRetrySiblings,
});

typedef _BranchConversationState = ({
  AsyncValue<List<ConversationEntity>> childBranches,
  AsyncValue<ConversationEntity?>? parentConversation,
  AsyncValue<List<ConversationEntity>>? siblingBranches,
});

typedef _BranchNavigationActions = ({
  VoidCallback onRetryChildren,
  VoidCallback? onRetryParent,
  VoidCallback? onRetrySiblings,
});

class const _ConversationBranchNavigationSheet({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _BranchNavigationContents(
        conversation: conversation,
        navigation: _watchBranchNavigationState(ref, workspaceId, conversation),
        onOpenConversation: onOpenConversation,
      );
}

_BranchNavigationState _watchBranchNavigationState(
  WidgetRef ref,
  String workspaceId,
  ConversationEntity conversation,
) {
  final branchState = _watchBranchConversations(ref, workspaceId, conversation);
  final actions = _branchNavigationActions(ref, workspaceId, conversation);

  return (
    childBranches: branchState.childBranches,
    parentConversation: branchState.parentConversation,
    siblingBranches: branchState.siblingBranches,
    onRetryChildren: actions.onRetryChildren,
    onRetryParent: actions.onRetryParent,
    onRetrySiblings: actions.onRetrySiblings,
  );
}

_BranchConversationState _watchBranchConversations(
  WidgetRef ref,
  String workspaceId,
  ConversationEntity conversation,
) {
  final parentId = conversation.forkSourceConversationId;

  return (
    childBranches: ref.watch(
      forkedConversationsStreamProvider((
        workspaceId: workspaceId,
        sourceConversationId: conversation.id,
      )),
    ),
    parentConversation: _watchParentConversation(ref, workspaceId, parentId),
    siblingBranches: _watchSiblingBranches(ref, workspaceId, parentId),
  );
}

_BranchNavigationActions _branchNavigationActions(
  WidgetRef ref,
  String workspaceId,
  ConversationEntity conversation,
) {
  final parentId = conversation.forkSourceConversationId;

  return (
    onRetryChildren: _retryForkedConversations(
      ref,
      workspaceId,
      conversation.id,
    ),
    onRetryParent: _retryParentConversation(ref, workspaceId, parentId),
    onRetrySiblings: parentId == null
        ? null
        : _retryForkedConversations(ref, workspaceId, parentId),
  );
}

AsyncValue<ConversationEntity?>? _watchParentConversation(
  WidgetRef ref,
  String workspaceId,
  String? parentId,
) => parentId == null
    ? null
    : ref.watch(
        conversationByIdStreamProvider(workspaceId, conversationId: parentId),
      );

AsyncValue<List<ConversationEntity>>? _watchSiblingBranches(
  WidgetRef ref,
  String workspaceId,
  String? parentId,
) => parentId == null
    ? null
    : ref.watch(
        forkedConversationsStreamProvider((
          workspaceId: workspaceId,
          sourceConversationId: parentId,
        )),
      );

VoidCallback _retryForkedConversations(
  WidgetRef ref,
  String workspaceId,
  String sourceConversationId,
) =>
    () => ref.invalidate(
      forkedConversationsStreamProvider((
        workspaceId: workspaceId,
        sourceConversationId: sourceConversationId,
      )),
    );

VoidCallback? _retryParentConversation(
  WidgetRef ref,
  String workspaceId,
  String? parentId,
) => parentId == null
    ? null
    : () => ref.invalidate(
        conversationByIdStreamProvider(workspaceId, conversationId: parentId),
      );

class const _BranchNavigationContents({
  required final ConversationEntity conversation,
  required final _BranchNavigationState navigation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.8,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: _BranchNavigationSections(
          conversation: conversation,
          navigation: navigation,
          onOpenConversation: onOpenConversation,
        ),
      ),
    ),
  );
}

class const _BranchNavigationSections({
  required final ConversationEntity conversation,
  required final _BranchNavigationState navigation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const _BranchNavigationTitle(),
      _CurrentConversationBranchSection(conversation: conversation),
      _RelatedBranchSections(
        conversation: conversation,
        navigation: navigation,
        onOpenConversation: onOpenConversation,
      ),
      _ChildConversationBranches(
        conversation: conversation,
        navigation: navigation,
        onOpenConversation: onOpenConversation,
      ),
      const SizedBox(height: 8),
    ],
  );
}

class const _RelatedBranchSections({
  required final ConversationEntity conversation,
  required final _BranchNavigationState navigation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (conversation.forkSourceConversationId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _ParentConversationSection(
          conversation: conversation,
          navigation: navigation,
          onOpenConversation: onOpenConversation,
        ),
        _SiblingConversationBranches(
          conversation: conversation,
          navigation: navigation,
          onOpenConversation: onOpenConversation,
        ),
      ],
    );
  }
}

class const _BranchNavigationTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Text(
        'chats_screens.chat_conversation.branch_navigation'.tr(),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
    ],
  );
}

class const _CurrentConversationBranchSection({
  required final ConversationEntity conversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _BranchSectionTitle(
        title: 'chats_screens.chat_conversation.current_branch'.tr(),
      ),
      _CurrentBranchTile(conversation: conversation),
    ],
  );
}

class const _SiblingConversationBranches({
  required final ConversationEntity conversation,
  required final _BranchNavigationState navigation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _BranchChoicesSection(
    label: 'chats_screens.chat_conversation.other_branches'.tr(),
    branches: navigation.siblingBranches!,
    currentConversationId: conversation.id,
    onOpenConversation: onOpenConversation,
    onRetry: navigation.onRetrySiblings!,
  );
}

class const _ChildConversationBranches({
  required final ConversationEntity conversation,
  required final _BranchNavigationState navigation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends StatelessWidget {
  bool get _noRelatedBranches =>
      conversation.forkSourceConversationId == null &&
      switch (navigation.childBranches) {
        AsyncData() => _branchChoices(
          navigation.childBranches,
          conversation.id,
        ).isEmpty,
        _ => false,
      };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _BranchChoicesSection(
        label: 'chats_screens.chat_conversation.branches_from_this_conversation'
            .tr(),
        branches: navigation.childBranches,
        currentConversationId: conversation.id,
        onOpenConversation: onOpenConversation,
        onRetry: navigation.onRetryChildren,
      ),
      if (_noRelatedBranches) const _NoRelatedBranchesMessage(),
    ],
  );
}

class const _NoRelatedBranchesMessage() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: TextLocale(
      'chats_screens.chat_conversation.no_other_branches',
      textAlign: .center,
    ),
  );
}

List<ConversationEntity> _branchChoices(
  AsyncValue<List<ConversationEntity>> branches,
  String currentConversationId,
) => switch (branches) {
  AsyncData(value: final values) =>
    values.where((value) => value.id != currentConversationId).toList(),
  _ => const <ConversationEntity>[],
};

class const _BranchSectionTitle({required final String title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: context.auraColors.onSurfaceVariant),
    ),
  );
}

class const _CurrentBranchTile({required final ConversationEntity conversation})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    selected: true,
    child: ListTile(
      key: const ValueKey<String>('conversation-current-branch'),
      selected: true,
      leading: const Icon(Icons.check_circle_outline),
      title: Text(conversation.title, maxLines: 1, overflow: .ellipsis),
      subtitle: const TextLocale(
        'chats_screens.chat_conversation.current_branch',
      ),
    ),
  );
}

class const _ParentConversationSection({
  required final ConversationEntity conversation,
  required final _BranchNavigationState navigation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      const _BranchSectionTitle(
        title: 'chats_screens.chat_conversation.parent_conversation',
      ),
      _ParentConversationStatus(
        sourceTitle: conversation.forkSourceTitle,
        parentConversation: navigation.parentConversation!,
        onOpenConversation: onOpenConversation,
        onRetry: navigation.onRetryParent!,
      ),
    ],
  );
}

class const _ParentConversationStatus({
  required final String? sourceTitle,
  required final AsyncValue<ConversationEntity?> parentConversation,
  required final ValueChanged<ConversationEntity> onOpenConversation,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (parentConversation) {
    AsyncData(value: final parent?) => _BranchConversationTile(
      conversation: parent,
      leadingIcon: Icons.arrow_upward_outlined,
      onTap: () => onOpenConversation(parent),
    ),
    AsyncData() => _UnavailableParentTile(sourceTitle: sourceTitle),
    AsyncLoading() => _ParentConversationLoadingTile(sourceTitle: sourceTitle),
    AsyncError() => _BranchLoadError(onRetry: onRetry),
  };
}

class const _UnavailableParentTile({required final String? sourceTitle})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: const ValueKey<String>('conversation-branch-parent-unavailable'),
    enabled: false,
    leading: const Icon(Icons.link_off_outlined),
    title: _SourceConversationTitle(sourceTitle: sourceTitle),
    subtitle: const TextLocale(
      'chats_screens.chat_conversation.parent_unavailable',
    ),
  );
}

class const _ParentConversationLoadingTile({required final String? sourceTitle})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.arrow_upward_outlined),
    title: _SourceConversationTitle(sourceTitle: sourceTitle),
    trailing: const SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class const _SourceConversationTitle({required final String? sourceTitle})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = sourceTitle?.trim();
    if (title == null || title.isEmpty) {
      return const TextLocale(
        'chats_screens.chat_conversation.parent_conversation',
        maxLines: 1,
        overflow: .ellipsis,
      );
    }

    return Text(title, maxLines: 1, overflow: .ellipsis);
  }
}

class const _BranchChoicesSection({
  required final String label,
  required final AsyncValue<List<ConversationEntity>> branches,
  required final String currentConversationId,
  required final ValueChanged<ConversationEntity> onOpenConversation,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final choices = _branchChoices(branches, currentConversationId);

    return switch (branches) {
      AsyncData() when choices.isEmpty => const SizedBox.shrink(),
      AsyncData() => _BranchChoicesList(
        label: label,
        choices: choices,
        onOpenConversation: onOpenConversation,
      ),
      AsyncLoading() => _BranchLoadingSection(label: label),
      AsyncError() => _BranchLoadErrorSection(label: label, onRetry: onRetry),
    };
  }
}

class const _BranchChoicesList({
  required final String label,
  required final List<ConversationEntity> choices,
  required final ValueChanged<ConversationEntity> onOpenConversation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _BranchSectionTitle(title: label),
      for (final conversation in choices)
        _BranchConversationTile(
          conversation: conversation,
          leadingIcon: Icons.subdirectory_arrow_right_outlined,
          onTap: () => onOpenConversation(conversation),
        ),
    ],
  );
}

class const _BranchConversationTile({
  required final ConversationEntity conversation,
  required final IconData leadingIcon,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey<String>('conversation-branch-${conversation.id}'),
    leading: Icon(leadingIcon),
    title: Text(conversation.title, maxLines: 1, overflow: .ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class const _BranchLoadingSection({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _BranchSectionTitle(title: label),
      const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    ],
  );
}

class const _BranchLoadErrorSection({
  required final String label,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _BranchSectionTitle(title: label),
      _BranchLoadError(onRetry: onRetry),
    ],
  );
}

class const _BranchLoadError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: .start,
      children: [
        const TextLocale('chats_screens.chat_conversation.branch_load_error'),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const TextLocale(
            'chats_screens.chat_conversation.branch_retry',
          ),
        ),
      ],
    ),
  );
}
