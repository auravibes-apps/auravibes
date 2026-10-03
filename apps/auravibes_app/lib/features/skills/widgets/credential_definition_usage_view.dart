import 'dart:async';

import 'package:auravibes_app/domain/models/credential_definition_usage.dart';
import 'package:auravibes_app/domain/models/credential_dependency.dart';
import 'package:auravibes_app/features/skills/providers/credential_definition_usage_provider.dart';
import 'package:auravibes_app/features/skills/usecases/credential_definition_schema.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _UsageGroupData = ({
  List<CredentialDependency> dependencies,
  String kind,
  Future<void> Function(CredentialDependency) open,
});

class const CredentialDefinitionUsageView({
  required final String workspaceId,
  required final String definitionId,
  required final List<CredentialSchemaChange> changes,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = credentialDefinitionUsageProvider(
      workspaceId,
      definitionId,
    );

    return AuraCard(
      child: AuraColumn(
        children: [
          const TextLocale('credential_usage.title'),
          _UsageState(
            workspaceId: workspaceId,
            usage: ref.watch(provider),
            refresh: () => ref.invalidate(provider),
          ),
          if (changes.isNotEmpty) _SchemaChanges(changes: changes),
          const TextLocale('credential_usage.advisory'),
        ],
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _UsageState({
  required final String workspaceId,
  required final AsyncValue<CredentialDefinitionUsage> usage,
  required final VoidCallback refresh,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (usage) {
    AsyncData(:final value) => _UsageData(
      workspaceId: workspaceId,
      usage: value,
      refresh: refresh,
    ),
    AsyncError() => AuraColumn(
      children: [
        const TextLocale('credential_usage.error'),
        AuraButton(
          onPressed: refresh,
          child: const TextLocale('route_state.retry'),
        ),
      ],
    ),
    AsyncLoading() => const AuraSpinner(),
  };
}

class const _SchemaChanges({
  required final List<CredentialSchemaChange> changes,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale('credential_usage.changes'),
      for (final change in changes)
        Text(
          'credential_usage.${change.kind.name}'.tr(
            namedArgs: {'field': change.variable},
          ),
        ),
      const TextLocale('credential_usage.impact'),
    ],
    crossAxisAlignment: .start,
  );
}

class const _UsageSummary({required final CredentialDefinitionUsage usage})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Text(
        'credential_usage.counts'.tr(
          namedArgs: {
            'credentials': '${usage.credentials.length}',
            'skills': '${usage.skills.length}',
            'tools': '${usage.tools.length}',
          },
        ),
      ),
      TextLocale(
        usage.isEmpty
            ? 'credential_usage.empty'
            : 'credential_usage.delete_blocked',
      ),
    ],
    crossAxisAlignment: .start,
  );
}

class const _UsageData({
  required final String workspaceId,
  required final CredentialDefinitionUsage usage,
  required final VoidCallback refresh,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _UsageSummary(usage: usage),
      for (final group in _groups(context))
        _UsageGroup(
          dependencies: group.dependencies,
          kind: group.kind,
          open: group.open,
        ),
    ],
    crossAxisAlignment: .start,
  );

  List<_UsageGroupData> _groups(BuildContext context) => [
    (
      dependencies: usage.credentials,
      kind: 'credential',
      open: (item) => _openCredential(context, item),
    ),
    (
      dependencies: usage.skills,
      kind: 'skill',
      open: (item) => _openSkill(context, item),
    ),
    (
      dependencies: usage.tools,
      kind: 'tool',
      open: (item) => _openTool(context, item),
    ),
  ];

  Future<void> _openCredential(
    BuildContext context,
    CredentialDependency item,
  ) async {
    await ServiceConnectionEditRoute(
      workspaceId: workspaceId,
      connectionId: item.id,
    ).push<void>(context);
    if (context.mounted) refresh();
  }

  Future<void> _openSkill(
    BuildContext context,
    CredentialDependency item,
  ) async {
    await SkillDetailRoute(
      workspaceId: workspaceId,
      skillId: item.id,
    ).push<void>(context);
    if (context.mounted) refresh();
  }

  Future<void> _openTool(
    BuildContext context,
    CredentialDependency item,
  ) async {
    final parent = item.parentSkillId;
    if (parent == null) return;
    await SkillToolEditRoute(
      workspaceId: workspaceId,
      skillId: parent,
      toolId: item.id,
    ).push<void>(context);
    if (context.mounted) refresh();
  }
}

class const _UsageGroup({
  required final List<CredentialDependency> dependencies,
  required final String kind,
  required final Future<void> Function(CredentialDependency) open,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final dependency in dependencies)
        _UsageLink(
          dependency: dependency,
          kind: kind,
          open: () => open(dependency),
        ),
    ],
    crossAxisAlignment: .start,
  );
}

class const _UsageLink({
  required final CredentialDependency dependency,
  required final String kind,
  required final Future<void> Function() open,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(open()),
    child: AuraRow(
      children: [
        Text(dependency.title),
        Text('credential_usage.$kind'.tr()),
        if (!dependency.isEnabled)
          const TextLocale('credential_usage.disabled'),
      ],
    ),
  );
}
