import 'package:auravibes_app/features/chats/widgets/chat_reasoning_controls.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const ChatReasoningControl({
  required final List<ReasoningOption> options,
  required final ReasoningConfiguration? value,
  required final ValueChanged<ReasoningConfiguration?> onChanged,
  super.key,
}) extends StatefulWidget {
  @override
  State<ChatReasoningControl> createState() => _ChatReasoningControlState();
}

class _ChatReasoningControlState extends State<ChatReasoningControl> {
  final _popupController = AuraPopupMenuController();

  @override
  Widget build(BuildContext context) {
    if (!ChatReasoningControls.hasSupportedReasoningOptions(widget.options)) {
      return const SizedBox.shrink();
    }

    final trigger = _ReasoningTrigger(
      summary: _ReasoningTrigger._reasoningSummary(
        widget.options,
        widget.value,
      ),
      onPressed: _isNarrowLayout(context)
          ? () => _showReasoningSheet(context)
          : _popupController.toggle,
    );

    if (_isNarrowLayout(context)) return trigger;

    return _ReasoningPopup(
      trigger: trigger,
      child: ChatReasoningControls(
        options: widget.options,
        value: widget.value,
        onChanged: widget.onChanged,
      ),
      controller: _popupController,
    );
  }

  bool _isNarrowLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width < DesignBreakpoints.sm;

  Future<void> _showReasoningSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => _ReasoningSheet(
          child: ChatReasoningControls(
            options: widget.options,
            value: widget.value,
            onChanged: widget.onChanged,
          ),
        ),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useSafeArea: true,
      );
}

class const _ReasoningTrigger({
  required final _ReasoningSummary summary,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('chat_reasoning_selector'),
    child: _ReasoningTriggerButton(
      summary: summary,
      onPressed: onPressed,
      tooltip: LocaleKeys
          .chats_screens_chat_conversation_reasoning_options_tooltip
          .tr(),
    ),
    button: true,
    identifier: 'chat_reasoning_selector',
    label: summary.semanticLabel,
  );

  static _ReasoningSummary _reasoningSummary(
    List<ReasoningOption> options,
    ReasoningConfiguration? value,
  ) {
    final label = _reasoningSummaryLabel(
      _validatedTriggerConfiguration(options, value),
    );
    final status = label ?? _defaultReasoningLabel();

    return (label: label, semanticLabel: _reasoningAccessibilityLabel(status));
  }

  static String? _reasoningSummaryLabel(
    ReasoningConfiguration? configuration,
  ) => switch (configuration) {
    ReasoningConfiguration(enabled: false) =>
      LocaleKeys.chats_screens_chat_conversation_reasoning_status_off.tr(),
    ReasoningConfiguration(effort: String(), budgetTokens: int()) =>
      LocaleKeys.chats_screens_chat_conversation_reasoning_status_custom.tr(),
    ReasoningConfiguration(effort: final effort?) => effort,
    ReasoningConfiguration(budgetTokens: final budget?) => '$budget',
    _ => null,
  };

  static String _defaultReasoningLabel() =>
      LocaleKeys.chats_screens_chat_conversation_reasoning_status_default.tr();

  static String _reasoningAccessibilityLabel(String status) => LocaleKeys
      .chats_screens_chat_conversation_reasoning_trigger_label
      .tr(namedArgs: {'status': status});
}

class const _ReasoningTriggerButton({
  required final _ReasoningSummary summary,
  required final VoidCallback onPressed,
  required final String tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTooltip(
    message: tooltip,
    child: AuraButton(
      onPressed: onPressed,
      child: _ReasoningTriggerContent(label: summary.label),
      variant: .ghost,
      size: .small,
      semanticLabel: summary.semanticLabel,
    ),
  );
}

class const _ReasoningTriggerContent({required final String? label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      const AuraIcon(Icons.psychology_outlined, size: .small),
      if (label case final value?) ...[
        const AuraSizedBox(width: .xs),
        Text(value, overflow: .ellipsis, maxLines: 1),
      ],
    ],
  );
}

class const _ReasoningPopupEntry({required final Widget child})
    extends AuraPopupMenuEntry {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: ConstrainedBox(
      constraints: .new(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
        child: child,
      ),
    ),
  );
}

class const _ReasoningPopup({
  required final Widget trigger,
  required final Widget child,
  required final AuraPopupMenuController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPopupMenu(
    child: trigger,
    items: [_ReasoningPopupEntry(child: child)],
    controller: controller,
  );
}

class const _ReasoningSheet({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: AuraCard(
        child: ConstrainedBox(
          constraints: .new(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}

typedef _ReasoningSummary = ({String? label, String semanticLabel});

ReasoningConfiguration? _validatedTriggerConfiguration(
  List<ReasoningOption> options,
  ReasoningConfiguration? value,
) => value?.isValidFor(options) == true ? value : null;
