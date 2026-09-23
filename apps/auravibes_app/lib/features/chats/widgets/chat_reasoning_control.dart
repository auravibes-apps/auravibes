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
    if (!hasSupportedReasoningOptions(widget.options)) {
      return const SizedBox.shrink();
    }

    final trigger = _ReasoningTrigger(
      options: widget.options,
      value: widget.value,
      onPressed: _isNarrowLayout(context)
          ? () => _showReasoningSheet(context)
          : _popupController.toggle,
    );

    if (_isNarrowLayout(context)) return trigger;

    return AuraPopupMenu(
      child: trigger,
      items: [
        _ReasoningPopupEntry(
          child: ChatReasoningControls(
            options: widget.options,
            value: widget.value,
            onChanged: widget.onChanged,
          ),
        ),
      ],
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
  required final List<ReasoningOption> options,
  required final ReasoningConfiguration? value,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summary = _ReasoningTrigger._reasoningSummary(options, value);

    return Semantics(
      key: const ValueKey<String>('chat_reasoning_selector'),
      child: AuraTooltip(
        message: LocaleKeys
            .chats_screens_chat_conversation_reasoning_options_tooltip
            .tr(),
        child: AuraButton(
          onPressed: onPressed,
          child: Row(
            mainAxisSize: .min,
            children: [
              const AuraIcon(Icons.psychology_outlined, size: .small),
              if (summary.label case final label?) ...[
                const AuraSizedBox(width: .xs),
                Text(label, overflow: .ellipsis, maxLines: 1),
              ],
            ],
          ),
          variant: .ghost,
          size: .small,
          semanticLabel: summary.semanticLabel,
        ),
      ),
      button: true,
      identifier: 'chat_reasoning_selector',
      label: summary.semanticLabel,
    );
  }

  static _ReasoningSummary _reasoningSummary(
    List<ReasoningOption> options,
    ReasoningConfiguration? value,
  ) {
    final configuration = _validatedTriggerConfiguration(options, value);
    final label = switch (configuration) {
      ReasoningConfiguration(enabled: false) =>
        LocaleKeys.chats_screens_chat_conversation_reasoning_status_off.tr(),
      ReasoningConfiguration(effort: String(), budgetTokens: int()) =>
        LocaleKeys.chats_screens_chat_conversation_reasoning_status_custom.tr(),
      ReasoningConfiguration(effort: final effort?) => effort,
      ReasoningConfiguration(budgetTokens: final budget?) => '$budget',
      _ => null,
    };
    final status =
        label ??
        LocaleKeys.chats_screens_chat_conversation_reasoning_status_default
            .tr();

    return (
      label: label,
      semanticLabel: LocaleKeys
          .chats_screens_chat_conversation_reasoning_trigger_label
          .tr(namedArgs: {'status': status}),
    );
  }
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

bool hasSupportedReasoningOptions(Iterable<ReasoningOption> options) =>
    options.any(
      (option) => option.isToggle || option.isEffort || option.isBudgetTokens,
    );
