import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
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
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.more_screen_title),
      ),
      child: ListView(
        children: [
          _SectionTile(
            icon: Icons.workspaces_outlined,
            title: LocaleKeys.more_screen_workspaces_title.tr(),
            subtitle: LocaleKeys.more_screen_workspaces_subtitle.tr(),
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/manage-workspaces',
            ),
          ),
          _SectionTile(
            icon: Icons.memory_outlined,
            title: LocaleKeys.more_screen_models_title.tr(),
            subtitle: LocaleKeys.more_screen_models_subtitle.tr(),
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/models',
            ),
          ),
          _SectionTile(
            icon: Icons.build_circle_outlined,
            title: LocaleKeys.more_screen_tools_title.tr(),
            subtitle: LocaleKeys.more_screen_tools_subtitle.tr(),
            onTap: () => context.push(
              '/workspaces/$workspaceId/more/tools',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
