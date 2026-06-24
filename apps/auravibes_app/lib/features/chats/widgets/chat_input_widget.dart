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
    required this.modelControl,
    this.onSkillsPress,
    this.onContinueAgent,
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
  final VoidCallback? onContinueAgent;
  final Widget modelControl;
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
                modelControl,
                const AuraSizedBox(width: .xs),
                AuraPopupMenuButton(
                  items: [
                    AuraPopupMenuItem(
                      title: Text(LocaleKeys.menu_tools.tr()),
                      onTap: onToolsPress,
                      leading: const AuraIcon(Icons.build_circle_outlined),
                    ),
                    if (onSkillsPress case final onSkillsPress?)
                      AuraPopupMenuItem(
                        title: Text(LocaleKeys.skills_selector_title.tr()),
                        onTap: onSkillsPress,
                        leading: const AuraIcon(
                          Icons.psychology_alt_outlined,
                        ),
                      ),
                    if (onContinueAgent != null)
                      AuraPopupMenuItem(
                        title: Text(
                          LocaleKeys
                              .chats_screens_chat_conversation_continue_agent
                              .tr(),
                        ),
                        onTap: onContinueAgent,
                        leading: const AuraIcon(Icons.play_circle_outline),
                      ),
                    if (onCompact != null &&
                        !disabled &&
                        !isBusy &&
                        !isCompacting)
                      AuraPopupMenuItem(
                        title: Text(
                          LocaleKeys.compaction_manual_button_tooltip.tr(),
                        ),
                        onTap: onCompact,
                        leading: const AuraIcon(Icons.compress_outlined),
                      ),
                  ],
                  icon: Icons.tune_rounded,
                  tooltip: LocaleKeys
                      .chats_screens_chat_conversation_options_tooltip
                      .tr(),
                ),
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
                if (onStop case final onStop?) ...[
                  Visibility(
                    child: AuraTooltip(
                      message: LocaleKeys
                          .chats_screens_chat_conversation_stop_generation
                          .tr(),
                      child: AuraButton(
                        onPressed: onStop,
                        child: const AuraIcon(Icons.stop_rounded),
                        variant: AuraButtonVariant.outlined,
                        colorVariant: AuraColorVariant.error,
                        size: AuraButtonSize.small,
                      ),
                    ),
                    visible: isBusy,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                  ),
                  const AuraSizedBox(width: .xs),
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
