import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_labels_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_label_actions.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ConversationLabelsToolbar({
  super.key,
  required final String workspaceId,
  required final Set<String> selectedLabelIds,
  required final ValueChanged<Set<String>> onSelectedLabelIdsChanged,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConversationLabelsToolbar> createState() =>
      _ConversationLabelsToolbarState();
}

class _ConversationLabelsToolbarState
    extends ConsumerState<ConversationLabelsToolbar> {
  @override
  Widget build(BuildContext context) {
    final workspaceId = widget.workspaceId;
    final labels = ref.watch(conversationLabelsStreamProvider(workspaceId));
    final labelRows = switch (labels) {
      AsyncData(:final value) => value,
      AsyncError() => const <ConversationLabelEntity>[],
      AsyncLoading() => const <ConversationLabelEntity>[],
    };
    final filterLabel = LocaleKeys.chats_screens_conversation_labels_filter
        .tr();
    final selectedLabelIds = widget.selectedLabelIds;
    final count = selectedLabelIds.length;
    final filterSemantics = count == 0
        ? LocaleKeys.chats_screens_conversation_labels_filter_semantics.tr()
        : LocaleKeys.chats_screens_conversation_labels_filter_count_semantics
              .tr(args: [count.toString()]);
    if (labels case AsyncData()) {
      final availableIds = labelRows.map((label) => label.id).toSet();
      final validSelection = selectedLabelIds.intersection(availableIds);
      if (validSelection.length != selectedLabelIds.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              widget.selectedLabelIds.length != validSelection.length) {
            widget.onSelectedLabelIdsChanged(validSelection);
          }
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: .center,
        children: [
          AuraButton(
            onPressed: _openFilter,
            child: Row(
              mainAxisSize: .min,
              children: [
                const AuraIcon(Icons.label_outline, size: .small),
                const SizedBox(width: 8),
                Text(filterLabel),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  AuraBadge.count(
                    count: count,
                    variant: .neutral,
                    size: .small,
                    semanticLabel: LocaleKeys
                        .chats_screens_conversation_labels_selected_count_semantics
                        .tr(args: [count.toString()]),
                  ),
                ],
              ],
            ),
            variant: count == 0 ? .secondary : .primary,
            size: .small,
            disabled: labels.isLoading || labels.hasError,
            identifier: 'conversation-label-filter',
            semanticLabel: filterSemantics,
          ),
          AuraButton(
            onPressed: _openManage,
            child: Text(
              LocaleKeys.chats_screens_conversation_labels_manage.tr(),
            ),
            variant: .ghost,
            size: .small,
            identifier: 'conversation-label-manage',
          ),
          if (count > 0)
            AuraButton(
              onPressed: () => widget.onSelectedLabelIdsChanged(const {}),
              child: Text(
                LocaleKeys.chats_screens_conversation_labels_clear_filter.tr(),
              ),
              variant: .ghost,
              size: .small,
              identifier: 'conversation-label-clear-filter',
            ),
        ],
      ),
    );
  }

  void _openFilter() {
    unawaited(_showFilter());
  }

  void _openManage() {
    unawaited(
      _showManageConversationLabels(
        context,
        workspaceId: widget.workspaceId,
        ref: ref,
      ),
    );
  }

  Future<void> _showFilter() async {
    final labelsState = ref.read(
      conversationLabelsStreamProvider(widget.workspaceId),
    );
    if (labelsState case AsyncData(:final value)) {
      final selection = await _showConversationLabelFilter(
        context,
        labels: value,
        selectedLabelIds: widget.selectedLabelIds,
      );
      if (selection != null && mounted) {
        widget.onSelectedLabelIdsChanged(selection);
      }
    }
  }
}

Future<Set<String>?> _showConversationLabelFilter(
  BuildContext context, {
  required List<ConversationLabelEntity> labels,
  required Set<String> selectedLabelIds,
}) => showDialog<Set<String>>(
  context: context,
  builder: (_) => _ConversationLabelFilterDialog(
    labels: labels,
    selectedLabelIds: selectedLabelIds,
  ),
);

class const _ConversationLabelFilterDialog({
  required final List<ConversationLabelEntity> labels,
  required final Set<String> selectedLabelIds,
}) extends StatefulWidget {
  @override
  State<_ConversationLabelFilterDialog> createState() =>
      _ConversationLabelFilterDialogState();
}

class _ConversationLabelFilterDialogState
    extends State<_ConversationLabelFilterDialog> {
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.selectedLabelIds);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocaleKeys.chats_screens_conversation_labels_filter_title.tr()),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Text(LocaleKeys.chats_screens_conversation_labels_filter_help.tr()),
          const SizedBox(height: 12),
          if (widget.labels.isEmpty)
            Text(LocaleKeys.chats_screens_conversation_labels_empty.tr())
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                itemBuilder: (_, index) => _ConversationLabelCheckbox(
                  label: widget.labels[index],
                  selected: _selected.contains(widget.labels[index].id),
                  enabled: true,
                  onChanged: (value) => setState(() {
                    if (value) {
                      final _ = _selected.add(widget.labels[index].id);
                    } else {
                      final _ = _selected.remove(widget.labels[index].id);
                    }
                  }),
                ),
                itemCount: widget.labels.length,
              ),
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
        onPressed: () => Navigator.of(context).pop(_selected),
        child: const TextLocale(
          LocaleKeys.chats_screens_conversation_labels_apply,
        ),
      ),
    ],
  );
}

Future<void> _showManageConversationLabels(
  BuildContext context, {
  required String workspaceId,
  required WidgetRef ref,
}) => showDialog<void>(
  context: context,
  builder: (_) => _ConversationLabelManagementDialog(
    workspaceId: workspaceId,
    actions: ref.read(conversationLabelActionsProvider),
  ),
);

class const _ConversationLabelManagementDialog({
  required final String workspaceId,
  required final ConversationLabelActions actions,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ConversationLabelManagementDialog> createState() =>
      _ConversationLabelManagementDialogState();
}

class _ConversationLabelManagementDialogState
    extends ConsumerState<_ConversationLabelManagementDialog> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(
      conversationLabelsStreamProvider(widget.workspaceId),
    );
    return AlertDialog(
      title: Text(
        LocaleKeys.chats_screens_conversation_labels_manage_title.tr(),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            _NewConversationLabelField(
              enabled: !_isWorking,
              onCreate: (name) => _run(
                () => widget.actions.create(
                  workspaceId: widget.workspaceId,
                  name: name,
                ),
              ),
            ),
            const SizedBox(height: 12),
            switch (labels) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  LocaleKeys.chats_screens_conversation_labels_empty.tr(),
                ),
              ),
              AsyncData(:final value) => ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  itemBuilder: (context, index) => _ConversationLabelRow(
                    label: value[index],
                    enabled: !_isWorking,
                    onRename: () => _rename(value[index]),
                    onDelete: () => _delete(value[index]),
                  ),
                  itemCount: value.length,
                ),
              ),
              AsyncError() => Text(
                LocaleKeys.chats_screens_conversation_labels_load_error.tr(),
              ),
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            },
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isWorking ? null : () => Navigator.of(context).pop(),
          child: const TextLocale(
            LocaleKeys.chats_screens_conversation_labels_done,
          ),
        ),
      ],
    );
  }

  Future<void> _rename(ConversationLabelEntity label) async {
    final name = await _showLabelNameDialog(
      context,
      title: LocaleKeys.chats_screens_conversation_labels_rename.tr(),
      initialName: label.name,
    );
    if (name == null || name == label.name) {
      return;
    }
    final _ = await _run(
      () => widget.actions.rename(
        workspaceId: widget.workspaceId,
        labelId: label.id,
        name: name,
      ),
    );
  }

  Future<void> _delete(ConversationLabelEntity label) async {
    final confirmed = await AuraDialogs.confirm(
      context: context,
      title: const TextLocale(
        LocaleKeys.chats_screens_conversation_labels_delete_title,
      ),
      message: const TextLocale(
        LocaleKeys.chats_screens_conversation_labels_delete_message,
      ),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(
          LocaleKeys.chats_screens_conversation_labels_delete,
        ),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );
    if (confirmed != true) {
      return;
    }
    final _ = await _run(
      () => widget.actions.delete(
        workspaceId: widget.workspaceId,
        labelId: label.id,
      ),
    );
  }

  Future<bool> _run(Future<Object?> Function() operation) async {
    setState(() => _isWorking = true);
    try {
      final _ = await operation();

      return true;
    } on Object catch (error) {
      if (mounted) {
        _showLabelError(
          context,
          message: error is ConversationLabelAlreadyExistsException
              ? LocaleKeys.chats_screens_conversation_labels_duplicate_name.tr()
              : LocaleKeys.chats_screens_conversation_labels_save_error.tr(),
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }
}

class const _NewConversationLabelField({
  required final bool enabled,
  required final Future<bool> Function(String name) onCreate,
}) extends StatefulWidget {
  @override
  State<_NewConversationLabelField> createState() =>
      _NewConversationLabelFieldState();
}

class _NewConversationLabelFieldState
    extends State<_NewConversationLabelField> {
  final _controller = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    children: [
      Expanded(
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: LocaleKeys.chats_screens_conversation_labels_label_name
                .tr(),
            errorText: _validationError,
            isDense: true,
          ),
          textInputAction: .done,
          maxLength: 40,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
          enabled: widget.enabled,
        ),
      ),
      const SizedBox(width: 8),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AuraIconButton(
          icon: Icons.add,
          onPressed: widget.enabled ? _submitFromButton : null,
          tooltip: LocaleKeys.chats_screens_conversation_labels_create.tr(),
        ),
      ),
    ],
  );

  void _onChanged(String _) {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
  }

  void _onSubmitted(String _) => unawaited(_submit());

  void _submitFromButton() => unawaited(_submit());

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || name.length > 40) {
      setState(
        () => _validationError = LocaleKeys
            .chats_screens_conversation_labels_invalid_name
            .tr(),
      );

      return;
    }
    if (await widget.onCreate(name) && mounted) {
      _controller.clear();
    }
  }
}

class const _ConversationLabelRow({
  required final ConversationLabelEntity label,
  required final bool enabled,
  required final VoidCallback onRename,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label.name),
    trailing: Wrap(
      children: [
        IconButton(
          onPressed: enabled ? onRename : null,
          tooltip: LocaleKeys.chats_screens_conversation_labels_rename.tr(),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: enabled ? onDelete : null,
          tooltip: LocaleKeys.chats_screens_conversation_labels_delete.tr(),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    dense: true,
  );
}

Future<String?> _showLabelNameDialog(
  BuildContext context, {
  required String title,
  required String initialName,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _ConversationLabelNameDialog(title: title, initialName: initialName),
);

class const _ConversationLabelNameDialog({
  required final String title,
  required final String initialName,
}) extends StatefulWidget {
  @override
  State<_ConversationLabelNameDialog> createState() =>
      _ConversationLabelNameDialogState();
}

class _ConversationLabelNameDialogState
    extends State<_ConversationLabelNameDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: LocaleKeys.chats_screens_conversation_labels_label_name.tr(),
        errorText: _error,
      ),
      textInputAction: .done,
      autofocus: true,
      maxLength: 40,
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const TextLocale(LocaleKeys.common_cancel),
      ),
      TextButton(
        onPressed: _submit,
        child: const TextLocale(LocaleKeys.common_save),
      ),
    ],
  );

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty || name.length > 40) {
      setState(
        () => _error = LocaleKeys.chats_screens_conversation_labels_invalid_name
            .tr(),
      );

      return;
    }
    Navigator.of(context).pop(name);
  }
}

Future<Set<String>?> showConversationLabelAssignmentDialog(
  BuildContext context, {
  required String workspaceId,
  required ConversationEntity conversation,
  required ConversationLabelActions actions,
}) => showDialog<Set<String>>(
  context: context,
  builder: (_) => _ConversationLabelAssignmentDialog(
    workspaceId: workspaceId,
    conversation: conversation,
    actions: actions,
  ),
);

class const _ConversationLabelAssignmentDialog({
  required final String workspaceId,
  required final ConversationEntity conversation,
  required final ConversationLabelActions actions,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ConversationLabelAssignmentDialog> createState() =>
      _ConversationLabelAssignmentDialogState();
}

class _ConversationLabelAssignmentDialogState
    extends ConsumerState<_ConversationLabelAssignmentDialog> {
  final Set<String> _selected = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.conversation.labels.map((label) => label.id));
  }

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(
      conversationLabelsStreamProvider(widget.workspaceId),
    );
    return AlertDialog(
      title: Text(
        LocaleKeys.chats_screens_conversation_labels_assignment_title.tr(),
      ),
      content: SizedBox(
        width: 420,
        child: switch (labels) {
          AsyncData(:final value) when value.isEmpty => Text(
            LocaleKeys.chats_screens_conversation_labels_empty.tr(),
          ),
          AsyncData(:final value) => ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.builder(
              itemBuilder: (_, index) => _ConversationLabelCheckbox(
                label: value[index],
                selected: _selected.contains(value[index].id),
                enabled: !_isSaving,
                onChanged: (checked) => setState(() {
                  if (checked) {
                    final _ = _selected.add(value[index].id);
                  } else {
                    final _ = _selected.remove(value[index].id);
                  }
                }),
              ),
              itemCount: value.length,
            ),
          ),
          AsyncError() => Text(
            LocaleKeys.chats_screens_conversation_labels_load_error.tr(),
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const TextLocale(LocaleKeys.common_cancel),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: const TextLocale(
            LocaleKeys.chats_screens_conversation_labels_save_assignments,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.actions.assign(
        workspaceId: widget.workspaceId,
        conversationId: widget.conversation.id,
        labelIds: _selected,
      );
      if (mounted) {
        Navigator.of(context).pop(_selected);
      }
    } on Object catch (_) {
      if (mounted) {
        _showLabelError(
          context,
          message: LocaleKeys.chats_screens_conversation_labels_save_error.tr(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

void _showLabelError(
  BuildContext context, {
  required String message,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final _ = messenger?.showSnackBar(SnackBar(content: Text(message)));
}

class const _ConversationLabelCheckbox({
  super.key,
  required final ConversationLabelEntity label,
  required final bool selected,
  required final bool enabled,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraCheckboxListTile(
    value: selected,
    onChanged: enabled ? onChanged : null,
    title: Text(label.name),
    semanticLabel: label.name,
  );
}

