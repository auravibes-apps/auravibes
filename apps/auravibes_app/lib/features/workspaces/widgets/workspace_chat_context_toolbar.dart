import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/directory_navigation.dart';
import 'package:auravibes_app/features/workspaces/notifiers/directory_navigation_notifier.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AuraIconButton(
              icon: Icons.close,
              onPressed: onClose,
              tooltip: LocaleKeys.common_close.tr(),
            ),
            Expanded(child: TextLocale(LocaleKeys.workspace_chat_scope)),
            AuraPopupMenuButton(
              items: [
                AuraPopupMenuItem(
                  onTap: busy.value
                      ? null
                      : () => unawaited(_run(context, ref, false, error, busy)),
                  title: const TextLocale(LocaleKeys.workspace_chat_share),
                ),
                AuraPopupMenuItem(
                  onTap: busy.value
                      ? null
                      : () => unawaited(_run(context, ref, true, error, busy)),
                  title: const TextLocale(LocaleKeys.workspace_chat_revoke),
                ),
              ],
            ),
          ],
        ),
        if (busy.value) const LinearProgressIndicator(),
        if (error.value != null) WorkspaceItemFailure(error: error.value!),
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    bool revoke,
    ValueNotifier<Object?> error,
    ValueNotifier<bool> busy,
  ) async {
    busy.value = true;
    error.value = null;
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
              workspaceId: session.cloud == null
                  ? workspaceId
                  : '${session.cloud!.cloudWorkspaceId}',
              conversationId: conversationId,
              itemId: selectedItem.id,
              kind: selectedItem.kind,
              parentId: _parent(ref),
              recordIds: ids,
            );
      final metadata = MessageMetadataEntity(
        modelMetadata: {workspaceContextMetadataKey: selection?.toJson()},
      );
      final content = revoke
          ? LocaleKeys.workspace_chat_revoked.tr()
          : '${LocaleKeys.workspace_chat_shared.tr()}\n${jsonEncode(selection!.toJson())}';
      await ref
          .read(sendMessageUsecaseProvider(workspaceId))
          .call(
            conversationId: conversationId,
            draft: ChatDraft(
              text: content,
              metadataJson: jsonEncode(metadata.toJson()),
            ),
          );
    } on Object catch (failure) {
      if (context.mounted) error.value = failure;
    } finally {
      if (context.mounted) busy.value = false;
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
    if (selected is WorkspaceTable)
      return WorkspaceChatItem(id: selected.id, kind: 'table');
    if (selected is DirectoryViewLocation)
      return WorkspaceChatItem(id: selected.id, kind: 'view');
    if (directory.path.isNotEmpty)
      return WorkspaceChatItem(id: directory.path.last.id, kind: 'folder');
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
          title: TextLocale(LocaleKeys.workspace_chat_share),
          content: TextLocale(LocaleKeys.workspace_chat_scope),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: TextLocale(LocaleKeys.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: TextLocale(LocaleKeys.workspace_chat_share),
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
    final query = await ref.read(
      workspaceRecordQueryUsecaseProvider(workspaceId).future,
    );
    final page = await query(table.id, const WorkspaceRecordQuery(limit: 50));
    if (!context.mounted) return null;
    return showDialog<List<String>>(
      context: context,
      builder: (_) => _RecordSelection(table, page.records),
    );
  }
}

class const _RecordSelection(
  final WorkspaceTable table,
  final List<WorkspaceRecord> records,
) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selected = useState(<String>{});
    return AlertDialog(
      title: const TextLocale(LocaleKeys.workspace_chat_records),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView(
          children: [
            const TextLocale(LocaleKeys.workspace_chat_scope),
            const TextLocale(LocaleKeys.workspace_chat_structure),
            for (final record in records)
              CheckboxListTile(
                title: Text(
                  '${record.values[table.labelColumnId] ?? record.id}',
                ),
                value: selected.value.contains(record.id),
                onChanged: (value) => selected.value =
                    value == true
                          ? {...selected.value, record.id}
                          : {...selected.value}
                      ..remove(record.id),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(selected.value.toList()),
          child: const TextLocale(LocaleKeys.workspace_chat_share),
        ),
      ],
    );
  }
}
