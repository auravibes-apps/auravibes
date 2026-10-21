import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/providers/message_bookmarks_provider.dart';
import 'package:auravibes_app/features/chats/usecases/message_bookmark_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const MessageBookmarksScreen({
  required final String workspaceId,
  final String? conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScreen(
    child: _MessageBookmarksBody(
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
    appBar: const AuraAppBarWithDrawer(
      title: TextLocale(LocaleKeys.chats_screens_chats_list_saved_messages),
    ),
  );
}

class const _MessageBookmarksBody({
  required final String workspaceId,
  required final String? conversationId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(messageBookmarksProvider(workspaceId));
    final cloudBookmarks = ref.watch(cloudMessageBookmarksProvider);

    return switch (bookmarks) {
      AsyncData(:final value) => _MessageBookmarksData(
        bookmarks: _conversationBookmarks(value, conversationId),
        cloudBookmarks: cloudBookmarks,
      ),
      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
      AsyncLoading() => const Center(child: AuraSpinner()),
    };
  }
}

List<MessageBookmarkEntity> _conversationBookmarks(
  List<MessageBookmarkEntity> bookmarks,
  String? conversationId,
) {
  if (conversationId == null) return bookmarks;

  return bookmarks
      .where((bookmark) => bookmark.details.conversationId == conversationId)
      .toList(growable: false);
}

class const _MessageBookmarksData({
  required final List<MessageBookmarkEntity> bookmarks,
  required final AsyncValue<List<MessageBookmarkEntity>> cloudBookmarks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (cloudBookmarks case AsyncError(:final error))
        _CloudBookmarksError(error: error),
      Expanded(
        child: _MessageBookmarkContent(
          bookmarks: bookmarks,
          cloudLoading: cloudBookmarks.isLoading,
        ),
      ),
    ],
  );
}

class const _CloudBookmarksError({required final Object error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPadding(
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _CloudBookmarkErrorCallout(error: error),
        const _CloudBookmarkRetryButton(),
      ],
    ),
    padding: const .horizontal(.md),
  );
}

class const _CloudBookmarkErrorCallout({required final Object error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCallout(
    title: CloudAppErrors.localizationKey(error).tr(),
    icon: Icons.error_outline,
    tint: .error,
  );
}

class const _CloudBookmarkRetryButton() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: () => ref.invalidate(cloudMessageBookmarksProvider),
    child: const TextLocale(LocaleKeys.route_state_retry),
  );
}

class const _MessageBookmarkContent({
  required final List<MessageBookmarkEntity> bookmarks,
  required final bool cloudLoading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (bookmarks.isNotEmpty) return _MessageBookmarkList(bookmarks: bookmarks);
    if (cloudLoading) return const Center(child: AuraSpinner());

    return const Center(
      child: TextLocale(
        LocaleKeys.chats_screens_chats_list_saved_messages_empty,
      ),
    );
  }
}

class const _MessageBookmarkList({
  required final List<MessageBookmarkEntity> bookmarks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    itemBuilder: (context, index) =>
        _MessageBookmarkTile(bookmark: bookmarks[index]),
    separatorBuilder: (context, index) => const Divider(height: 1),
    itemCount: bookmarks.length,
  );
}

class const _MessageBookmarkTile({
  required final MessageBookmarkEntity bookmark,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    title: _MessageBookmarkExcerpt(bookmark: bookmark),
    subtitle: _MessageBookmarkMetadata(bookmark: bookmark),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _openMessageBookmark(context, ref, bookmark),
  );
}

class const _MessageBookmarkExcerpt({
  required final MessageBookmarkEntity bookmark,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    bookmark.details.excerpt.isEmpty
        ? LocaleKeys.chats_screens_chats_list_saved_message_empty_excerpt.tr()
        : bookmark.details.excerpt,
    overflow: .ellipsis,
    maxLines: 2,
  );
}

class const _MessageBookmarkMetadata({
  required final MessageBookmarkEntity bookmark,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (bookmark.details.isUser case final isUser?)
        _MessageBookmarkAuthorRole(isUser: isUser),
      Text(_conversationTitle(bookmark)),
      Text(bookmark.details.workspaceName),
      _MessageBookmarkTime(createdAt: bookmark.details.createdAt),
    ],
  );
}

class const _MessageBookmarkAuthorRole({required final bool isUser})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    isUser
        ? LocaleKeys.chats_screens_conversation_search_user_role
        : LocaleKeys.chats_screens_conversation_search_assistant_role,
  );
}

class const _MessageBookmarkTime({required final DateTime createdAt})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    RelativeTimeFormatter.format(
      createdAt,
      locale: Localizations.localeOf(context),
      translate: (key, {args}) => context.tr(key, args: args),
    ),
  );
}

String _conversationTitle(MessageBookmarkEntity bookmark) {
  final title = bookmark.details.conversationTitle?.trim();
  if (title == null || title.isEmpty) {
    return LocaleKeys
        .chats_screens_chats_list_saved_message_untitled_conversation
        .tr();
  }

  return title;
}

Future<void> _openMessageBookmark(
  BuildContext context,
  WidgetRef ref,
  MessageBookmarkEntity bookmark,
) async {
  try {
    final workspace = await _resolveBookmarkWorkspace(context, ref, bookmark);
    if (!context.mounted) return;

    await _refreshWorkspaceInventory(ref, bookmark, workspace);
    if (!context.mounted) return;

    _navigateToBookmark(context, bookmark, workspace);
  } on Object catch (error) {
    _showBookmarkOpenError(context, error);
  }
}

Future<WorkspaceEntity> _resolveBookmarkWorkspace(
  BuildContext context,
  WidgetRef ref,
  MessageBookmarkEntity bookmark,
) => ref
    .read(messageBookmarkUseCaseProvider)
    .resolveWorkspace(
      bookmark,
      attachAuthorizedWorkspace: ({required account, required workspaceId}) =>
          _attachAuthorizedWorkspace(context, ref, (
            account: account,
            workspaceId: workspaceId,
          )),
    );

typedef _AuthorizedCloudWorkspace = ({
  CloudAccountKey account,
  int workspaceId,
});

Future<WorkspaceEntity> _attachAuthorizedWorkspace(
  BuildContext context,
  WidgetRef ref,
  _AuthorizedCloudWorkspace request,
) async {
  if (!context.mounted) {
    throw const AppCloudWorkspaceException(LocaleKeys.cloud_errors_unavailable);
  }

  final useCases = await _cloudWorkspaceUseCasesForAccount(
    context,
    ref,
    request.account,
  );

  return await useCases.attachAuthorizedWorkspace(request.workspaceId);
}

Future<CloudWorkspaceUseCases> _cloudWorkspaceUseCasesForAccount(
  BuildContext context,
  WidgetRef ref,
  CloudAccountKey account,
) async {
  final provider = cloudWorkspaceUseCasesProvider(account);
  final subscription = ref.listenManual(provider, (_, next) => next);
  try {
    final useCases = await ref.read(provider.future);

    return _requireCloudWorkspaceUseCases(useCases);
  } finally {
    if (context.mounted) subscription.close();
  }
}

CloudWorkspaceUseCases _requireCloudWorkspaceUseCases(
  CloudWorkspaceUseCases? useCases,
) {
  if (useCases == null) {
    throw const AppCloudWorkspaceException(LocaleKeys.cloud_errors_unavailable);
  }

  return useCases;
}

Future<void> _refreshWorkspaceInventory(
  WidgetRef ref,
  MessageBookmarkEntity bookmark,
  WorkspaceEntity workspace,
) async {
  if (workspace.id == bookmark.workspace.workspaceId) return;
  ref.invalidate(allWorkspacesProvider);
  final _ = await ref.read(allWorkspacesProvider.future);
}

void _navigateToBookmark(
  BuildContext context,
  MessageBookmarkEntity bookmark,
  WorkspaceEntity workspace,
) => ConversationRoute(
  workspaceId: workspace.id,
  chatId: bookmark.details.conversationId,
  messageId: bookmark.details.messageId,
).go(context);

void _showBookmarkOpenError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final localizationKey = switch (error) {
    AppCloudWorkspaceException(:final localizationKey) => localizationKey,
    Object() => CloudAppErrors.localizationKey(error),
  };
  final _ = ScaffoldMessenger.of(context)
      .showSnackBar(.new(content: Text(localizationKey.tr())));
}
