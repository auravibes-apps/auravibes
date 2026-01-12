import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        // Primary action - Start New Chat
        SizedBox(
          width: double.infinity,
          child: AuraButton(
            onPressed: () => NewChatRoute().go(context),
            child: const AuraRow(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline),
                TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
              ],
            ),
          ),
        ),

        // Secondary actions grid
        AuraRow(
          mainAxisAlignment: .end,
          children: [
            Expanded(
              child: AuraButton(
                variant: AuraButtonVariant.outlined,
                onPressed: () => ChatsRoute().go(context),
                child: const AuraColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuraIcon(Icons.history),
                    TextLocale(LocaleKeys.home_screen_actions_all_chats),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AuraButton(
                variant: AuraButtonVariant.outlined,
                onPressed: () => SettingsRoute().go(context),
                child: const AuraColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuraIcon(Icons.settings_outlined),
                    TextLocale(LocaleKeys.home_screen_actions_settings),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Tertiary actions row
        AuraRow(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.model_training_outlined,
                labelKey: LocaleKeys.home_screen_actions_models,
                onTap: () => ModelsRoute().go(context),
              ),
            ),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.tune_outlined,
                labelKey: LocaleKeys.home_screen_actions_tools,
                onTap: () => ToolsRoute().go(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.labelKey,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      onTap: onTap,
      child: AuraPadding(
        child: AuraColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuraIcon(
              icon,
            ),
            AuraText(
              style: AuraTextStyle.bodySmall,
              child: TextLocale(
                labelKey,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
