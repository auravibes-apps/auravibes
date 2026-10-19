// Required: UI callbacks stay local to their widgets.

import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/providers/conversation_archive_provider.dart';
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_archive_feedback.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
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

    return AppScreen(
      child: _ChatsListBody(
        workspaceId: workspaceId,
        showArchiveActions: showArchiveActions,
      ),
      appBar: AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.chats_screens_chats_list_title),
        actions: [
          AuraIconButton(
            icon: Icons.search,
            onPressed: () =>
                ConversationSearchRoute(workspaceId: workspaceId).go(context),
            tooltip: LocaleKeys.chats_screens_conversation_search_entry.tr(),
          ),
        ],
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
    await _importArchive((
      context: context,
      ref: ref,
      workspaceId: workspaceId,
      archiveJson: archiveJson,
    ));
  } on Object catch (error) {
    if (!context.mounted) return;
    ConversationArchiveFeedback.showError(context, error);
  }
}

typedef _ArchiveImportRequest = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String archiveJson,
});

Future<void> _importArchive(_ArchiveImportRequest request) async {
  final (:context, :ref, :workspaceId, :archiveJson) = request;
  if (!await _confirmIncompleteAgentContextImport(context, archiveJson)) return;
  final conversations = await _importConversations(
    ref,
    workspaceId,
    archiveJson,
  );
  if (!context.mounted) return;
  _showArchiveImportResult(context, workspaceId, conversations);
}

Future<List<ConversationEntity>> _importConversations(
  WidgetRef ref,
  String workspaceId,
  String archiveJson,
) => ref
    .read(conversationArchiveUsecaseProvider)
    .importArchive(workspaceId: workspaceId, archiveJson: archiveJson);

Future<bool> _confirmIncompleteAgentContextImport(
  BuildContext context,
  String archiveJson,
) {
  final affected = _incompleteArchiveImportPreview(archiveJson);
  if (affected.isEmpty) return Future.value(true);

  return _showIncompleteAgentContextImportDialog(context, affected);
}

List<ConversationArchiveImportPreview> _incompleteArchiveImportPreview(
  String archiveJson,
) =>
    ConversationArchiveCodec.previewImport(archiveJson)
        .where((item) => item.hasIncompleteAgentContext)
        .toList(growable: false);

Future<bool> _showIncompleteAgentContextImportDialog(
  BuildContext context,
  List<ConversationArchiveImportPreview> affected,
) async {
  if (!context.mounted) return false;

  final result = await AuraDialogs.confirm(
    context: context,
    title: const TextLocale(
      LocaleKeys.chats_screens_chats_list_archive_incomplete_title,
    ),
    message: _IncompleteAgentContextImportContent(affected: affected),
    actions: const AuraConfirmDialogActions(
      confirmLabel: TextLocale(
        LocaleKeys.chats_screens_chats_list_archive_import_continue,
      ),
      cancelLabel: TextLocale(
        LocaleKeys.chats_screens_chats_list_archive_import_cancel,
      ),
    ),
  );

  return result == true;
}

class const _IncompleteAgentContextImportContent({
  required final List<ConversationArchiveImportPreview> affected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      const TextLocale(
        LocaleKeys.chats_screens_chats_list_archive_incomplete_description,
      ),
      const SizedBox(height: 12),
      const TextLocale(
        LocaleKeys.chats_screens_chats_list_archive_incomplete_affected,
      ),
      const SizedBox(height: 4),
      for (final conversation in affected)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(conversation.title),
        ),
    ],
  );
}

void _showArchiveImportResult(
  BuildContext context,
  String workspaceId,
  List<ConversationEntity> conversations,
) {
  if (conversations.length > 1) {
    ConversationArchiveFeedback.showImportedMany(context, conversations.length);

    return;
  }
  final conversation = conversations.single;
  ConversationRoute(
    workspaceId: workspaceId,
    chatId: conversation.id,
  ).go(context);
}
