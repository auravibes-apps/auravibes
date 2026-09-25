// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/features/chats/providers/conversation_archive_provider.dart';
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_archive_feedback.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ChatsListScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchiveActions = switch (ref.watch(
      workspaceSessionForRouteProvider(workspaceId),
    )) {
      AsyncData(value: final session) => session.cloud == null,
      AsyncLoading() || AsyncError() => false,
    };

    return AuraScreen(
      child: _ChatsListBody(
        workspaceId: workspaceId,
        showArchiveActions: showArchiveActions,
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.chats_screens_chats_list_title),
      ),
    );
  }
}

class const _ChatsListBody({
  required final String workspaceId,
  required final bool showArchiveActions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _ChatsListAddChatButton(
          workspaceId: workspaceId,
          showArchiveActions: showArchiveActions,
        ),
        Expanded(child: ChatListWidget(workspaceId: workspaceId)),
      ],
    );
  }
}

class const _ChatsListAddChatButton({
  required final String workspaceId,
  required final bool showArchiveActions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPadding(
      child: AppContent(
        child: _ChatsListNewChatButton(
          workspaceId: workspaceId,
          showArchiveActions: showArchiveActions,
        ),
      ),
      padding: const .horizontal(.md),
    );
  }
}

class const _ChatsListNewChatButton({
  required final String workspaceId,
  required final bool showArchiveActions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AuraButton(
          onPressed: () => NewChatRoute(workspaceId: workspaceId).go(context),
          child: const TextLocale(LocaleKeys.chats_screens_chats_list_add_chat),
        ),
      ),
      if (showArchiveActions) ...[
        const SizedBox(width: 8),
        _ConversationArchiveImportButton(workspaceId: workspaceId),
      ],
    ],
  );
}

class const _ConversationArchiveImportButton({
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraIconButton(
    icon: Icons.file_open_outlined,
    onPressed: () =>
        unawaited(_importConversationArchive(context, ref, workspaceId)),
    tooltip: LocaleKeys.chats_screens_chats_list_archive_import.tr(),
  );
}

Future<void> _importConversationArchive(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  try {
    final archiveJson = await ref
        .read(conversationArchiveFileServiceProvider)
        .pickArchiveJson();
    if (archiveJson == null || !context.mounted) return;
    await _importAndOpenArchive(context, ref, workspaceId, archiveJson);
  } on Object catch (error) {
    if (!context.mounted) return;
    ConversationArchiveFeedback.showError(context, error);
  }
}

Future<void> _importAndOpenArchive(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String archiveJson,
) async {
  final conversation = await ref
      .read(conversationArchiveUsecaseProvider)
      .importConversation(workspaceId: workspaceId, archiveJson: archiveJson);
  if (!context.mounted) return;
  ConversationRoute(
    workspaceId: workspaceId,
    chatId: conversation.id,
  ).go(context);
}
