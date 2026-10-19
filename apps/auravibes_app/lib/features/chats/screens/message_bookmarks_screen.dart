import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/features/chats/providers/message_bookmarks_provider.dart';
import 'package:auravibes_app/features/chats/usecases/message_bookmark_usecase.dart';
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
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloudBookmarks = ref.watch(cloudMessageBookmarksProvider);
    final content = switch (ref.watch(messageBookmarksProvider(workspaceId))) {
      AsyncData(:final value) => Column(
        children: [
          if (cloudBookmarks case AsyncError(:final error))
            AuraPadding(
              child: AuraCallout(
                title: CloudAppErrors.localizationKey(error).tr(),
                icon: Icons.error_outline,
                tint: .error,
              ),
              padding: const .horizontal(.md),
            ),
          Expanded(
            child: switch (value.isEmpty) {
              true when cloudBookmarks.isLoading => const Center(
                child: AuraSpinner(),
              ),
              true => const Center(
                child: TextLocale(
                  LocaleKeys.chats_screens_chats_list_saved_messages_empty,
                ),
              ),
              false => _MessageBookmarkList(bookmarks: value),
            },
          ),
        ],
      ),
      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
      AsyncLoading() => const Center(child: AuraSpinner()),
    };

    return AppScreen(
      child: content,
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.chats_screens_chats_list_saved_messages),
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
    title: Text(
      bookmark.excerpt.isEmpty
          ? LocaleKeys.chats_screens_chats_list_saved_message_empty_excerpt.tr()
          : bookmark.excerpt,
      overflow: .ellipsis,
      maxLines: 2,
    ),
    subtitle: Column(
      crossAxisAlignment: .start,
      children: [
        Text(_conversationTitle(bookmark)),
        Text(bookmark.workspaceName),
        Text(
          RelativeTimeFormatter.format(
            bookmark.createdAt,
            locale: Localizations.localeOf(context),
            translate: (key, {args}) => context.tr(key, args: args),
          ),
        ),
      ],
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _openMessageBookmark(context, ref, bookmark),
  );
}

String _conversationTitle(MessageBookmarkEntity bookmark) {
  final title = bookmark.conversationTitle?.trim();
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
    final workspace = await ref
        .read(messageBookmarkUseCaseProvider)
        .resolveWorkspace(
          bookmark,
          attachAuthorizedWorkspace:
              ({required account, required workspaceId}) async {
                if (!context.mounted) {
                  throw const AppCloudWorkspaceException(
                    LocaleKeys.cloud_errors_unavailable,
                  );
                }
                final provider = cloudWorkspaceUseCasesProvider(account);
                final subscription = ref.listenManual(
                  provider,
                  (_, next) => next,
                );
                try {
                  final useCases = await ref.read(provider.future);
                  if (useCases == null) {
                    throw const AppCloudWorkspaceException(
                      LocaleKeys.cloud_errors_unavailable,
                    );
                  }

                  return await useCases.attachAuthorizedWorkspace(workspaceId);
                } finally {
                  if (context.mounted) subscription.close();
                }
              },
        );
    if (!context.mounted) return;
    if (workspace.id != bookmark.workspaceId) {
      ref.invalidate(allWorkspacesProvider);
      final _ = await ref.read(allWorkspacesProvider.future);
    }

    if (!context.mounted) return;
    ConversationRoute(
      workspaceId: workspace.id,
      chatId: bookmark.conversationId,
      messageId: bookmark.messageId,
    ).go(context);
  } on Object catch (error) {
    if (!context.mounted) return;
    final localizationKey = switch (error) {
      AppCloudWorkspaceException(:final localizationKey) => localizationKey,
      Object() => CloudAppErrors.localizationKey(error),
    };
    final _ = ScaffoldMessenger.of(context)
        .showSnackBar(.new(content: Text(localizationKey.tr())));
  }
}
