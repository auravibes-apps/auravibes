import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/directory_navigation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/directory_navigation_notifier.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_context_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_context_inspector.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_context_record_picker.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkspaceChatContextToolbar({
  required final String workspaceId,
  required final String conversationId,
  required final WorkspaceChatItem item,
  required final VoidCallback onClose,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = useState<Object?>(null);
    final busy = useState(false);
    final saving = useState(false);

    return Column(
      mainAxisSize: .min,
      children: [
        Row(
          children: [
            AuraIconButton(
              icon: Icons.close,
              onPressed: onClose,
              tooltip: LocaleKeys.common_close.tr(),
            ),
            const Expanded(child: TextLocale(LocaleKeys.workspace_chat_title)),
            AuraPopupMenuButton(
              items: [
                AuraPopupMenuItem(
                  title: const TextLocale(LocaleKeys.workspace_chat_inspect),
                  onTap: () => unawaited(
                    showDialog<void>(
                      context: context,
                      builder: (_) => WorkspaceContextInspector(
                        workspaceId: workspaceId,
                        conversationId: conversationId,
                      ),
                    ),
                  ),
                ),
                AuraPopupMenuItem(
                  title: const TextLocale(LocaleKeys.workspace_chat_share),
                  onTap: busy.value
                      ? null
                      : () => unawaited(
                          _run(context, ref, false, error, busy, saving),
                        ),
                ),
                AuraPopupMenuItem(
                  title: const TextLocale(LocaleKeys.workspace_chat_revoke),
                  onTap: busy.value
                      ? null
                      : () => unawaited(
                          _run(context, ref, true, error, busy, saving),
                        ),
                ),
              ],
            ),
          ],
        ),
        if (saving.value) const LinearProgressIndicator(),
        if (error.value case final Object failure)
          WorkspaceItemFailure(error: failure),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    bool revoke,
    ValueNotifier<Object?> error,
    ValueNotifier<bool> busy,
    ValueNotifier<bool> saving,
  ) async {
    busy.value = true;
    error.value = null;
    var released = false;
    try {
      final selectedItem = _selectedItem(ref);
      final ids = revoke
          ? <String>[]
          : await _chooseRecords(context, ref, selectedItem);
      if (!context.mounted || ids == null) return;
      final session = await ref.read(
        workspaceSessionForRouteProvider(workspaceId).future,
      );
      final selection = revoke
          ? null
          : WorkspaceContextSelection(
              workspaceId:
                  session.cloud?.cloudWorkspaceId.toString() ?? workspaceId,
              conversationId: conversationId,
              itemId: selectedItem.id,
              kind: selectedItem.kind,
              parentId: _parent(ref),
              recordIds: ids,
            );
      saving.value = true;
      final consent = await ref.read(
        workspaceConversationContextUsecaseProvider(workspaceId).future,
      );
      final granted = await consent.save(
        conversationId,
        const UuidV7().generate(),
        selection,
      );
      ref.invalidate(
        workspaceConversationContextProvider(workspaceId, conversationId),
      );
      // Sharing controls stay available while an authorized AI turn continues.
      busy.value = false;
      saving.value = false;
      released = true;
      final metadata = MessageMetadataEntity(
        modelMetadata: {
          'workspaceContextSelectionProof': {
            'epoch': granted.id,
            'selection': selection?.toJson(),
          },
        },
      );
      final content = selection == null
          ? LocaleKeys.workspace_chat_revoked.tr()
          : '${LocaleKeys.workspace_chat_shared.tr()}\n'
                '${jsonEncode(selection.toJson())}';
      final _ = await ref
          .read(sendMessageUsecaseProvider(workspaceId))
          .call(
            conversationId: conversationId,
            draft: .new(
              text: content,
              metadataJson: jsonEncode(metadata.toJson()),
            ),
          );
    } on Object catch (failure) {
      if (context.mounted) error.value = failure;
    } finally {
      if (context.mounted && !released) {
        busy.value = false;
        saving.value = false;
      }
    }
  }

  String? _parent(WidgetRef ref) {
    final path = ref.read(directoryNavigationProvider(workspaceId)).path;

    return path.isEmpty ? null : path.last.parentId;
  }

  WorkspaceChatItem _selectedItem(WidgetRef ref) {
    if (item.kind != 'directory') return item;
    final directory = ref.read(directoryNavigationProvider(workspaceId));
    final selected = directory.selected;
    if (selected is WorkspaceTable) {
      return WorkspaceChatItem(id: selected.id, kind: 'table');
    }
    if (selected is DirectoryViewLocation) {
      return WorkspaceChatItem(id: selected.id, kind: 'view');
    }
    if (selected != null) throw const WorkspaceTableException(denied: true);
    if (directory.path.isNotEmpty) {
      return WorkspaceChatItem(id: directory.path.last.id, kind: 'folder');
    }

    return item;
  }

  Future<List<String>?> _chooseRecords(
    BuildContext context,
    WidgetRef ref,
    WorkspaceChatItem item,
  ) async {
    if (item.kind != 'table') {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const TextLocale(LocaleKeys.workspace_chat_share),
          content: const TextLocale(LocaleKeys.workspace_chat_scope),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const TextLocale(LocaleKeys.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const TextLocale(LocaleKeys.workspace_chat_share),
            ),
          ],
        ),
      );

      return accepted == true ? [] : null;
    }
    final tables = await ref.read(
      workspaceTableUsecaseProvider(workspaceId).future,
    );
    final table = await tables.table(item.id);
    if (!context.mounted) return null;

    return await showDialog<List<String>>(
      context: context,
      builder: (_) =>
          WorkspaceContextRecordPicker(workspaceId: workspaceId, table: table),
    );
  }
}
