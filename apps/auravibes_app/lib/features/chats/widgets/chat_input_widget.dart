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
    this.showStopButton,
    this.onStop,
    this.onCompact,
    this.isCompacting = false,
    super.key,
  });

  final bool disabled;
  final bool isBusy;
  final bool? showStopButton;
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
    final focusNode = useFocusNode();

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

    final shouldShowStopButton = showStopButton ?? isBusy;
    const continueAgentKey =
        LocaleKeys.chats_screens_chat_conversation_continue_agent;
    const stopGenerationKey =
        LocaleKeys.chats_screens_chat_conversation_stop_generation;

    return TextFieldTapRegion(
      child: GestureDetector(
        child: SafeArea(
          top: false,
          child: Padding(
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
              onTapOutside: (_) => focusNode.unfocus(),
              focusNode: focusNode,
              footer: GestureDetector(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (disabledHint case final Widget disabledHint) ...[
                        AuraText(
                          child: Row(
                            children: [
                              const AuraIcon(
                                Icons.info_outline,
                                size: AuraIconSize.small,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: disabledHint),
                            ],
                          ),
                          style: AuraTextStyle.bodySmall,
                        ),
                        const AuraSizedBox(height: .xs),
                      ],
                      Row(
                        children: [
                          Flexible(child: modelControl),
                          const AuraSizedBox(width: .xs),
                          AuraPopupMenuButton(
                            items: [
                              AuraPopupMenuItem(
                                title: const TextLocale(LocaleKeys.menu_tools),
                                onTap: onToolsPress,
                                leading: const AuraIcon(
                                  Icons.build_circle_outlined,
                                ),
                              ),
                              if (onSkillsPress case final onSkillsPress?)
                                AuraPopupMenuItem(
                                  title: const TextLocale(
                                    LocaleKeys.skills_selector_title,
                                  ),
                                  onTap: onSkillsPress,
                                  leading: const AuraIcon(
                                    Icons.psychology_alt_outlined,
                                  ),
                                ),
                              if (onContinueAgent != null)
                                AuraPopupMenuItem(
                                  title: const TextLocale(
                                    continueAgentKey,
                                  ),
                                  onTap: onContinueAgent,
                                  leading: const AuraIcon(
                                    Icons.play_circle_outline,
                                  ),
                                ),
                              if (onCompact != null &&
                                  !disabled &&
                                  !isBusy &&
                                  !isCompacting)
                                AuraPopupMenuItem(
                                  title: const TextLocale(
                                    LocaleKeys.compaction_manual_button_tooltip,
                                  ),
                                  onTap: onCompact,
                                  leading: const AuraIcon(
                                    Icons.compress_outlined,
                                  ),
                                ),
                            ],
                            icon: Icons.tune_rounded,
                            tooltip: LocaleKeys
                                .chats_screens_chat_conversation_options_tooltip
                                .tr(),
                          ),
                          const Spacer(),
                          if (onStop case final onStop?) ...[
                            Visibility(
                              child: AuraTooltip(
                                message: stopGenerationKey.tr(),
                                child: AuraButton(
                                  onPressed: onStop,
                                  child: const AuraIcon(Icons.stop_rounded),
                                  variant: AuraButtonVariant.outlined,
                                  tint: AuraTint.error,
                                  size: AuraButtonSize.small,
                                ),
                              ),
                              visible: shouldShowStopButton,
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
                onTap: () => focusNode.hasFocus,
                behavior: HitTestBehavior.opaque,
              ),
            ),
          ),
        ),
        onTap: focusNode.requestFocus,
        behavior: HitTestBehavior.translucent,
      ),
    );
  }
}
