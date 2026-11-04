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

const _conversationLabelToolbarInset = 16.0;
const _conversationLabelToolbarTopInset = 12.0;
const _conversationLabelToolbarSpacing = 8.0;
const _conversationLabelFilterDialogWidth = 420.0;
const _conversationLabelManageDialogWidth = 440.0;
const _conversationLabelFilterListMaxHeight = 320.0;
const _conversationLabelAssignmentListMaxHeight = 360.0;
const _conversationLabelDialogSectionSpacing = 12.0;
const _conversationLabelRowGap = 8.0;
const _conversationLabelCountGap = 6.0;
const _conversationLabelFieldInset = 8.0;
const _conversationLabelNameMaxLength = 40;

class const ConversationLabelsToolbar({
  required final String workspaceId,
  required final Set<String> selectedLabelIds,
  required final ValueChanged<Set<String>> onSelectedLabelIdsChanged,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConversationLabelsToolbar> createState() =>
      _ConversationLabelsToolbarState();
}

class _ConversationLabelsToolbarState
    extends ConsumerState<ConversationLabelsToolbar> {
  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(
      conversationLabelsStreamProvider(widget.workspaceId),
    );
    _removeStaleSelections(labels);

    return _toolbar(labels);
  }

  Widget _toolbar(AsyncValue<List<ConversationLabelEntity>> labels) => Padding(
    padding: const EdgeInsets.only(
      left: _conversationLabelToolbarInset,
      top: _conversationLabelToolbarTopInset,
      right: _conversationLabelToolbarInset,
    ),
    child: Wrap(
      spacing: _conversationLabelToolbarSpacing,
      runSpacing: _conversationLabelToolbarSpacing,
      crossAxisAlignment: .center,
      children: _toolbarItems(labels),
    ),
  );

  List<Widget> _toolbarItems(
    AsyncValue<List<ConversationLabelEntity>> labels,
  ) => [
    _ConversationLabelFilterButton(
      labels: labels,
      count: widget.selectedLabelIds.length,
      onPressed: _openFilter,
    ),
    AuraButton(
      onPressed: _openManage,
      child: Text(LocaleKeys.chats_screens_conversation_labels_manage.tr()),
      variant: .ghost,
      size: .small,
      identifier: 'conversation-label-manage',
    ),
    if (widget.selectedLabelIds.isNotEmpty)
      AuraButton(
        onPressed: () => widget.onSelectedLabelIdsChanged(const {}),
        child: Text(
          LocaleKeys.chats_screens_conversation_labels_clear_filter.tr(),
        ),
        variant: .ghost,
        size: .small,
        identifier: 'conversation-label-clear-filter',
      ),
  ];

  void _removeStaleSelections(
    AsyncValue<List<ConversationLabelEntity>> labels,
  ) {
    if (labels case AsyncData(:final value)) {
      final availableIds = value.map((label) => label.id).toSet();
      final validSelection = widget.selectedLabelIds.intersection(availableIds);
      if (validSelection.length != widget.selectedLabelIds.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              widget.selectedLabelIds.length != validSelection.length) {
            widget.onSelectedLabelIdsChanged(validSelection);
          }
        });
      }
    }
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

class const _ConversationLabelFilterButton({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final int count,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: _content(),
    variant: count == 0 ? .secondary : .primary,
    size: .small,
    disabled: labels.isLoading || labels.hasError,
    identifier: 'conversation-label-filter',
    semanticLabel: _filterSemantics,
  );

  String get _filterSemantics => count == 0
      ? LocaleKeys.chats_screens_conversation_labels_filter_semantics.tr()
      : LocaleKeys.chats_screens_conversation_labels_filter_count_semantics
            .tr(args: [count.toString()]);

  String get _selectedCountSemantics => LocaleKeys
      .chats_screens_conversation_labels_selected_count_semantics
      .tr(args: [count.toString()]);

  Widget _content() => Row(
    mainAxisSize: .min,
    children: [
      const AuraIcon(Icons.label_outline, size: .small),
      const SizedBox(width: _conversationLabelRowGap),
      Text(LocaleKeys.chats_screens_conversation_labels_filter.tr()),
      if (count > 0) ...[
        const SizedBox(width: _conversationLabelCountGap),
        AuraBadge.count(
          count: count,
          variant: .neutral,
          size: .small,
          semanticLabel: _selectedCountSemantics,
        ),
      ],
    ],
  );
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
    title: _title,
    content: _content,
    actions: _actions(context),
  );

  Widget get _title =>
      Text(LocaleKeys.chats_screens_conversation_labels_filter_title.tr());

  Widget get _content => SizedBox(
    width: _conversationLabelFilterDialogWidth,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Text(LocaleKeys.chats_screens_conversation_labels_filter_help.tr()),
        const SizedBox(height: _conversationLabelDialogSectionSpacing),
        _ConversationLabelCheckboxList(
          labels: widget.labels,
          selectedLabelIds: _selected,
          enabled: true,
          maxHeight: _conversationLabelFilterListMaxHeight,
          onChanged: _toggleLabel,
        ),
      ],
    ),
  );

  List<Widget> _actions(BuildContext context) => [
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
  ];

  void _toggleLabel({required String labelId, required bool selected}) =>
      setState(() {
        if (selected) {
          final _ = _selected.add(labelId);
        } else {
          final _ = _selected.remove(labelId);
        }
      });
}

class const _ConversationLabelCheckboxList({
  required final List<ConversationLabelEntity> labels,
  required final Set<String> selectedLabelIds,
  required final bool enabled,
  required final double maxHeight,
  required final void Function({
    required String labelId,
    required bool selected,
  })
  onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return Text(LocaleKeys.chats_screens_conversation_labels_empty.tr());
    }

    return _list();
  }

  Widget _list() => ConstrainedBox(
    constraints: .new(maxHeight: maxHeight),
    child: ListView.builder(
      itemBuilder: (_, index) => _checkbox(index),
      itemCount: labels.length,
    ),
  );

  Widget _checkbox(int index) {
    final label = labels[index];

    return _ConversationLabelCheckbox(
      label: label,
      selected: selectedLabelIds.contains(label.id),
      enabled: enabled,
      onChanged: (selected) =>
          onChanged(labelId: label.id, selected: selected),
    );
  }
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
      title: _title,
      content: _content(labels),
      actions: _actions(context),
    );
  }

  Widget get _title =>
      Text(LocaleKeys.chats_screens_conversation_labels_manage_title.tr());

  Widget _content(AsyncValue<List<ConversationLabelEntity>> labels) => SizedBox(
    width: _conversationLabelManageDialogWidth,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        _newLabelField(),
        const SizedBox(height: _conversationLabelDialogSectionSpacing),
        _managementList(labels),
      ],
    ),
  );

  Widget _newLabelField() => _NewConversationLabelField(
    enabled: !_isWorking,
    onCreate: (name) => _run(
      () => widget.actions.create(workspaceId: widget.workspaceId, name: name),
    ),
  );

  Widget _managementList(AsyncValue<List<ConversationLabelEntity>> labels) =>
      _ConversationLabelManagementList(
        labels: labels,
        enabled: !_isWorking,
        onRename: (label) => unawaited(_rename(label)),
        onDelete: (label) => unawaited(_delete(label)),
      );

  List<Widget> _actions(BuildContext context) => [
    TextButton(
      onPressed: _isWorking ? null : () => Navigator.of(context).pop(),
      child: const TextLocale(
        LocaleKeys.chats_screens_conversation_labels_done,
      ),
    ),
  ];

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

class const _ConversationLabelManagementList({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final bool enabled,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (labels) {
    AsyncData(:final value) => _dataState(value),
    AsyncError() => _errorState(),
    AsyncLoading() => _loadingState(),
  };

  Widget _dataState(List<ConversationLabelEntity> values) => values.isEmpty
      ? _emptyState()
      : _loadedState(values);

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: _conversationLabelDialogSectionSpacing,
    ),
    child: Text(LocaleKeys.chats_screens_conversation_labels_empty.tr()),
  );

  Widget _loadedState(List<ConversationLabelEntity> values) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: _conversationLabelAssignmentListMaxHeight,
    ),
    child: ListView.builder(
      itemBuilder: (context, index) => _ConversationLabelRow(
        label: values[index],
        enabled: enabled,
        onRename: () => onRename(values[index]),
        onDelete: () => onDelete(values[index]),
      ),
      itemCount: values.length,
    ),
  );

  Widget _errorState() =>
      Text(LocaleKeys.chats_screens_conversation_labels_load_error.tr());

  Widget _loadingState() => const Center(child: CircularProgressIndicator());
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
          decoration: .new(
            labelText: LocaleKeys.chats_screens_conversation_labels_label_name
                .tr(),
            errorText: _validationError,
            isDense: true,
          ),
          textInputAction: .done,
          maxLength: _conversationLabelNameMaxLength,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
          enabled: widget.enabled,
        ),
      ),
      const SizedBox(width: _conversationLabelRowGap),
      Padding(
        padding: const EdgeInsets.only(top: _conversationLabelFieldInset),
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
    if (name.isEmpty || name.length > _conversationLabelNameMaxLength) {
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
      decoration: .new(
        labelText: LocaleKeys.chats_screens_conversation_labels_label_name.tr(),
        errorText: _error,
      ),
      textInputAction: .done,
      autofocus: true,
      maxLength: _conversationLabelNameMaxLength,
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
    if (name.isEmpty || name.length > _conversationLabelNameMaxLength) {
      setState(
        () => _error = LocaleKeys.chats_screens_conversation_labels_invalid_name
            .tr(),
      );

      return;
    }
    Navigator.of(context).pop(name);
  }
}

abstract final class ConversationLabelDialogs {
  static Future<Set<String>?> showAssignment(
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
}

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
      title: _assignmentTitle,
      content: _assignmentContent(labels),
      actions: _assignmentActions(context),
    );
  }

  Widget get _assignmentTitle => Text(
    LocaleKeys.chats_screens_conversation_labels_assignment_title.tr(),
  );

  Widget _assignmentContent(
    AsyncValue<List<ConversationLabelEntity>> labels,
  ) => SizedBox(
    width: _conversationLabelFilterDialogWidth,
    child: _ConversationLabelAssignmentList(
      labels: labels,
      selectedLabelIds: _selected,
      enabled: !_isSaving,
      onChanged: _toggleAssignment,
    ),
  );

  List<Widget> _assignmentActions(BuildContext context) => [
    TextButton(
      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
      child: const TextLocale(LocaleKeys.common_cancel),
    ),
    TextButton(
      onPressed: _isSaving ? null : () => unawaited(_save()),
      child: const TextLocale(
        LocaleKeys.chats_screens_conversation_labels_save_assignments,
      ),
    ),
  ];

  void _toggleAssignment({required String labelId, required bool selected}) {
    setState(() {
      if (selected) {
        final _ = _selected.add(labelId);
      } else {
        final _ = _selected.remove(labelId);
      }
    });
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

class const _ConversationLabelAssignmentList({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final Set<String> selectedLabelIds,
  required final bool enabled,
  required final void Function({
    required String labelId,
    required bool selected,
  })
  onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (labels) {
    AsyncData(:final value) => _ConversationLabelCheckboxList(
      labels: value,
      selectedLabelIds: selectedLabelIds,
      enabled: enabled,
      maxHeight: _conversationLabelAssignmentListMaxHeight,
      onChanged: onChanged,
    ),
    AsyncError() => Text(
      LocaleKeys.chats_screens_conversation_labels_load_error.tr(),
    ),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

void _showLabelError(BuildContext context, {required String message}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final _ = messenger?.showSnackBar(.new(content: Text(message)));
}

class const _ConversationLabelCheckbox({
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
