import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/directory_navigation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/directory_navigation_notifier.dart';
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
    final state = _WorkspaceChatContextToolbarState(
      status: useState(const _WorkspaceChatContextToolbarStatus()),
    );
    final actions = _WorkspaceChatContextToolbarActions(
      context: context,
      ref: ref,
      state: state,
      workspaceId: workspaceId,
      conversationId: conversationId,
      item: item,
    );

    return _WorkspaceChatContextToolbarContent(
      state: state,
      onClose: onClose,
      actions: actions,
    );
  }
}

class const _WorkspaceChatContextToolbarContent({
  required final _WorkspaceChatContextToolbarState state,
  required final VoidCallback onClose,
  required final _WorkspaceChatContextToolbarActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _WorkspaceChatContextToolbarHeader(
        onClose: onClose,
        busy: state.status.value.busy,
        actions: actions,
      ),
      _WorkspaceChatContextToolbarFeedback(state: state),
    ],
  );
}

class _WorkspaceChatContextToolbarState({
  required final ValueNotifier<_WorkspaceChatContextToolbarStatus> status,
}) {
  var released = false;

  void start() {
    status.value = const _WorkspaceChatContextToolbarStatus(busy: true);
    released = false;
  }

  void showFailure(Object failure) {
    final current = status.value;
    status.value = _WorkspaceChatContextToolbarStatus(
      error: failure,
      busy: current.busy,
      saving: current.saving,
    );
  }

  void startSaving() {
    final current = status.value;
    status.value = _WorkspaceChatContextToolbarStatus(
      error: current.error,
      busy: current.busy,
      saving: true,
    );
  }

  void release() {
    status.value = const _WorkspaceChatContextToolbarStatus();
    released = true;
  }

  void finish({required bool mounted}) {
    if (!mounted || released) return;
    status.value = const _WorkspaceChatContextToolbarStatus();
  }
}

class const _WorkspaceChatContextToolbarStatus({
  final Object? error,
  final bool busy = false,
  final bool saving = false,
});

class const _WorkspaceChatContextToolbarActions({
  required final BuildContext context,
  required final WidgetRef ref,
  required final _WorkspaceChatContextToolbarState state,
  required final String workspaceId,
  required final String conversationId,
  required final WorkspaceChatItem item,
}) {
  void inspect() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => WorkspaceContextInspector(
          workspaceId: workspaceId,
          conversationId: conversationId,
        ),
      ),
    );
  }

  void share() => _run(revoke: false);

  void revoke() => _run(revoke: true);

  void _run({required bool revoke}) =>
      unawaited(_runWorkspaceContextAction(this, revoke: revoke));

  List<AuraPopupMenuItem> _menuItems({required bool busy}) => [
    AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.workspace_chat_inspect),
      onTap: inspect,
    ),
    AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.workspace_chat_share),
      onTap: busy ? null : share,
    ),
    AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.workspace_chat_revoke),
      onTap: busy ? null : revoke,
    ),
  ];
}

class const _WorkspaceChatContextToolbarHeader({
  required final VoidCallback onClose,
  required final bool busy,
  required final _WorkspaceChatContextToolbarActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      AuraIconButton(
        icon: Icons.close,
        onPressed: onClose,
        tooltip: LocaleKeys.common_close.tr(),
      ),
      const Expanded(child: TextLocale(LocaleKeys.workspace_chat_title)),
      _WorkspaceChatContextToolbarMenu(busy: busy, actions: actions),
    ],
  );
}

class const _WorkspaceChatContextToolbarMenu({
  required final bool busy,
  required final _WorkspaceChatContextToolbarActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraPopupMenuButton(items: actions._menuItems(busy: busy));
}

class const _WorkspaceChatContextToolbarFeedback({
  required final _WorkspaceChatContextToolbarState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      if (state.status.value.saving) const LinearProgressIndicator(),
      if (state.status.value.error case final Object failure)
        WorkspaceItemFailure(error: failure),
    ],
  );
}

class const _ContextSelectionDecision({
  required final WorkspaceContextSelection? selection,
});

class const _ContextSelectionChoice({
  required final _WorkspaceContextTarget target,
  required final List<String> recordIds,
  required final bool revoke,
});

Future<void> _runWorkspaceContextAction(
  _WorkspaceChatContextToolbarActions actions, {
  required bool revoke,
}) async {
  actions.state.start();
  try {
    await _performWorkspaceContextAction(actions, revoke: revoke);
  } on Object catch (failure) {
    if (actions.context.mounted) actions.state.showFailure(failure);
  } finally {
    actions.state.finish(mounted: actions.context.mounted);
  }
}

Future<void> _performWorkspaceContextAction(
  _WorkspaceChatContextToolbarActions actions, {
  required bool revoke,
}) async {
  final decision = await _prepareContextSelection(actions, revoke: revoke);
  if (!actions.context.mounted || decision == null) return;
  await _saveWorkspaceContext(actions, decision.selection);
}

Future<_ContextSelectionDecision?> _prepareContextSelection(
  _WorkspaceChatContextToolbarActions actions, {
  required bool revoke,
}) async {
  final choice = await _chooseContextSelection(actions, revoke: revoke);
  if (choice == null) return null;
  final session = await actions.ref.read(
    workspaceSessionForRouteProvider(actions.workspaceId).future,
  );

  return _contextSelectionDecision(actions, choice, session);
}

Future<_ContextSelectionChoice?> _chooseContextSelection(
  _WorkspaceChatContextToolbarActions actions, {
  required bool revoke,
}) async {
  final target = _selectedContextTarget(
    actions.ref,
    actions.workspaceId,
    actions.item,
  );
  final ids = await _contextRecordsForTarget(actions, target, revoke: revoke);
  if (!actions.context.mounted || ids == null) return null;

  return _ContextSelectionChoice(
    target: target,
    recordIds: ids,
    revoke: revoke,
  );
}

Future<List<String>?> _contextRecordsForTarget(
  _WorkspaceChatContextToolbarActions actions,
  _WorkspaceContextTarget target, {
  required bool revoke,
}) => revoke ? Future.value([]) : _chooseContextRecords(actions, target.item);

_ContextSelectionDecision _contextSelectionDecision(
  _WorkspaceChatContextToolbarActions actions,
  _ContextSelectionChoice choice,
  WorkspaceSession session,
) {
  if (choice.revoke) return const _ContextSelectionDecision(selection: null);

  return _ContextSelectionDecision(
    selection: _buildContextSelection(actions, choice, session),
  );
}

WorkspaceContextSelection _buildContextSelection(
  _WorkspaceChatContextToolbarActions actions,
  _ContextSelectionChoice choice,
  WorkspaceSession session,
) => WorkspaceContextSelection(
  workspaceId:
      session.cloud?.cloudWorkspaceId.toString() ?? actions.workspaceId,
  conversationId: actions.conversationId,
  itemId: choice.target.item.id,
  kind: choice.target.item.kind,
  parentId: choice.target.parentId,
  recordIds: choice.recordIds,
);

_WorkspaceContextTarget _selectedContextTarget(
  WidgetRef ref,
  String workspaceId,
  WorkspaceChatItem item,
) {
  final directory = ref.read(directoryNavigationProvider(workspaceId));
  final selectedItem = item.kind == 'directory'
      ? _selectedDirectoryItem(item, directory)
      : item;

  return _WorkspaceContextTarget(
    item: selectedItem,
    parentId: directory.path.isEmpty ? null : directory.path.last.parentId,
  );
}

WorkspaceChatItem _selectedDirectoryItem(
  WorkspaceChatItem item,
  DirectoryNavigation directory,
) {
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

Future<List<String>?> _chooseContextRecords(
  _WorkspaceChatContextToolbarActions actions,
  WorkspaceChatItem item,
) {
  if (item.kind != 'table') return _confirmWholeItem(actions.context);

  return _pickTableRecords(actions, item);
}

Future<List<String>?> _confirmWholeItem(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (_) => const _WorkspaceContextShareConfirmation(),
  );

  return accepted == true ? [] : null;
}

Future<List<String>?> _pickTableRecords(
  _WorkspaceChatContextToolbarActions actions,
  WorkspaceChatItem item,
) async {
  final table = await _loadContextTable(actions, item.id);
  if (!actions.context.mounted) return null;

  return _showContextRecordPicker(actions, table);
}

Future<WorkspaceTable> _loadContextTable(
  _WorkspaceChatContextToolbarActions actions,
  String itemId,
) async {
  final tables = await actions.ref.read(
    workspaceTableUsecaseProvider(actions.workspaceId).future,
  );

  return await tables.table(itemId);
}

Future<List<String>?> _showContextRecordPicker(
  _WorkspaceChatContextToolbarActions actions,
  WorkspaceTable table,
) => showDialog<List<String>>(
  context: actions.context,
  builder: (_) => WorkspaceContextRecordPicker(
    workspaceId: actions.workspaceId,
    table: table,
  ),
);

class const _WorkspaceContextShareConfirmation() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(LocaleKeys.workspace_chat_share),
    content: const TextLocale(LocaleKeys.workspace_chat_scope),
    actions: [
      const _WorkspaceContextCancelButton(),
      const _WorkspaceContextAcceptButton(),
    ],
  );
}

class const _WorkspaceContextCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}

class const _WorkspaceContextAcceptButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(true),
    child: const TextLocale(LocaleKeys.workspace_chat_share),
  );
}

Future<void> _saveWorkspaceContext(
  _WorkspaceChatContextToolbarActions actions,
  WorkspaceContextSelection? selection,
) async {
  actions.state.startSaving();
  final granted = await _persistContextSelection(actions, selection);
  actions.ref.invalidate(
    workspaceConversationContextProvider(
      actions.workspaceId,
      actions.conversationId,
    ),
  );
  // Sharing controls stay available while an authorized AI turn continues.
  actions.state.release();
  await _sendContextMessage(actions, granted.id, selection);
}

Future<void> _sendContextMessage(
  _WorkspaceChatContextToolbarActions actions,
  String? grantedId,
  WorkspaceContextSelection? selection,
) async {
  final payload = _contextMessagePayload(grantedId, selection);
  final _ = await actions.ref
      .read(sendMessageUsecaseProvider(actions.workspaceId))
      .call(
        conversationId: actions.conversationId,
        draft: .new(text: payload.text, metadataJson: payload.metadataJson),
      );
}

Future<WorkspaceConversationContext> _persistContextSelection(
  _WorkspaceChatContextToolbarActions actions,
  WorkspaceContextSelection? selection,
) async {
  final consent = await actions.ref.read(
    workspaceConversationContextUsecaseProvider(actions.workspaceId).future,
  );

  return consent.save(
    actions.conversationId,
    const UuidV7().generate(),
    selection,
  );
}

({String text, String metadataJson}) _contextMessagePayload(
  String? grantedId,
  WorkspaceContextSelection? selection,
) => (
  text: selection == null
      ? LocaleKeys.workspace_chat_revoked.tr()
      : '${LocaleKeys.workspace_chat_shared.tr()}\n'
            '${jsonEncode(selection.toJson())}',
  metadataJson: jsonEncode(
    MessageMetadataEntity(
      modelMetadata: {
        'workspaceContextSelectionProof': {
          'epoch': grantedId,
          'selection': selection?.toJson(),
        },
      },
    ).toJson(),
  ),
);

class const _WorkspaceContextTarget({
  required final WorkspaceChatItem item,
  required final String? parentId,
});
