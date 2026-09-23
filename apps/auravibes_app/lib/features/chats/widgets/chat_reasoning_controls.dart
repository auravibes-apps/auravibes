import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class const ChatReasoningControls({
  required final List<ReasoningOption> options,
  required final ReasoningConfiguration? value,
  required final ValueChanged<ReasoningConfiguration?> onChanged,
  super.key,
}) extends StatefulWidget {
  static bool hasSupportedReasoningOptions(Iterable<ReasoningOption> options) =>
      options.any(
        (option) => option.isToggle || option.isEffort || option.isBudgetTokens,
      );

  @override
  State<ChatReasoningControls> createState() => _ChatReasoningControlsState();
}

class _ChatReasoningControlsState extends State<ChatReasoningControls> {
  final _budgetController = TextEditingController();
  final _editorFocusNode = FocusNode(debugLabel: 'Chat reasoning editor');
  ReasoningConfiguration? _configuration;
  bool _isEffortExpanded = false;
  String? _budgetError;

  @override
  void initState() {
    super.initState();
    _configuration = widget.value;
    _syncBudgetController(
      _validatedConfiguration(widget.options, _configuration),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatReasoningControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _configuration = widget.value;
    }
    final oldConfiguration = _validatedConfiguration(
      oldWidget.options,
      oldWidget.value,
    );
    final newConfiguration = _validatedConfiguration(
      widget.options,
      _configuration,
    );
    if (oldConfiguration?.budgetTokens != newConfiguration?.budgetTokens) {
      _syncBudgetController(newConfiguration);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ChatReasoningControls.hasSupportedReasoningOptions(widget.options)) {
      return const SizedBox.shrink();
    }

    return _buildReasoningEditor();
  }

  KeyEventResult _handleEditorKeyEvent(FocusNode node, KeyEvent event) {
    if (node == _editorFocusNode &&
        _isEffortExpanded &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _collapseEffortChoices();

      return .handled;
    }

    return .ignored;
  }

  void _toggleEffortChoices() {
    setState(() => _isEffortExpanded = !_isEffortExpanded);
    _editorFocusNode.requestFocus();
  }

  void _collapseEffortChoices() {
    setState(() => _isEffortExpanded = false);
    _editorFocusNode.requestFocus();
  }

  void _selectEffort(ReasoningConfiguration? configuration, String effort) {
    final updatedConfiguration = _copyConfiguration(
      configuration,
      effort: effort,
    );
    setState(() {
      _configuration = updatedConfiguration;
      _budgetError = null;
      _isEffortExpanded = false;
    });
    _editorFocusNode.requestFocus();
    widget.onChanged(updatedConfiguration);
  }

  void _setBudget(
    ReasoningConfiguration? configuration,
    ReasoningOption option,
    String value,
  ) {
    final parsed = _parseBudget(option, value);
    if (parsed == null) {
      setState(() => _budgetError = _budgetValidationMessage(option));

      return;
    }

    _changeConfiguration(
      _copyConfiguration(configuration, budgetTokens: parsed),
    );
  }

  void _changeConfiguration(ReasoningConfiguration? configuration) {
    setState(() {
      _configuration = configuration;
      _budgetError = null;
    });
    widget.onChanged(configuration);
  }
}

extension _ChatReasoningControlsEditor on _ChatReasoningControlsState {
  Widget _buildReasoningEditor() {
    final configuration = _validatedConfiguration(
      widget.options,
      _configuration,
    );

    return Focus(
      child: Semantics(
        child: AuraColumn(
          children: _reasoningSections(configuration),
          spacing: .sm,
          crossAxisAlignment: .stretch,
        ),
        container: true,
        explicitChildNodes: true,
        label: LocaleKeys.chats_screens_chat_conversation_reasoning_title.tr(),
      ),
      focusNode: _editorFocusNode,
      onKeyEvent: _handleEditorKeyEvent,
    );
  }

  List<Widget> _reasoningSections(ReasoningConfiguration? configuration) => [
    _ReasoningHeader(
      canReset: _configuration != null,
      onReset: () => _changeConfiguration(null),
    ),
    ..._toggleSection(configuration),
    ..._effortSection(configuration),
    ..._budgetSection(configuration),
  ];

  List<Widget> _toggleSection(ReasoningConfiguration? configuration) {
    if (_toggleOption(widget.options) == null) return const [];

    return [
      _ReasoningToggle(
        enabled: configuration?.enabled != false,
        onChanged: (enabled) => _changeConfiguration(
          _copyConfiguration(configuration, enabled: enabled),
        ),
      ),
    ];
  }

  List<Widget> _effortSection(ReasoningConfiguration? configuration) {
    final effort = _effortOption(widget.options);
    if (effort == null) return const [];

    return [_buildEffortSelector(effort, configuration)];
  }

  List<Widget> _budgetSection(ReasoningConfiguration? configuration) {
    final budget = _budgetOption(widget.options);
    if (budget == null) return const [];

    return [_buildBudgetInput(budget, configuration)];
  }

  void _syncBudgetController(ReasoningConfiguration? configuration) {
    final value = configuration?.budgetTokens;
    _budgetController.text = value?.toString() ?? '';
    _budgetError = null;
  }

  Widget _buildEffortSelector(
    ReasoningOption effort,
    ReasoningConfiguration? configuration,
  ) => _ReasoningEffortSelector(
    option: effort,
    value: configuration?.effort,
    enabled: configuration?.enabled != false,
    expanded: _isEffortExpanded,
    onToggle: _toggleEffortChoices,
    onChanged: (value) => _selectEffort(configuration, value),
  );

  Widget _buildBudgetInput(
    ReasoningOption budget,
    ReasoningConfiguration? configuration,
  ) => _ReasoningBudgetInput(
    option: budget,
    controller: _budgetController,
    error: _budgetError,
    enabled: configuration?.enabled != false,
    onChanged: (value) => _setBudget(configuration, budget, value),
  );
}

int? _parseBudget(ReasoningOption option, String value) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < (option.min ?? 0)) return null;
  final max = option.max;
  if (max != null && parsed > max) return null;

  return parsed;
}

String _budgetValidationMessage(ReasoningOption option) => LocaleKeys
    .chats_screens_chat_conversation_reasoning_budget_invalid
    .tr(namedArgs: {'min': '${option.min}', 'max': '${option.max}'});

class const _ReasoningHeader({
  required final bool canReset,
  required final VoidCallback onReset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      const Expanded(
        child: AuraText(
          child: TextLocale(
            LocaleKeys.chats_screens_chat_conversation_reasoning_title,
          ),
          style: .heading6,
        ),
      ),
      if (canReset)
        Semantics(
          key: const ValueKey<String>('chat_reasoning_reset'),
          child: AuraIconButton(
            icon: Icons.restore,
            onPressed: onReset,
            tooltip: LocaleKeys
                .chats_screens_chat_conversation_reasoning_restore_default
                .tr(),
          ),
          identifier: 'chat_reasoning_reset',
        ),
    ],
  );
}

class const _ReasoningToggle({
  required final bool enabled,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: AuraRow(
      children: [
        const Expanded(
          child: AuraText(
            child: TextLocale(
              LocaleKeys.chats_screens_chat_conversation_reasoning_enabled,
            ),
          ),
        ),
        AuraSwitch(
          value: enabled,
          onChanged: onChanged,
          semanticLabel: LocaleKeys
              .chats_screens_chat_conversation_reasoning_enabled
              .tr(),
        ),
      ],
    ),
    identifier: 'chat_reasoning_toggle',
  );
}

class const _ReasoningEffortSelector({
  required final ReasoningOption option,
  required final String? value,
  required final bool enabled,
  required final bool expanded,
  required final VoidCallback onToggle,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedLabel =
        value ??
        LocaleKeys.chats_screens_chat_conversation_reasoning_effort_default
            .tr();

    return AuraColumn(
      children: [
        _ReasoningEffortDisclosure(
          enabled: enabled,
          expanded: expanded,
          selectedLabel: selectedLabel,
          onToggle: onToggle,
        ),
        if (expanded)
          _ReasoningEffortChoices(
            values: option.values,
            value: value,
            enabled: enabled,
            onChanged: onChanged,
          ),
      ],
      spacing: .xs,
      crossAxisAlignment: .stretch,
    );
  }
}

class const _ReasoningEffortDisclosure({
  required final bool enabled,
  required final bool expanded,
  required final String selectedLabel,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final effortLabel = LocaleKeys
        .chats_screens_chat_conversation_reasoning_effort
        .tr();

    return Semantics(
      key: const ValueKey<String>('chat_reasoning_effort_disclosure'),
      child: _ReasoningEffortDisclosureButton(
        enabled: enabled,
        expanded: expanded,
        selectedLabel: selectedLabel,
        effortLabel: effortLabel,
        onToggle: onToggle,
      ),
      button: true,
      expanded: expanded,
      identifier: 'chat_reasoning_effort_disclosure',
      label: effortLabel,
      value: selectedLabel,
    );
  }
}

class const _ReasoningEffortDisclosureButton({
  required final bool enabled,
  required final bool expanded,
  required final String selectedLabel,
  required final String effortLabel,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onToggle,
    child: _ReasoningEffortDisclosureContent(
      expanded: expanded,
      selectedLabel: selectedLabel,
    ),
    variant: .ghost,
    size: .small,
    isFullWidth: true,
    disabled: !enabled,
    semanticLabel: '$effortLabel: $selectedLabel',
  );
}

class const _ReasoningEffortDisclosureContent({
  required final bool expanded,
  required final String selectedLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: TextLocale(
          LocaleKeys.chats_screens_chat_conversation_reasoning_effort,
        ),
      ),
      Text(selectedLabel),
      AuraIcon(expanded ? Icons.expand_less : Icons.expand_more, size: .small),
    ],
  );
}

class const _ReasoningEffortChoices({
  required final List<String> values,
  required final String? value,
  required final bool enabled,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('chat_reasoning_effort_choices'),
    child: AuraRadioGroup<String>(
      value: value,
      onChanged: enabled ? _handleSelection : null,
      options: _effortOptions(),
    ),
    identifier: 'chat_reasoning_effort_choices',
  );

  void _handleSelection(String? selected) {
    if (selected != null) onChanged(selected);
  }

  List<AuraRadioOption<String>> _effortOptions() => [
    for (final effort in values)
      AuraRadioOption(
        value: effort,
        label: Text(
          effort,
          key: ValueKey<String>('chat_reasoning_effort_choice_$effort'),
        ),
        semanticLabel: effort,
      ),
  ];
}

class const _ReasoningBudgetInput({
  required final ReasoningOption option,
  required final TextEditingController controller,
  required final String? error,
  required final bool enabled,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  static const _label = TextLocale(
    LocaleKeys.chats_screens_chat_conversation_reasoning_budget_tokens,
  );

  @override
  Widget build(BuildContext context) => AuraInput(
      controller: controller,
      label: _label,
      hint: _hint,
      error: _error,
      keyboardType: .number,
      enabled: enabled,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      semanticLabel: _semanticLabel(),
    );

  Widget get _hint => Text(
    LocaleKeys.chats_screens_chat_conversation_reasoning_budget_hint.tr(
      namedArgs: {'min': '${option.min}', 'max': '${option.max}'},
    ),
  );

  Widget? get _error => switch (error) {
    final message? => Text(message),
    null => null,
  };

  String _semanticLabel() =>
      LocaleKeys.chats_screens_chat_conversation_reasoning_budget_tokens.tr();
}

ReasoningConfiguration? _validatedConfiguration(
  List<ReasoningOption> options,
  ReasoningConfiguration? value,
) => value?.isValidFor(options) == true ? value : null;

ReasoningConfiguration? _copyConfiguration(
  ReasoningConfiguration? configuration, {
  bool? enabled,
  String? effort,
  int? budgetTokens,
}) => ReasoningConfiguration(
  enabled: enabled ?? configuration?.enabled,
  effort: effort ?? configuration?.effort,
  budgetTokens: budgetTokens ?? configuration?.budgetTokens,
);

ReasoningOption? _toggleOption(Iterable<ReasoningOption> options) =>
    options.where((option) => option.isToggle).firstOrNull;

ReasoningOption? _effortOption(Iterable<ReasoningOption> options) =>
    options.where((option) => option.isEffort).firstOrNull;

ReasoningOption? _budgetOption(Iterable<ReasoningOption> options) =>
    options.where((option) => option.isBudgetTokens).firstOrNull;
