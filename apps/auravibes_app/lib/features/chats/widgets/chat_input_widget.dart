// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatInputWidget extends HookConsumerWidget {
  const ChatInputWidget({
    required this.onSendMessage,
    required this.onToolsPress,
    this.onSkillsPress,
    this.disabledHint,
    this.disabled = false,
    this.isBusy = false,
    this.onStop,
    this.onCompact,
    this.isCompacting = false,
    super.key,
  });

  final bool disabled;
  final bool isBusy;
  final void Function(String message) onSendMessage;
  final VoidCallback onToolsPress;
  final VoidCallback? onSkillsPress;
  final Widget? disabledHint;
  final VoidCallback? onStop;
  final VoidCallback? onCompact;
  final bool isCompacting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();

    final isEmpty = useListenableSelector(
      controller,
      () => controller.text.trim().isEmpty,
    );

    final sendMessage = useCallback(
      () {
        final message = controller.text.trim();
        onSendMessage(message);
        controller.clear();
      },
      [controller, onSendMessage, isEmpty],
    );

    final compact = onCompact;
    final stop = onStop;
    final stopButton = stop == null
        ? null
        : Tooltip(
            message: LocaleKeys.chats_screens_chat_conversation_stop_generation
                .tr(),
            child: AuraButton(
              onPressed: stop,
              child: const AuraIcon(Icons.stop_rounded),
              variant: AuraButtonVariant.outlined,
              colorVariant: AuraColorVariant.error,
              size: AuraButtonSize.small,
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: AuraInput(
        controller: controller,
        placeholder: const TextLocale(
          LocaleKeys.chats_screens_chat_conversation_message_placeholder,
        ),
        textInputAction: TextInputAction.send,
        maxLines: 2,
        onSubmitted: (value) {
          sendMessage.call();
        },
        footer: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: LocaleKeys.menu_tools.tr(),
                  child: AuraButton(
                    onPressed: onToolsPress,
                    child: const AuraIcon(Icons.build_circle_outlined),
                    variant: AuraButtonVariant.secondary,
                    size: AuraButtonSize.small,
                  ),
                ),
                if (onSkillsPress case final onSkillsPress?) ...[
                  const AuraSizedBox(width: AuraSpacing.xs),
                  Tooltip(
                    message: LocaleKeys.skills_selector_title.tr(),
                    child: AuraButton(
                      onPressed: onSkillsPress,
                      child: const AuraIcon(Icons.psychology_alt_outlined),
                      variant: AuraButtonVariant.secondary,
                      size: AuraButtonSize.small,
                    ),
                  ),
                ],
              ],
            ),

            if (disabledHint case final Widget disabledHint)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AuraText(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AuraIcon(
                          Icons.info_outline,
                          size: AuraIconSize.small,
                          color: AuraColorVariant.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: disabledHint),
                      ],
                    ),
                    style: AuraTextStyle.bodySmall,
                    color: AuraColorVariant.onSurfaceVariant,
                  ),
                ),
              )
            else
              const Spacer(),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (compact != null) ...[
                  Tooltip(
                    message: LocaleKeys.compaction_manual_button_tooltip.tr(),
                    child: AuraButton(
                      onPressed: compact,
                      child: isCompacting
                          ? const AuraSpinner(size: AuraSpinnerSize.small)
                          : const AuraIcon(Icons.compress_outlined),
                      variant: AuraButtonVariant.secondary,
                      size: AuraButtonSize.small,
                      disabled: disabled || isBusy || isCompacting,
                    ),
                  ),
                  const AuraSizedBox(width: AuraSpacing.xs),
                ],
                if (stopButton != null) ...[
                  Visibility(
                    child: stopButton,
                    visible: isBusy,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                  ),
                  const AuraSizedBox(width: AuraSpacing.xs),
                ],
                AuraButton(
                  onPressed: sendMessage,
                  child: const AuraIcon(Icons.arrow_upward),
                  size: AuraButtonSize.small,
                  disabled: isEmpty || disabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
