// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _moreAppBar = AuraAppBarWithDrawer(
  title: TextLocale(LocaleKeys.more_screen_title),
);
const _moreTiles = [
  _MoreTileSpec(
    kind: .workspaces,
    icon: Icons.workspaces_outlined,
    titleKey: LocaleKeys.more_screen_workspaces_title,
    subtitleKey: LocaleKeys.more_screen_workspaces_subtitle,
  ),
  _MoreTileSpec(
    kind: .cloudAccounts,
    icon: Icons.manage_accounts_outlined,
    titleKey: LocaleKeys.cloud_accounts_title,
    subtitleKey: LocaleKeys.cloud_accounts_empty,
  ),
  _MoreTileSpec(
    kind: .serviceConnections,
    icon: Icons.hub_outlined,
    titleKey: LocaleKeys.more_screen_service_connections_title,
    subtitleKey: LocaleKeys.more_screen_service_connections_subtitle,
  ),
  _MoreTileSpec(
    kind: .credentialDefinitions,
    icon: Icons.key_outlined,
    titleKey: LocaleKeys.more_screen_credential_definitions_title,
    subtitleKey: LocaleKeys.more_screen_credential_definitions_subtitle,
  ),
  _MoreTileSpec(
    kind: .tools,
    icon: Icons.build_circle_outlined,
    titleKey: LocaleKeys.more_screen_tools_title,
    subtitleKey: LocaleKeys.more_screen_tools_subtitle,
  ),
  _MoreTileSpec(
    kind: .skills,
    icon: Icons.psychology_alt_outlined,
    titleKey: LocaleKeys.more_screen_skills_title,
    subtitleKey: LocaleKeys.more_screen_skills_subtitle,
  ),
  _MoreTileSpec(
    kind: .agents,
    icon: Icons.smart_toy_outlined,
    titleKey: LocaleKeys.more_screen_agents_title,
    subtitleKey: LocaleKeys.more_screen_agents_subtitle,
  ),
];

/// A hub screen that groups all app management sections.
///
/// Provides navigation tiles for workspaces, service connections, and tools.
class MoreScreen extends StatelessWidget {
  /// Creates a [MoreScreen].
  const new({required this.workspaceId, super.key});

  /// The current workspace ID from the route.
  final String workspaceId;

  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _MoreTileList(workspaceId: workspaceId),
    appBar: _moreAppBar,
  );
}

class const _MoreTileList({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraList(
    children: [
      for (final tile in _moreTiles)
        _MoreTile(spec: tile, workspaceId: workspaceId),
    ],
  );
}

enum _MoreTileKind {
  workspaces,
  cloudAccounts,
  serviceConnections,
  credentialDefinitions,
  tools,
  skills,
  agents,
}

class const _MoreTileSpec({
  required final _MoreTileKind kind,
  required final IconData icon,
  required final String titleKey,
  required final String subtitleKey,
}) {
  String location(String workspaceId) => switch (kind) {
    .workspaces => WorkspaceManagementRoute(workspaceId: workspaceId).location,
    .cloudAccounts => CloudAccountsRoute(workspaceId: workspaceId).location,
    .serviceConnections => '/workspaces/$workspaceId/more/service-connections',
    .credentialDefinitions =>
      '/workspaces/$workspaceId/more/skill-credential-definitions',
    .tools => '/workspaces/$workspaceId/more/tools',
    .skills => '/workspaces/$workspaceId/more/skills',
    .agents => '/workspaces/$workspaceId/more/agents',
  };
}

class const _MoreTile({
  required final _MoreTileSpec spec,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SectionTile(
    icon: spec.icon,
    titleKey: spec.titleKey,
    subtitleKey: spec.subtitleKey,
    onTap: () => context.push(spec.location(workspaceId)),
  );
}

class const _SectionTile({
  required final IconData icon,
  required final String titleKey,
  required final String subtitleKey,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: AuraColumn(
        children: [_SectionTileTitle(titleKey, subtitleKey)],
        spacing: .xs,
        crossAxisAlignment: .start,
      ),
      onTap: onTap,
      variant: .ghost,
      leading: AuraIcon(icon),
      trailing: const AuraIcon(Icons.chevron_right),
    );
  }
}

class const _SectionTileTitle(final String titleKey, final String subtitleKey)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      TextLocale(titleKey),
      AuraText(child: TextLocale(subtitleKey), style: .bodySmall),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}
