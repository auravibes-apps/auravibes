import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A hub screen that groups all app management sections.
///
/// Provides navigation tiles for workspaces, model providers, and tools.
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
            icon: Icons.memory_outlined,
            titleKey: LocaleKeys.more_screen_models_title,
            subtitleKey: LocaleKeys.more_screen_models_subtitle,
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/models',
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
    return ListTile(
      leading: Icon(icon),
      title: TextLocale(titleKey),
      subtitle: TextLocale(subtitleKey),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
