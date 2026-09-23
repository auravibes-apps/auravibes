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
    final toggle = _toggleOption(widget.options);
    final effort = _effortOption(widget.options);
    final budget = _budgetOption(widget.options);
    if (toggle == null && effort == null && budget == null) {
      return const SizedBox.shrink();
    }

    final configuration = _validatedConfiguration(
      widget.options,
      _configuration,
    );

    return _buildReasoningEditor(toggle, effort, budget, configuration);
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
    final parsed = int.tryParse(value);
    final isValid =
        parsed != null &&
        parsed >= (option.min ?? 0) &&
        parsed <= (option.max ?? parsed);
    setState(() {
      _budgetError = isValid ? null : _budgetValidationMessage(option);
    });
    if (isValid) {
      _changeConfiguration(
        _copyConfiguration(configuration, budgetTokens: parsed),
      );
    }
  }

  void _changeConfiguration(ReasoningConfiguration? configuration) {
    setState(() {
      _configuration = configuration;
      _budgetError = null;
    });
    widget.onChanged(configuration);
  }

  void _syncBudgetController(ReasoningConfiguration? configuration) {
    final value = configuration?.budgetTokens;
    _budgetController.text = value?.toString() ?? '';
    _budgetError = null;
  }

  String _budgetValidationMessage(ReasoningOption option) => LocaleKeys
      .chats_screens_chat_conversation_reasoning_budget_invalid
      .tr(namedArgs: {'min': '${option.min}', 'max': '${option.max}'});
}

extension _ChatReasoningControlsEditor on _ChatReasoningControlsState {
  Widget _buildReasoningEditor(
    ReasoningOption? toggle,
    ReasoningOption? effort,
    ReasoningOption? budget,
    ReasoningConfiguration? configuration,
  ) => Focus(
    child: Semantics(
      child: AuraColumn(
        children: [
          _ReasoningHeader(
            canReset: _configuration != null,
            onReset: () => _changeConfiguration(null),
          ),
          if (toggle != null)
            _ReasoningToggle(
              enabled: configuration?.enabled != false,
              onChanged: (enabled) => _changeConfiguration(
                _copyConfiguration(configuration, enabled: enabled),
              ),
            ),
          if (effort != null) _buildEffortSelector(effort, configuration),
          if (budget != null) _buildBudgetInput(budget, configuration),
        ],
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
  Widget build(BuildContext context) => AuraColumn(
    children: [_buildDisclosure(), if (expanded) _buildChoices()],
    spacing: .xs,
    crossAxisAlignment: .stretch,
  );

  Widget _buildDisclosure() {
    final effortLabel = LocaleKeys
        .chats_screens_chat_conversation_reasoning_effort
        .tr();
    final selectedLabel =
        value ??
        LocaleKeys.chats_screens_chat_conversation_reasoning_effort_default
            .tr();

    return Semantics(
      key: const ValueKey<String>('chat_reasoning_effort_disclosure'),
      child: AuraButton(
        onPressed: onToggle,
        child: Row(
          children: [
            const Expanded(
              child: TextLocale(
                LocaleKeys.chats_screens_chat_conversation_reasoning_effort,
              ),
            ),
            Text(selectedLabel),
            AuraIcon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: .small,
            ),
          ],
        ),
        variant: .ghost,
        size: .small,
        isFullWidth: true,
        disabled: !enabled,
        semanticLabel: '$effortLabel: $selectedLabel',
      ),
      button: true,
      expanded: expanded,
      identifier: 'chat_reasoning_effort_disclosure',
      label: effortLabel,
      value: selectedLabel,
    );
  }

  Widget _buildChoices() => Semantics(
    key: const ValueKey<String>('chat_reasoning_effort_choices'),
    child: AuraRadioGroup<String>(
      value: value,
      onChanged: enabled
          ? (selected) {
              if (selected != null) onChanged(selected);
            }
          : null,
      options: [
        for (final effort in option.values)
          AuraRadioOption(
            value: effort,
            label: Text(
              effort,
              key: ValueKey<String>('chat_reasoning_effort_choice_$effort'),
            ),
            semanticLabel: effort,
          ),
      ],
    ),
    identifier: 'chat_reasoning_effort_choices',
  );
}

class const _ReasoningBudgetInput({
  required final ReasoningOption option,
  required final TextEditingController controller,
  required final String? error,
  required final bool enabled,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_reasoning_budget_tokens,
    ),
    hint: Text(
      LocaleKeys.chats_screens_chat_conversation_reasoning_budget_hint.tr(
        namedArgs: {'min': '${option.min}', 'max': '${option.max}'},
      ),
    ),
    error: _errorWidget(error),
    keyboardType: .number,
    enabled: enabled,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: onChanged,
    semanticLabel: LocaleKeys
        .chats_screens_chat_conversation_reasoning_budget_tokens
        .tr(),
  );

  Widget? _errorWidget(String? value) => value == null ? null : Text(value);
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
