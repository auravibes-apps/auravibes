// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A hub screen that groups all app management sections.
///
/// Provides navigation tiles for workspaces, service connections, and tools.
class MoreScreen extends StatelessWidget {
  /// Creates a [MoreScreen].
  const MoreScreen({required this.workspaceId, super.key});

  /// The current workspace ID from the route.
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: ListView(
        children: [
          _SectionTile(
            icon: Icons.workspaces_outlined,
            titleKey: LocaleKeys.more_screen_workspaces_title,
            subtitleKey: LocaleKeys.more_screen_workspaces_subtitle,
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/manage-workspaces',
            ),
          ),
          _SectionTile(
            icon: Icons.hub_outlined,
            titleKey: LocaleKeys.more_screen_service_connections_title,
            subtitleKey: LocaleKeys.more_screen_service_connections_subtitle,
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/service-connections',
            ),
          ),
          _SectionTile(
            icon: Icons.key_outlined,
            titleKey: LocaleKeys.more_screen_credential_definitions_title,
            subtitleKey: LocaleKeys.more_screen_credential_definitions_subtitle,
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/skill-credential-definitions',
            ),
          ),
          _SectionTile(
            icon: Icons.build_circle_outlined,
            titleKey: LocaleKeys.more_screen_tools_title,
            subtitleKey: LocaleKeys.more_screen_tools_subtitle,
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/tools',
            ),
          ),
          _SectionTile(
            icon: Icons.psychology_alt_outlined,
            titleKey: LocaleKeys.more_screen_skills_title,
            subtitleKey: LocaleKeys.more_screen_skills_subtitle,
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/skills',
            ),
          ),
        ],
      ),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.more_screen_title),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.onTap,
  });

  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: AuraColumn(
        children: [
          TextLocale(titleKey),
          AuraText(
            child: TextLocale(subtitleKey),
            style: AuraTextStyle.bodySmall,
          ),
        ],
        spacing: .xs,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      onTap: onTap,
      variant: AuraTileVariant.ghost,
      leading: AuraIcon(icon),
      trailing: const AuraIcon(Icons.chevron_right),
    );
  }
}
