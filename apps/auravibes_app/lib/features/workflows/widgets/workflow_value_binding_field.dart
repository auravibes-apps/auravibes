import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

abstract final class WorkflowValueTypeLabel {
  static const _keys = <WorkflowValueType, String>{
    .any: LocaleKeys.workflow_editor_type_any,
    .string: LocaleKeys.workflow_editor_type_string,
    .integer: LocaleKeys.workflow_editor_type_integer,
    .number: LocaleKeys.workflow_editor_type_number,
    .boolean: LocaleKeys.workflow_editor_type_boolean,
    .object: LocaleKeys.workflow_editor_type_object,
    .array: LocaleKeys.workflow_editor_type_array,
  };

  static String text(WorkflowValueType type, BuildContext context) =>
      _keys[type]!.tr(context: context);
}

class WorkflowValueBindingField extends HookWidget {
  const WorkflowValueBindingField({
    required this.field,
    required this.binding,
    required this.sources,
    required this.isWide,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final WorkflowField field;
  final WorkflowBinding? binding;
  final List<WorkflowNode> sources;
  final bool isWide;
  final bool enabled;
  final ValueChanged<WorkflowBinding> onChanged;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final currentBinding = binding;
    final isBound = currentBinding?.isStatic == false;
    final reference = isBound
        ? _referenceFor(
            sources,
            currentBinding!.sourceNodeId,
            currentBinding.jsonPointer,
          )
        : null;
    final staticDraftIsInvalid =
        currentBinding != null &&
        currentBinding.hasStaticDraft &&
        (currentBinding.staticDraftHasValue
            ? !WorkflowGraphValidation.workflowValueMatchesField(
                currentBinding.staticDraft,
                field,
              )
            : field.isRequired && !field.hasDefaultValue);

    if (isBound) {
      final currentLabel =
          reference?.label ??
          LocaleKeys.workflow_editor_binding_unavailable.tr(context: context);
      return Column(
        crossAxisAlignment: .stretch,
        children: [
          AuraInput(
            focusNode: focusNode,
            readOnly: true,
            enabled: enabled,
            initialValue: '',
            label: Text(field.name),
            hint: Text(
              LocaleKeys.workflow_editor_choose_value.tr(context: context),
            ),
            onTap: enabled ? () => _choose(context, focusNode) : null,
            prefixIcon: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: AuraBadge.text(
                size: .small,
                variant: reference == null ? .error : .info,
                semanticLabel: currentLabel,
                child: Text(currentLabel, maxLines: 1, overflow: .ellipsis),
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: .min,
              children: [
                AuraIconButton(
                  icon: Icons.edit,
                  size: .small,
                  disabled: !enabled,
                  tooltip: LocaleKeys.workflow_editor_choose_value.tr(
                    context: context,
                  ),
                  semanticLabel: LocaleKeys.workflow_editor_choose_value.tr(
                    context: context,
                  ),
                  onPressed: enabled ? () => _choose(context, focusNode) : null,
                ),
                AuraIconButton(
                  icon: Icons.link_off,
                  size: .small,
                  disabled: !enabled,
                  tooltip: LocaleKeys.workflow_editor_use_static_value.tr(
                    context: context,
                  ),
                  semanticLabel: LocaleKeys.workflow_editor_use_static_value.tr(
                    context: context,
                  ),
                  onPressed: enabled ? _restoreStatic : null,
                ),
              ],
            ),
          ),
          if (binding?.hasStaticDraft == true)
            TextLocale(
              staticDraftIsInvalid
                  ? LocaleKeys.workflow_editor_static_draft_invalid
                  : LocaleKeys.workflow_editor_static_draft_saved,
            ),
        ],
      );
    }

    final current = _staticValue;
    return Focus(
      focusNode: focusNode,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          WorkflowStaticValueEditor(
            field: field,
            value: current.value,
            hasValue: current.hasValue,
            enabled: enabled,
            onChooseBinding: enabled ? () => _choose(context, focusNode) : null,
            showBindingLabel: isWide,
            onChanged: (value, hasValue) => onChanged(
              WorkflowBinding.staticValue(value, hasValue: hasValue),
            ),
          ),
        ],
      ),
    );
  }

  ({Object? value, bool hasValue}) get _staticValue {
    final value = binding;
    if (value == null) {
      return (value: field.defaultValue, hasValue: field.hasDefaultValue);
    }
    if (!value.isStatic) {
      if (value.hasStaticDraft) {
        return (value: value.staticDraft, hasValue: value.staticDraftHasValue);
      }
      return (value: field.defaultValue, hasValue: field.hasDefaultValue);
    }
    return (value: value.value, hasValue: value.hasValue);
  }

  Future<void> _choose(BuildContext context, FocusNode focusNode) async {
    final selected = isWide
        ? await showDialog<_WorkflowValueReference>(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 640,
                ),
                child: AuraCard(
                  padding: .medium,
                  style: .border,
                  child: _WorkflowValuePicker(
                    sources: sources,
                    target: field,
                    onSelected: (value) => Navigator.of(context).pop(value),
                  ),
                ),
              ),
            ),
          )
        : await showModalBottomSheet<_WorkflowValueReference>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
              final availableHeight =
                  MediaQuery.sizeOf(context).height - bottomInset;
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SizedBox(
                    height: availableHeight * .78,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AuraCard(
                        padding: .medium,
                        style: .border,
                        child: _WorkflowValuePicker(
                          sources: sources,
                          target: field,
                          onSelected: (value) =>
                              Navigator.of(context).pop(value),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
    if (!context.mounted) return;
    focusNode.requestFocus();
    if (selected == null) return;

    final draft = _draftValue;
    onChanged(
      WorkflowBinding.fromNode(
        sourceNodeId: selected.node.id,
        jsonPointer: selected.pointer,
        staticDraft: draft.hasDraft ? draft.value : null,
        hasStaticDraft: draft.hasDraft,
        staticDraftHasValue: draft.hasValue,
      ),
    );
  }

  ({Object? value, bool hasDraft, bool hasValue}) get _draftValue {
    final current = binding;
    if (current?.isStatic == true) {
      return (
        value: current!.value,
        hasDraft: true,
        hasValue: current.hasValue,
      );
    }
    if (current?.hasStaticDraft == true) {
      return (
        value: current!.staticDraft,
        hasDraft: true,
        hasValue: current.staticDraftHasValue,
      );
    }
    return (
      value: field.defaultValue,
      hasDraft: false,
      hasValue: field.hasDefaultValue,
    );
  }

  void _restoreStatic() {
    final draft = _draftValue;
    onChanged(
      WorkflowBinding.staticValue(draft.value, hasValue: draft.hasValue),
    );
  }
}

class WorkflowSourceFieldPicker extends HookWidget {
  const WorkflowSourceFieldPicker({
    required this.label,
    required this.sources,
    required this.selectedNodeId,
    required this.selectedPointer,
    required this.isWide,
    required this.enabled,
    required this.onSelected,
    this.target,
    super.key,
  });

  final String label;
  final List<WorkflowNode> sources;
  final String? selectedNodeId;
  final String? selectedPointer;
  final WorkflowField? target;
  final bool isWide;
  final bool enabled;
  final ValueChanged<WorkflowBinding> onSelected;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final reference = _referenceFor(sources, selectedNodeId, selectedPointer);
    return AuraInput(
      focusNode: focusNode,
      readOnly: true,
      enabled: enabled,
      label: Text(label),
      initialValue: '',
      hint: Text(LocaleKeys.workflow_editor_choose_value.tr(context: context)),
      onTap: enabled ? () => _choose(context, focusNode) : null,
      prefixIcon: reference == null
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: AuraBadge.text(
                size: .small,
                semanticLabel: reference.label,
                child: Text(reference.label, maxLines: 1, overflow: .ellipsis),
              ),
            ),
      suffixIcon: AuraIconButton(
        icon: Icons.expand_more,
        size: .small,
        disabled: !enabled,
        tooltip: LocaleKeys.workflow_editor_choose_value.tr(context: context),
        semanticLabel: LocaleKeys.workflow_editor_choose_value.tr(
          context: context,
        ),
        onPressed: enabled ? () => _choose(context, focusNode) : null,
      ),
    );
  }

  Future<void> _choose(BuildContext context, FocusNode focusNode) async {
    final selected = isWide
        ? await showDialog<_WorkflowValueReference>(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 640,
                ),
                child: AuraCard(
                  padding: .medium,
                  style: .border,
                  child: _WorkflowValuePicker(
                    sources: sources,
                    target: target,
                    onSelected: (value) => Navigator.of(context).pop(value),
                  ),
                ),
              ),
            ),
          )
        : await showModalBottomSheet<_WorkflowValueReference>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
              final availableHeight =
                  MediaQuery.sizeOf(context).height - bottomInset;
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SizedBox(
                    height: availableHeight * .78,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AuraCard(
                        padding: .medium,
                        style: .border,
                        child: _WorkflowValuePicker(
                          sources: sources,
                          target: target,
                          onSelected: (value) =>
                              Navigator.of(context).pop(value),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
    if (!context.mounted) return;
    focusNode.requestFocus();
    if (selected == null) return;
    onSelected(
      WorkflowBinding.fromNode(
        sourceNodeId: selected.node.id,
        jsonPointer: selected.pointer,
      ),
    );
  }
}

class const _WorkflowValuePicker({
  required final List<WorkflowNode> sources,
  required final WorkflowField? target,
  required final ValueChanged<_WorkflowValueReference> onSelected,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final query = useState('');
    final normalizedQuery = query.value.trim().toLowerCase();
    final matchingSources = [
      for (final source in sources)
        if (normalizedQuery.isEmpty ||
            source.label.toLowerCase().contains(normalizedQuery) ||
            source.outputFields.any(
              (field) => _treeMatches(field, normalizedQuery),
            ))
          source,
    ];
    final sourceQueries = {
      for (final source in matchingSources)
        source.id: source.label.toLowerCase().contains(normalizedQuery)
            ? ''
            : normalizedQuery,
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.workflow_editor_choose_value.tr(context: context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AuraIconButton(
                icon: Icons.close,
                tooltip: LocaleKeys.workflow_editor_close_picker.tr(
                  context: context,
                ),
                semanticLabel: LocaleKeys.workflow_editor_close_picker.tr(
                  context: context,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          AuraInput(
            onChanged: (value) => query.value = value,
            size: .small,
            autofocus: true,
            label: Text(
              LocaleKeys.workflow_editor_search_values.tr(context: context),
            ),
            prefixIcon: const Icon(Icons.search),
          ),
          if (target != null)
            const TextLocale(LocaleKeys.workflow_editor_compatible_value_hint),
          const SizedBox(height: 8),
          Expanded(
            child: matchingSources.isEmpty
                ? Center(
                    child: TextLocale(
                      normalizedQuery.isEmpty
                          ? LocaleKeys.workflow_editor_no_values
                          : LocaleKeys.workflow_editor_no_matching_values,
                    ),
                  )
                : ListView(
                    children: [
                      for (final source in matchingSources)
                        AuraAccordion(
                          key: ValueKey('${source.id}-$normalizedQuery'),
                          initiallyExpanded: normalizedQuery.isEmpty
                              ? const {}
                              : const {0},
                          items: [
                            AuraAccordionItem(
                              title: source.label,
                              child: Column(
                                crossAxisAlignment: .stretch,
                                children: [
                                  for (final field in source.outputFields)
                                    _WorkflowValueTree(
                                      node: source,
                                      field: field,
                                      pointer: '/${_escape(field.name)}',
                                      path: [field.name],
                                      target: target,
                                      query: sourceQueries[source.id]!,
                                      onSelected: onSelected,
                                      depth: 0,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class const _WorkflowValueTree({
  required final WorkflowNode node,
  required final WorkflowField field,
  required final String pointer,
  required final List<String> path,
  required final WorkflowField? target,
  required final String query,
  required final ValueChanged<_WorkflowValueReference> onSelected,
  required final int depth,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final children = field.type == .array
        ? [if (field.items != null) field.items!]
        : field.properties;
    final childPointer = field.type == .array ? '$pointer/0' : pointer;
    final matches =
        query.isEmpty ||
        path.join(' ').toLowerCase().contains(query) ||
        field.name.toLowerCase().contains(query);
    if (!matches && !children.any((child) => _treeMatches(child, query))) {
      return const SizedBox.shrink();
    }
    final expected = target;
    final canSelect = expected == null || _compatible(field, expected);
    final row = AuraTile(
      variant: .ghost,
      size: .small,
      enabled: canSelect,
      onTap: canSelect
          ? () => onSelected(
              _WorkflowValueReference(
                node: node,
                field: field,
                pointer: pointer,
                label: '${node.label} · ${path.join(' · ')}',
              ),
            )
          : null,
      semanticLabel:
          '${path.join(' · ')}, ${WorkflowValueTypeLabel.text(field.type, context)}',
      leading: const Icon(Icons.data_object),
      trailing: canSelect
          ? const Icon(Icons.call_made)
          : const Icon(Icons.block),
      child: Row(
        children: [
          Expanded(child: Text(field.name, maxLines: 1, overflow: .ellipsis)),
          const SizedBox(width: 8),
          AuraBadge.text(
            size: .small,
            variant: canSelect ? .neutral : .outlined,
            child: Text(WorkflowValueTypeLabel.text(field.type, context)),
          ),
        ],
      ),
    );
    if (children.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: depth * 12.0),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            row,
            if (!canSelect)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: TextLocale(
                  LocaleKeys.workflow_editor_value_not_compatible,
                  style: TextStyle(color: context.auraColors.error),
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          row,
          if (!canSelect)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: TextLocale(
                LocaleKeys.workflow_editor_value_not_compatible,
                style: TextStyle(color: context.auraColors.error),
              ),
            ),
          AuraAccordion(
            key: ValueKey('$pointer-$query'),
            initiallyExpanded: query.isEmpty ? const {} : const {0},
            items: [
              AuraAccordionItem(
                title: LocaleKeys.workflow_editor_nested_values.tr(
                  context: context,
                  namedArgs: {'name': field.name},
                ),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    for (final child in children)
                      _WorkflowValueTree(
                        node: node,
                        field: child,
                        pointer: field.type == .array
                            ? childPointer
                            : '$pointer/${_escape(child.name)}',
                        path: [...path, child.name],
                        target: target,
                        query: query,
                        onSelected: onSelected,
                        depth: depth + 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkflowStaticValueEditor extends HookWidget {
  const WorkflowStaticValueEditor({
    required this.field,
    required this.value,
    required this.hasValue,
    required this.enabled,
    required this.onChanged,
    this.onChooseBinding,
    this.valueLabelKey,
    this.showBindingLabel = false,
  });

  final WorkflowField field;
  final Object? value;
  final bool hasValue;
  final bool enabled;
  final void Function(Object?, bool) onChanged;
  final VoidCallback? onChooseBinding;
  final String? valueLabelKey;
  final bool showBindingLabel;

  @override
  Widget build(BuildContext context) {
    final inferredType =
        _valueType(value) ??
        (field.type == .any ? WorkflowValueType.string : field.type);
    final selectedType = useState(inferredType);
    final editorField = field.type == .any
        ? field.copyWith(type: selectedType.value)
        : field;
    final valueMatches =
        !hasValue ||
        WorkflowGraphValidation.workflowValueMatchesField(value, editorField);
    final structuredValueCanBeRepaired =
        editorField.type == .object && value is Map ||
        editorField.type == .array && value is List;
    final hasInvalidStructuredValue =
        hasValue && !valueMatches && structuredValueCanBeRepaired;
    final needsValueRepair =
        hasValue && !valueMatches && !structuredValueCanBeRepaired;
    final isScalar =
        editorField.type == .string ||
        editorField.type == .integer ||
        editorField.type == .number;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (field.type == .any)
          AuraDropdownSelector<WorkflowValueType>(
            value: selectedType.value,
            isEnabled: enabled,
            label: Text(
              LocaleKeys.workflow_editor_value_type.tr(context: context),
            ),
            options: [
              for (final type in WorkflowValueType.values.where(
                (item) => item != .any,
              ))
                AuraDropdownOption<WorkflowValueType>(
                  value: type,
                  child: Text(WorkflowValueTypeLabel.text(type, context)),
                ),
            ],
            onChanged: (type) {
              if (type == null) return;
              selectedType.value = type;
              if (hasValue &&
                  value != null &&
                  _matchesValueType(value!, type)) {
                return;
              }
              onChanged(_emptyValueOfType(type), true);
            },
          ),
        if (field.type != .any)
          Text(
            WorkflowValueTypeLabel.text(field.type, context),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        if (!isScalar && valueLabelKey != null) TextLocale(valueLabelKey!),
        if (needsValueRepair)
          Column(
            crossAxisAlignment: .stretch,
            children: [
              TextLocale(
                LocaleKeys.workflow_editor_value_schema_changed,
                style: TextStyle(color: context.auraColors.error),
              ),
              Wrap(
                alignment: .end,
                spacing: 8,
                children: [
                  if (onChooseBinding != null) _bindingPickerButton(context),
                  AuraButton(
                    variant: .outlined,
                    size: .small,
                    disabled: !enabled,
                    onPressed: enabled
                        ? () => onChanged(
                            _emptyValueFor(editorField, useDefault: false),
                            true,
                          )
                        : () {},
                    child: Text(
                      LocaleKeys.workflow_editor_repair_value.tr(
                        context: context,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        if (hasInvalidStructuredValue)
          TextLocale(
            LocaleKeys.workflow_editor_value_schema_changed,
            style: TextStyle(color: context.auraColors.error),
          ),
        if (!needsValueRepair &&
            onChooseBinding != null &&
            editorField.type != .string &&
            editorField.type != .integer &&
            editorField.type != .number &&
            !(hasValue && value == null))
          Align(alignment: .centerRight, child: _bindingPickerButton(context)),
        if (!needsValueRepair) _valueEditor(context, editorField),
        if (field.nullable || !field.isRequired || field.hasDefaultValue)
          Wrap(
            spacing: 8,
            children: [
              if (field.nullable && !(hasValue && value == null))
                AuraButton(
                  variant: .text,
                  size: .small,
                  disabled: !enabled,
                  onPressed: enabled ? () => onChanged(null, true) : () {},
                  child: Text(
                    LocaleKeys.workflow_editor_set_null.tr(context: context),
                  ),
                ),
              if (hasValue && (!field.isRequired || field.hasDefaultValue))
                AuraButton(
                  variant: .text,
                  size: .small,
                  disabled: !enabled,
                  onPressed: enabled ? () => onChanged(null, false) : () {},
                  child: Text(
                    LocaleKeys.workflow_editor_leave_empty.tr(context: context),
                  ),
                ),
              if (field.hasDefaultValue &&
                  (value != field.defaultValue || !hasValue))
                AuraButton(
                  variant: .text,
                  size: .small,
                  disabled: !enabled,
                  onPressed: enabled
                      ? () => onChanged(field.defaultValue, true)
                      : () {},
                  child: Text(
                    LocaleKeys.workflow_editor_use_default.tr(context: context),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _valueEditor(BuildContext context, WorkflowField currentField) {
    if (hasValue && value == null) {
      return Row(
        children: [
          const Expanded(
            child: TextLocale(LocaleKeys.workflow_editor_value_is_null),
          ),
          AuraButton(
            variant: .text,
            size: .small,
            disabled: !enabled,
            onPressed: enabled
                ? () => onChanged(_emptyValueFor(currentField), true)
                : () {},
            child: Text(
              LocaleKeys.workflow_editor_enter_value.tr(context: context),
            ),
          ),
          if (onChooseBinding case final onChooseBinding?)
            _bindingPickerButton(context, onChooseBinding),
        ],
      );
    }
    if (!hasValue) {
      if (currentField.type == .object || currentField.type == .array) {
        return AuraButton(
          variant: .outlined,
          size: .small,
          disabled: !enabled,
          onPressed: enabled
              ? () => onChanged(_emptyValueFor(currentField), true)
              : () {},
          child: Text(
            currentField.type == .object
                ? LocaleKeys.workflow_editor_start_object.tr(context: context)
                : LocaleKeys.workflow_editor_add_array_item.tr(
                    context: context,
                  ),
          ),
        );
      }
      if (currentField.type == .boolean) {
        return AuraButton(
          variant: .outlined,
          size: .small,
          disabled: !enabled,
          onPressed: enabled ? () => onChanged(false, true) : () {},
          child: Text(
            LocaleKeys.workflow_editor_enter_value.tr(context: context),
          ),
        );
      }
      return _ScalarWorkflowValueEditor(
        field: currentField,
        value: _emptyValueFor(currentField) ?? '',
        enabled: enabled,
        onChooseBinding: onChooseBinding,
        valueLabelKey: valueLabelKey,
        showBindingLabel: showBindingLabel,
        onChanged: (value) => onChanged(value, true),
      );
    }
    return switch (currentField.type) {
      .any => const SizedBox.shrink(),
      .string || .integer || .number => _ScalarWorkflowValueEditor(
        field: currentField,
        value: value ?? _emptyValueFor(currentField) ?? '',
        enabled: enabled,
        onChooseBinding: onChooseBinding,
        valueLabelKey: valueLabelKey,
        showBindingLabel: showBindingLabel,
        onChanged: (value) => onChanged(value, true),
      ),
      .boolean => AuraSwitch(
        value: value == true,
        semanticLabel: field.name,
        onChanged: enabled ? (value) => onChanged(value, true) : null,
        disabled: !enabled,
      ),
      .object => _ObjectWorkflowValueEditor(
        field: currentField,
        value: value,
        enabled: enabled,
        onChanged: (value) => onChanged(value, true),
      ),
      .array => _ArrayWorkflowValueEditor(
        field: currentField,
        value: value,
        enabled: enabled,
        onChanged: (value) => onChanged(value, true),
      ),
    };
  }

  Widget _bindingPickerButton(
    BuildContext context, [
    VoidCallback? onPressed,
  ]) => _workflowBindingAction(
    context,
    onPressed: onPressed ?? onChooseBinding,
    showLabel: showBindingLabel,
  );
}

class _ScalarWorkflowValueEditor extends HookWidget {
  const _ScalarWorkflowValueEditor({
    required this.field,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onChooseBinding,
    this.valueLabelKey,
    this.showBindingLabel = false,
  });

  final WorkflowField field;
  final Object value;
  final bool enabled;
  final ValueChanged<Object> onChanged;
  final VoidCallback? onChooseBinding;
  final String? valueLabelKey;
  final bool showBindingLabel;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value.toString());
    if (controller.text != value.toString()) controller.text = value.toString();
    return AuraInput(
      controller: controller,
      enabled: enabled,
      readOnly: !enabled,
      label: Text(
        (valueLabelKey ?? LocaleKeys.workflow_editor_static_value).tr(
          context: context,
        ),
      ),
      suffixIcon: onChooseBinding == null
          ? null
          : _workflowBindingAction(
              context,
              onPressed: onChooseBinding,
              showLabel: showBindingLabel,
            ),
      keyboardType: _keyboardType(field.type),
      onChanged: (text) {
        if (field.type == .string) {
          onChanged(text);
          return;
        }
        final parsed = num.tryParse(text);
        if (parsed == null || field.type == .integer && parsed is! int) return;
        onChanged(field.type == .integer ? parsed.toInt() : parsed);
      },
    );
  }
}

Widget _workflowBindingAction(
  BuildContext context, {
  required VoidCallback? onPressed,
  required bool showLabel,
}) {
  final label = LocaleKeys.workflow_editor_choose_value.tr(context: context);
  if (showLabel) {
    return AuraButton(
      variant: .text,
      size: .small,
      disabled: onPressed == null,
      onPressed: onPressed ?? () {},
      child: Row(
        mainAxisSize: .min,
        children: [
          const Icon(Icons.link),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
  return AuraIconButton(
    icon: Icons.link,
    size: .small,
    disabled: onPressed == null,
    tooltip: label,
    semanticLabel: label,
    onPressed: onPressed,
  );
}

class _ObjectWorkflowValueEditor extends HookWidget {
  const _ObjectWorkflowValueEditor({
    required this.field,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final WorkflowField field;
  final Object? value;
  final bool enabled;
  final ValueChanged<Map<String, Object?>> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value is Map
        ? Map<String, Object?>.from(value! as Map)
        : <String, Object?>{};
    final newName = useState('');
    final nameController = useTextEditingController();
    final dynamic = field.properties.isEmpty;
    final fields = dynamic
        ? [
            for (final entry in current.entries)
              WorkflowField(
                id: entry.key,
                name: entry.key,
                type: _valueType(entry.value) ?? .any,
                isRequired: false,
                nullable: entry.value == null,
              ),
          ]
        : field.properties;
    final unknownFields = dynamic
        ? const <String>[]
        : current.keys
              .where(
                (name) => !field.properties.any((item) => item.name == name),
              )
              .toList();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final name in unknownFields)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(name, maxLines: 1, overflow: .ellipsis),
                      const TextLocale(
                        LocaleKeys.workflow_editor_unknown_object_field,
                      ),
                    ],
                  ),
                ),
                AuraIconButton(
                  icon: Icons.close,
                  size: .small,
                  tooltip: LocaleKeys.workflow_editor_remove_item.tr(
                    context: context,
                  ),
                  semanticLabel: LocaleKeys.workflow_editor_remove_item.tr(
                    context: context,
                  ),
                  onPressed: enabled
                      ? () {
                          current.remove(name);
                          onChanged(current);
                        }
                      : null,
                ),
              ],
            ),
          ),
        for (final child in fields)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(child.name)),
                    if (child.isRequired)
                      AuraBadge.text(
                        size: .small,
                        variant: .outlined,
                        child: const TextLocale(
                          LocaleKeys.workflow_editor_required,
                        ),
                      ),
                    if (dynamic)
                      AuraIconButton(
                        icon: Icons.close,
                        size: .small,
                        tooltip: LocaleKeys.workflow_editor_remove_item.tr(
                          context: context,
                        ),
                        semanticLabel: LocaleKeys.workflow_editor_remove_item
                            .tr(context: context),
                        onPressed: enabled
                            ? () {
                                current.remove(child.name);
                                onChanged(current);
                              }
                            : null,
                      ),
                  ],
                ),
                if (child.description.isNotEmpty)
                  Text(
                    child.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                WorkflowStaticValueEditor(
                  field: child,
                  value: current[child.name],
                  hasValue: current.containsKey(child.name),
                  enabled: enabled,
                  onChanged: (value, hasValue) {
                    if (hasValue) {
                      current[child.name] = value;
                    } else {
                      current.remove(child.name);
                    }
                    onChanged(current);
                  },
                ),
              ],
            ),
          ),
        if (dynamic)
          Row(
            children: [
              Expanded(
                child: AuraInput(
                  controller: nameController,
                  enabled: enabled,
                  size: .small,
                  label: Text(
                    LocaleKeys.workflow_editor_field_name.tr(context: context),
                  ),
                  onChanged: (value) => newName.value = value,
                ),
              ),
              AuraIconButton(
                icon: Icons.add,
                tooltip: LocaleKeys.workflow_editor_add_field.tr(
                  context: context,
                ),
                semanticLabel: LocaleKeys.workflow_editor_add_field.tr(
                  context: context,
                ),
                onPressed:
                    enabled &&
                        newName.value.trim().isNotEmpty &&
                        !current.containsKey(newName.value.trim())
                    ? () {
                        current[newName.value.trim()] = '';
                        nameController.clear();
                        newName.value = '';
                        onChanged(current);
                      }
                    : null,
              ),
            ],
          ),
        if (!dynamic && fields.isEmpty)
          const TextLocale(LocaleKeys.workflow_editor_no_nested_fields),
      ],
    );
  }
}

class _ArrayWorkflowValueEditor extends StatelessWidget {
  const _ArrayWorkflowValueEditor({
    required this.field,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final WorkflowField field;
  final Object? value;
  final bool enabled;
  final ValueChanged<List<Object?>> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = value is List
        ? List<Object?>.from(value! as List)
        : <Object?>[];
    final itemField =
        field.items ??
        const WorkflowField(
          id: 'item',
          name: 'Item',
          type: .any,
          isRequired: false,
          nullable: true,
        );
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, item) in values.indexed)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        LocaleKeys.workflow_editor_array_item_number.tr(
                          context: context,
                          namedArgs: {'number': '${index + 1}'},
                        ),
                      ),
                    ),
                    AuraIconButton(
                      icon: Icons.close,
                      size: .small,
                      tooltip: LocaleKeys.workflow_editor_remove_item.tr(
                        context: context,
                      ),
                      semanticLabel: LocaleKeys.workflow_editor_remove_item.tr(
                        context: context,
                      ),
                      onPressed: enabled
                          ? () {
                              values.removeAt(index);
                              onChanged(values);
                            }
                          : null,
                    ),
                  ],
                ),
                WorkflowStaticValueEditor(
                  field: itemField,
                  value: item,
                  hasValue: true,
                  enabled: enabled,
                  onChanged: (value, hasValue) {
                    if (hasValue) {
                      values[index] = value;
                    } else {
                      values.removeAt(index);
                    }
                    onChanged(values);
                  },
                ),
              ],
            ),
          ),
        AuraButton(
          variant: .text,
          size: .small,
          disabled: !enabled,
          onPressed: enabled
              ? () => onChanged([...values, _emptyValueFor(itemField)])
              : () {},
          child: Row(
            mainAxisSize: .min,
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.workflow_editor_add_array_item.tr(context: context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowValueReference {
  const _WorkflowValueReference({
    required this.node,
    required this.field,
    required this.pointer,
    required this.label,
  });

  final WorkflowNode node;
  final WorkflowField field;
  final String pointer;
  final String label;
}

_WorkflowValueReference? _referenceFor(
  List<WorkflowNode> sources,
  String? nodeId,
  String? pointer,
) {
  if (nodeId == null || pointer == null) return null;
  final source = sources.where((node) => node.id == nodeId).firstOrNull;
  if (source == null) return null;
  final field = _fieldAt(source.outputFields, pointer);
  if (field == null) return null;
  final path = _fieldPath(source.outputFields, pointer);
  if (path.isEmpty) return null;
  return _WorkflowValueReference(
    node: source,
    field: field,
    pointer: pointer,
    label: '${source.label} · ${path.join(' · ')}',
  );
}

List<String> _fieldPath(List<WorkflowField> fields, String pointer) {
  if (!pointer.startsWith('/')) return const [];
  var currentFields = fields;
  WorkflowField? current;
  final path = <String>[];
  for (final raw in pointer.substring(1).split('/')) {
    final segment = _unescape(raw);
    if (current?.type == .array && segment == '0') {
      current = current!.items;
      if (current == null) return const [];
      path.add(current.name);
      currentFields = current.properties;
      continue;
    }
    current = currentFields.where((field) => field.name == segment).firstOrNull;
    if (current == null) return const [];
    path.add(current.name);
    currentFields = current.properties;
  }
  return path;
}

WorkflowField? _fieldAt(List<WorkflowField> fields, String pointer) {
  if (!pointer.startsWith('/')) return null;
  var currentFields = fields;
  WorkflowField? current;
  for (final raw in pointer.substring(1).split('/')) {
    final segment = _unescape(raw);
    if (current?.type == .array) {
      if (segment != '0') return null;
      current = current!.items;
      if (current == null) return null;
      currentFields = current.properties;
      continue;
    }
    current = currentFields.where((field) => field.name == segment).firstOrNull;
    if (current == null) return null;
    currentFields = current.properties;
  }
  return current;
}

bool _treeMatches(WorkflowField field, String query) =>
    query.isEmpty ||
    field.name.toLowerCase().contains(query) ||
    (field.type == .array
        ? field.items != null && _treeMatches(field.items!, query)
        : field.properties.any((child) => _treeMatches(child, query)));

bool _compatible(WorkflowField source, WorkflowField target) =>
    WorkflowGraphValidation.workflowFieldsCompatible(source, target);

WorkflowValueType? _valueType(Object? value) => switch (value) {
  String() => .string,
  int() => .integer,
  num() => .number,
  bool() => .boolean,
  Map() => .object,
  List() => .array,
  _ => null,
};

bool _matchesValueType(Object value, WorkflowValueType type) => switch (type) {
  .any => true,
  .string => value is String,
  .integer => value is int,
  .number => value is num,
  .boolean => value is bool,
  .object => value is Map,
  .array => value is List,
};

Object _emptyValueOfType(WorkflowValueType type) => switch (type) {
  .any || .string => '',
  .integer || .number => 0,
  .boolean => false,
  .object => <String, Object?>{},
  .array => <Object?>[],
};

Object? _emptyValueFor(WorkflowField field, {bool useDefault = true}) =>
    useDefault && field.hasDefaultValue
    ? field.defaultValue
    : _emptyValueOfType(field.type);

TextInputType? _keyboardType(WorkflowValueType type) => switch (type) {
  .integer || .number => const TextInputType.numberWithOptions(decimal: true),
  .string => TextInputType.text,
  _ => null,
};

String _escape(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1');

String _unescape(String value) =>
    value.replaceAll('~1', '/').replaceAll('~0', '~');
