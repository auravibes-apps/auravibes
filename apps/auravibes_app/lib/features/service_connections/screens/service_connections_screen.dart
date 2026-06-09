// ignore_for_file: prefer-single-widget-per-file
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('service_connections_screen');

class ServiceConnectionsScreen extends ConsumerWidget {
  const ServiceConnectionsScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(serviceConnectionsProvider(workspaceId));

    return AuraScreen(
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.service_connections_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          AuraIconButton(
            icon: Icons.add,
            onPressed: () async {
              await context.push<bool>(
                '/workspaces/$workspaceId/more/service-connections/new',
              );
            },
            tooltip: LocaleKeys.service_connections_add.tr(context: context),
          ),
        ],
      ),
      child: switch (connectionsAsync) {
        AsyncData(:final value) => _ConnectionsList(connections: value),
        AsyncLoading(:final value, hasValue: true) => _ConnectionsList(
          connections: value!,
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => const Center(
          child: AuraText(
            child: TextLocale(LocaleKeys.service_connections_load_error),
            color: AuraColorVariant.error,
          ),
        ),
      },
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  const _ConnectionsList({required this.connections});

  final List<ServiceConnectionListItem> connections;

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) {
      return const Center(
        child: AuraColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuraIcon(
              Icons.hub_outlined,
              size: AuraIconSize.extraLarge,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            AuraText(
              child: TextLocale(LocaleKeys.service_connections_empty_title),
              style: AuraTextStyle.heading3,
            ),
            AuraText(
              child: TextLocale(LocaleKeys.service_connections_empty_subtitle),
              textAlign: TextAlign.center,
              color: AuraColorVariant.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        return _ConnectionTile(connection: connections[index]);
      },
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: connections.length,
    );
  }
}

class _ConnectionTile extends ConsumerWidget {
  const _ConnectionTile({required this.connection});

  final ServiceConnectionListItem connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuController = AuraPopupMenuController();
    return AuraCard(
      child: AuraTile(
        variant: AuraTileVariant.ghost,
        leading: AuraIcon(_icon),
        trailing: AuraPopupMenu(
          child: AuraIconButton(
            icon: Icons.more_vert,
            onPressed: menuController.toggle,
          ),
          items: [
            AuraPopupMenuItem(
              title: const TextLocale(LocaleKeys.common_edit),
              onTap: () => context.push<bool>(
                '/workspaces/${connection.workspaceId}/more/'
                'service-connections/${connection.id}',
              ),
              leading: const AuraIcon(Icons.edit_outlined),
            ),
            if (connection.kind ==
                ServiceConnectionListItemKind.skillCredential)
              AuraPopupMenuItem(
                title: const TextLocale(LocaleKeys.common_delete),
                onTap: () => _confirmDeleteCredential(context, ref),
                leading: const AuraIcon(Icons.delete_outline),
                variant: AuraTileVariant.error,
              ),
          ],
          controller: menuController,
        ),
        child: AuraColumn(
          spacing: AuraSpacing.xs,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuraText(
              child: Text(connection.name),
              style: AuraTextStyle.heading6,
            ),
            AuraText(
              child: Text(_subtitle(context)),
              color: AuraColorVariant.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    return switch (connection.kind) {
      ServiceConnectionListItemKind.modelProvider => Icons.memory_outlined,
      ServiceConnectionListItemKind.skillCredential => Icons.key_outlined,
    };
  }

  String _subtitle(BuildContext context) {
    final kind = switch (connection.kind) {
      ServiceConnectionListItemKind.modelProvider =>
        LocaleKeys.service_connections_type_model_provider.tr(context: context),
      ServiceConnectionListItemKind.skillCredential =>
        LocaleKeys.service_connections_type_skill_credential.tr(
          context: context,
        ),
    };
    final suffix = connection.keySuffix;
    if (suffix == null || suffix.isEmpty) {
      return '$kind - ${_serviceName(context)}';
    }
    return '$kind - ${_serviceName(context)} - ****$suffix';
  }

  String _serviceName(BuildContext context) {
    final serviceName = connection.serviceName;
    if (serviceName != null && serviceName.isNotEmpty) return serviceName;
    return LocaleKeys.service_connections_missing_credential_definition.tr(
      context: context,
    );
  }

  Future<void> _confirmDeleteCredential(
    BuildContext context,
    WidgetRef ref,
  ) async {
    _logger.info(
      'debug:skill credential delete confirmation opened '
      'workspace=${connection.workspaceId} credentialId=${connection.id} '
      'credentialNameLength=${connection.name.length}',
    );
    final confirmed = await showAuraConfirmDialog(
      context: context,
      title: const TextLocale(
        LocaleKeys.service_connections_delete_credential_title,
      ),
      message: Text(
        LocaleKeys.service_connections_delete_credential_confirm.tr(
          namedArgs: {'name': connection.name},
          context: context,
        ),
      ),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_delete),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
      isDestructive: true,
    );

    _logger.info(
      'debug:skill credential delete confirmation closed '
      'workspace=${connection.workspaceId} credentialId=${connection.id} '
      'confirmed=$confirmed contextMounted=${context.mounted}',
    );

    if (confirmed != true || !context.mounted) return;

    try {
      _logger.info(
        'debug:skill credential delete start '
        'workspace=${connection.workspaceId} credentialId=${connection.id}',
      );
      await ref
          .read(skillCredentialsRepositoryProvider)
          .deleteCredential(connection.id);
      _logger.info(
        'debug:skill credential delete completed '
        'workspace=${connection.workspaceId} credentialId=${connection.id}',
      );
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'debug:skill credential delete failed '
        'workspace=${connection.workspaceId} credentialId=${connection.id}',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      showAuraSnackBar(
        context: context,
        variant: AuraSnackBarVariant.error,
        content: const TextLocale(
          LocaleKeys.service_connections_delete_credential_error,
        ),
      );
    }
  }
}
