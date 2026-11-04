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

    return _ConversationLabelToolbarContent(
      labels: labels,
      selectedLabelIds: widget.selectedLabelIds,
      onSelectedLabelIdsChanged: widget.onSelectedLabelIdsChanged,
      onOpenFilter: _openFilter,
      onOpenManage: _openManage,
    );
  }

  void _removeStaleSelections(
    AsyncValue<List<ConversationLabelEntity>> labels,
  ) {
    final selection = _staleSelection(labels);
    if (selection == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateStaleSelections(selection),
    );
  }

  Set<String>? _staleSelection(
    AsyncValue<List<ConversationLabelEntity>> labels,
  ) {
    if (labels is! AsyncData<List<ConversationLabelEntity>>) {
      return null;
    }
    final availableIds = labels.value.map((label) => label.id).toSet();
    final selection = widget.selectedLabelIds.intersection(availableIds);

    return selection.length == widget.selectedLabelIds.length
        ? null
        : selection;
  }

  void _updateStaleSelections(Set<String> validSelection) {
    if (!mounted || widget.selectedLabelIds.length == validSelection.length) {
      return;
    }
    widget.onSelectedLabelIdsChanged(validSelection);
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

class const _ConversationLabelToolbarContent({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final Set<String> selectedLabelIds,
  required final ValueChanged<Set<String>> onSelectedLabelIdsChanged,
  required final VoidCallback onOpenFilter,
  required final VoidCallback onOpenManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: _conversationLabelToolbarInset,
      top: _conversationLabelToolbarTopInset,
      right: _conversationLabelToolbarInset,
    ),
    child: _ConversationLabelToolbarActions(
      labels: labels,
      selectedLabelIds: selectedLabelIds,
      onSelectedLabelIdsChanged: onSelectedLabelIdsChanged,
      onOpenFilter: onOpenFilter,
      onOpenManage: onOpenManage,
    ),
  );
}

class const _ConversationLabelToolbarActions({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final Set<String> selectedLabelIds,
  required final ValueChanged<Set<String>> onSelectedLabelIdsChanged,
  required final VoidCallback onOpenFilter,
  required final VoidCallback onOpenManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _conversationLabelToolbarSpacing,
    runSpacing: _conversationLabelToolbarSpacing,
    crossAxisAlignment: .center,
    children: [
      _ConversationLabelFilterButton(
        labels: labels,
        count: selectedLabelIds.length,
        onPressed: onOpenFilter,
      ),
      _ConversationLabelManageButton(onPressed: onOpenManage),
      if (selectedLabelIds.isNotEmpty)
        _ConversationLabelClearButton(
          onPressed: () => onSelectedLabelIdsChanged(const {}),
        ),
    ],
  );
}

class const _ConversationLabelManageButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: Text(LocaleKeys.chats_screens_conversation_labels_manage.tr()),
    variant: .ghost,
    size: .small,
    identifier: 'conversation-label-manage',
  );
}

class const _ConversationLabelClearButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: Text(LocaleKeys.chats_screens_conversation_labels_clear_filter.tr()),
    variant: .ghost,
    size: .small,
    identifier: 'conversation-label-clear-filter',
  );
}

class const _ConversationLabelFilterButton({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final int count,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  String get _filterSemantics => count == 0
      ? LocaleKeys.chats_screens_conversation_labels_filter_semantics.tr()
      : LocaleKeys.chats_screens_conversation_labels_filter_count_semantics.tr(
          args: [count.toString()],
        );

  String get _selectedCountSemantics => LocaleKeys
      .chats_screens_conversation_labels_selected_count_semantics
      .tr(args: [count.toString()]);

  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: _ConversationLabelFilterButtonContent(
      count: count,
      selectedCountSemantics: _selectedCountSemantics,
    ),
    variant: count == 0 ? .secondary : .primary,
    size: .small,
    disabled: labels.isLoading || labels.hasError,
    identifier: 'conversation-label-filter',
    semanticLabel: _filterSemantics,
  );
}

class const _ConversationLabelFilterButtonContent({
  required final int count,
  required final String selectedCountSemantics,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
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
          semanticLabel: selectedCountSemantics,
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
  Widget build(BuildContext context) => _ConversationLabelFilterDialogView(
    labels: widget.labels,
    selectedLabelIds: _selected,
    onChanged: _toggleLabel,
  );

  void _toggleLabel({required String labelId, required bool selected}) =>
      setState(() {
        if (selected) {
          final _ = _selected.add(labelId);
        } else {
          final _ = _selected.remove(labelId);
        }
      });
}

class const _ConversationLabelFilterDialogView({
  required final List<ConversationLabelEntity> labels,
  required final Set<String> selectedLabelIds,
  required final void Function({
    required String labelId,
    required bool selected,
  })
  onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocaleKeys.chats_screens_conversation_labels_filter_title.tr()),
    content: _ConversationLabelFilterDialogBody(
      labels: labels,
      selectedLabelIds: selectedLabelIds,
      onChanged: onChanged,
    ),
    actions: [
      const _ConversationLabelCancelButton(),
      _ConversationLabelApplyButton(selectedLabelIds: selectedLabelIds),
    ],
  );
}

class const _ConversationLabelCancelButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}

class const _ConversationLabelApplyButton({
  required final Set<String> selectedLabelIds,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => Navigator.of(context).pop(selectedLabelIds),
    child: const TextLocale(LocaleKeys.chats_screens_conversation_labels_apply),
  );
}

class const _ConversationLabelFilterDialogBody({
  required final List<ConversationLabelEntity> labels,
  required final Set<String> selectedLabelIds,
  required final void Function({
    required String labelId,
    required bool selected,
  })
  onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: _conversationLabelFilterDialogWidth,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Text(LocaleKeys.chats_screens_conversation_labels_filter_help.tr()),
        const SizedBox(height: _conversationLabelDialogSectionSpacing),
        _ConversationLabelCheckboxList(
          labels: labels,
          selectedLabelIds: selectedLabelIds,
          enabled: true,
          maxHeight: _conversationLabelFilterListMaxHeight,
          onChanged: onChanged,
        ),
      ],
    ),
  );
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

    return _ConversationLabelCheckboxRows(
      labels: labels,
      selectedLabelIds: selectedLabelIds,
      enabled: enabled,
      maxHeight: maxHeight,
      onChanged: onChanged,
    );
  }
}

class const _ConversationLabelCheckboxRows({
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
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(maxHeight: maxHeight),
    child: ListView.builder(
      itemBuilder: (_, index) => _ConversationLabelCheckboxRow(
        label: labels[index],
        selectedLabelIds: selectedLabelIds,
        enabled: enabled,
        onChanged: onChanged,
      ),
      itemCount: labels.length,
    ),
  );
}

class const _ConversationLabelCheckboxRow({
  required final ConversationLabelEntity label,
  required final Set<String> selectedLabelIds,
  required final bool enabled,
  required final void Function({
    required String labelId,
    required bool selected,
  })
  onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ConversationLabelCheckbox(
    label: label,
    selected: selectedLabelIds.contains(label.id),
    enabled: enabled,
    onChanged: (selected) => onChanged(labelId: label.id, selected: selected),
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

    return _ConversationLabelManagementDialogView(
      labels: labels,
      isWorking: _isWorking,
      onCreate: _create,
      onRename: _onRename,
      onDelete: _onDelete,
    );
  }

  Future<bool> _create(String name) => _run(
    () => widget.actions.create(workspaceId: widget.workspaceId, name: name),
  );

  void _onRename(ConversationLabelEntity label) => unawaited(_rename(label));

  void _onDelete(ConversationLabelEntity label) => unawaited(_delete(label));

  Future<void> _rename(ConversationLabelEntity label) async {
    final name = await _requestConversationLabelRename(context, label);
    if (name == null || name == label.name) {
      return;
    }
    final _ = await _run(
      () => _renameConversationLabel(
        widget.actions,
        widget.workspaceId,
        label,
        name,
      ),
    );
  }

  Future<void> _delete(ConversationLabelEntity label) async {
    if (!await _confirmConversationLabelDelete(context)) {
      return;
    }
    final _ = await _run(
      () => _deleteConversationLabel(widget.actions, widget.workspaceId, label),
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

Future<String?> _requestConversationLabelRename(
  BuildContext context,
  ConversationLabelEntity label,
) => _showLabelNameDialog(
  context,
  title: LocaleKeys.chats_screens_conversation_labels_rename.tr(),
  initialName: label.name,
);

Future<bool> _confirmConversationLabelDelete(BuildContext context) async {
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

  return confirmed == true;
}

Future<Object?> _renameConversationLabel(
  ConversationLabelActions actions,
  String workspaceId,
  ConversationLabelEntity label,
  String name,
) => actions.rename(workspaceId: workspaceId, labelId: label.id, name: name);

Future<Object?> _deleteConversationLabel(
  ConversationLabelActions actions,
  String workspaceId,
  ConversationLabelEntity label,
) => actions.delete(workspaceId: workspaceId, labelId: label.id);

class const _ConversationLabelManagementDialogView({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final bool isWorking,
  required final Future<bool> Function(String name) onCreate,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocaleKeys.chats_screens_conversation_labels_manage_title.tr()),
    content: _ConversationLabelManagementDialogBody(
      labels: labels,
      enabled: !isWorking,
      onCreate: onCreate,
      onRename: onRename,
      onDelete: onDelete,
    ),
    actions: [_ConversationLabelDoneButton(isWorking: isWorking)],
  );
}

class const _ConversationLabelDoneButton({required final bool isWorking})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: isWorking ? null : () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.chats_screens_conversation_labels_done),
  );
}

class const _ConversationLabelManagementDialogBody({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final bool enabled,
  required final Future<bool> Function(String name) onCreate,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: _conversationLabelManageDialogWidth,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        _NewConversationLabelField(enabled: enabled, onCreate: onCreate),
        const SizedBox(height: _conversationLabelDialogSectionSpacing),
        _ConversationLabelManagementList(
          labels: labels,
          enabled: enabled,
          onRename: onRename,
          onDelete: onDelete,
        ),
      ],
    ),
  );
}

class const _ConversationLabelManagementList({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final bool enabled,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (labels) {
    AsyncData(:final value) => _ConversationLabelManagementData(
      labels: value,
      enabled: enabled,
      onRename: onRename,
      onDelete: onDelete,
    ),
    AsyncError() => Text(
      LocaleKeys.chats_screens_conversation_labels_load_error.tr(),
    ),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

class const _ConversationLabelManagementData({
  required final List<ConversationLabelEntity> labels,
  required final bool enabled,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => labels.isEmpty
      ? Padding(
          padding: const EdgeInsets.symmetric(
            vertical: _conversationLabelDialogSectionSpacing,
          ),
          child: Text(LocaleKeys.chats_screens_conversation_labels_empty.tr()),
        )
      : _ConversationLabelManagementRows(
          labels: labels,
          enabled: enabled,
          onRename: onRename,
          onDelete: onDelete,
        );
}

class const _ConversationLabelManagementRows({
  required final List<ConversationLabelEntity> labels,
  required final bool enabled,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ConversationLabelManagementListView(
    labels: labels,
    enabled: enabled,
    onRename: onRename,
    onDelete: onDelete,
  );
}

class const _ConversationLabelManagementListView({
  required final List<ConversationLabelEntity> labels,
  required final bool enabled,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: _conversationLabelAssignmentListMaxHeight,
    ),
    child: ListView.builder(
      itemBuilder: (_, index) => _ConversationLabelManagementListItem(
        label: labels[index],
        enabled: enabled,
        onRename: onRename,
        onDelete: onDelete,
      ),
      itemCount: labels.length,
    ),
  );
}

class const _ConversationLabelManagementListItem({
  required final ConversationLabelEntity label,
  required final bool enabled,
  required final ValueChanged<ConversationLabelEntity> onRename,
  required final ValueChanged<ConversationLabelEntity> onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ConversationLabelRow(
    label: label,
    enabled: enabled,
    onRename: () => onRename(label),
    onDelete: () => onDelete(label),
  );
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
  Widget build(BuildContext context) => _NewConversationLabelFieldLayout(
    enabled: widget.enabled,
    controller: _controller,
    error: _validationError,
    onChanged: _onChanged,
    onSubmitted: _onSubmitted,
    onCreate: _submitFromButton,
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

class const _NewConversationLabelFieldLayout({
  required final bool enabled,
  required final TextEditingController controller,
  required final String? error,
  required final ValueChanged<String> onChanged,
  required final ValueChanged<String> onSubmitted,
  required final VoidCallback onCreate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    children: [
      Expanded(
        child: _NewConversationLabelNameInput(
          controller: controller,
          error: error,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          enabled: enabled,
        ),
      ),
      const SizedBox(width: _conversationLabelRowGap),
      Padding(
        padding: const EdgeInsets.only(top: _conversationLabelFieldInset),
        child: _NewConversationLabelCreateButton(
          enabled: enabled,
          onPressed: onCreate,
        ),
      ),
    ],
  );
}

class const _NewConversationLabelNameInput({
  required final TextEditingController controller,
  required final String? error,
  required final ValueChanged<String> onChanged,
  required final ValueChanged<String> onSubmitted,
  required final bool enabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(
      labelText: LocaleKeys.chats_screens_conversation_labels_label_name.tr(),
      errorText: error,
      isDense: true,
    ),
    textInputAction: .done,
    maxLength: _conversationLabelNameMaxLength,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    enabled: enabled,
  );
}

class const _NewConversationLabelCreateButton({
  required final bool enabled,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.add,
    onPressed: enabled ? onPressed : null,
    tooltip: LocaleKeys.chats_screens_conversation_labels_create.tr(),
  );
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
    trailing: _ConversationLabelRowActions(
      enabled: enabled,
      onRename: onRename,
      onDelete: onDelete,
    ),
    dense: true,
  );
}

class const _ConversationLabelRowActions({
  required final bool enabled,
  required final VoidCallback onRename,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
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
    content: _ConversationLabelNameInput(
      controller: _controller,
      error: _error,
      onSubmitted: _submit,
    ),
    actions: [
      const _ConversationLabelCancelButton(),
      _ConversationLabelSaveButton(onPressed: _submit),
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

class const _ConversationLabelNameInput({
  required final TextEditingController controller,
  required final String? error,
  required final VoidCallback onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(
      labelText: LocaleKeys.chats_screens_conversation_labels_label_name.tr(),
      errorText: error,
    ),
    textInputAction: .done,
    autofocus: true,
    maxLength: _conversationLabelNameMaxLength,
    onSubmitted: (_) => onSubmitted(),
  );
}

class const _ConversationLabelSaveButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.common_save),
  );
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

    return _ConversationLabelAssignmentDialogView(
      labels: labels,
      selectedLabelIds: _selected,
      isSaving: _isSaving,
      onChanged: _toggleAssignment,
      onSave: () => unawaited(_save()),
    );
  }

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
      await _assignLabels();
    } on Object catch (_) {
      _showAssignmentError();
    } finally {
      _finishSaving();
    }
  }

  Future<void> _assignLabels() async {
    await widget.actions.assign(
      workspaceId: widget.workspaceId,
      conversationId: widget.conversation.id,
      labelIds: _selected,
    );
    if (mounted) {
      Navigator.of(context).pop(_selected);
    }
  }

  void _showAssignmentError() {
    if (mounted) {
      _showLabelError(
        context,
        message: LocaleKeys.chats_screens_conversation_labels_save_error.tr(),
      );
    }
  }

  void _finishSaving() {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

class const _ConversationLabelAssignmentDialogView({
  required final AsyncValue<List<ConversationLabelEntity>> labels,
  required final Set<String> selectedLabelIds,
  required final bool isSaving,
  required final void Function({
    required String labelId,
    required bool selected,
  })
  onChanged,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      LocaleKeys.chats_screens_conversation_labels_assignment_title.tr(),
    ),
    content: _ConversationLabelAssignmentDialogBody(
      labels: labels,
      selectedLabelIds: selectedLabelIds,
      enabled: !isSaving,
      onChanged: onChanged,
    ),
    actions: [
      _ConversationLabelAssignmentCancelButton(isSaving: isSaving),
      _ConversationLabelAssignmentSaveButton(
        isSaving: isSaving,
        onSave: onSave,
      ),
    ],
  );
}

class const _ConversationLabelAssignmentCancelButton({
  required final bool isSaving,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: isSaving ? null : () => Navigator.of(context).pop(),
    child: const TextLocale(LocaleKeys.common_cancel),
  );
}

class const _ConversationLabelAssignmentSaveButton({
  required final bool isSaving,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: isSaving ? null : onSave,
    child: const TextLocale(
      LocaleKeys.chats_screens_conversation_labels_save_assignments,
    ),
  );
}

class const _ConversationLabelAssignmentDialogBody({
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
  Widget build(BuildContext context) => SizedBox(
    width: _conversationLabelFilterDialogWidth,
    child: _ConversationLabelAssignmentList(
      labels: labels,
      selectedLabelIds: selectedLabelIds,
      enabled: enabled,
      onChanged: onChanged,
    ),
  );
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
