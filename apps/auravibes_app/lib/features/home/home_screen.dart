import 'package:auravibes_app/features/home/widgets/quick_actions_widget.dart';
import 'package:auravibes_app/features/home/widgets/recent_conversations_widget.dart';
import 'package:auravibes_app/features/home/widgets/status_bar_widget.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AuraScreen(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with welcome message and status
            AuraPadding(
              child: AuraColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(
                    style: AuraTextStyle.heading2,
                    child: TextLocale(
                      LocaleKeys.home_screen_welcome_title,
                    ),
                  ),
                  AuraText(
                    style: AuraTextStyle.bodyLarge,
                    color: AuraColorVariant.onSurfaceVariant,
                    child: TextLocale(
                      LocaleKeys.home_screen_welcome_subtitle,
                    ),
                  ),
                  StatusBarWidget(),
                ],
              ),
            ),

            AuraDivider(),

            // Main content area
            Expanded(
              child: SingleChildScrollView(
                child: AuraPadding(
                  child: AuraColumn(
                    spacing: .lg,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick actions section
                      AuraText(
                        style: AuraTextStyle.heading4,
                        child: TextLocale(
                          LocaleKeys.home_screen_quick_actions,
                        ),
                      ),
                      QuickActionsWidget(),

                      // Recent conversations section
                      AuraText(
                        style: AuraTextStyle.heading4,
                        child: TextLocale(
                          LocaleKeys.home_screen_recent_conversations,
                        ),
                      ),
                      RecentConversationsWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
