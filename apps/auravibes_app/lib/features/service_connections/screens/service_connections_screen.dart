// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';

import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/service_connections_action_usecase.dart';
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
const _mcpCredentialsDeleteError =
    'MCP credentials cannot be deleted from this screen.';

class ServiceConnectionsScreen extends ConsumerWidget {
  const ServiceConnectionsScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(serviceConnectionsProvider(workspaceId));

    void openCreateConnection() {
      unawaited(
        context.push<bool>(
          '/workspaces/$workspaceId/more/service-connections/new',
        ),
      );
    }

    return AuraScreen(
      child: switch (connectionsAsync) {
        AsyncData(:final value) => _ConnectionsList(
          connections: value,
          onAddConnection: openCreateConnection,
        ),
        AsyncLoading(value: final value?, hasValue: true) => _ConnectionsList(
          connections: value,
          onAddConnection: openCreateConnection,
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => const Center(
          child: AuraText(
            child: TextLocale(LocaleKeys.service_connections_load_error),
            color: AuraColorVariant.error,
          ),
        ),
      },
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.service_connections_title),
        actions: [
          AuraIconButton(
            icon: Icons.add,
            onPressed: openCreateConnection,
            tooltip: LocaleKeys.service_connections_add.tr(context: context),
          ),
        ],
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  const _ConnectionsList({
    required this.connections,
    required this.onAddConnection,
  });

  final List<ServiceConnectionListItem> connections;
  final VoidCallback onAddConnection;

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) {
      return Center(
        child: AuraColumn(
          children: [
            const AuraIcon(
              Icons.hub_outlined,
              size: AuraIconSize.extraLarge,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            const AuraText(
              child: TextLocale(LocaleKeys.service_connections_empty_title),
              style: AuraTextStyle.heading3,
            ),
            const AuraText(
              child: TextLocale(LocaleKeys.service_connections_empty_subtitle),
              textAlign: TextAlign.center,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            AuraButton(
              onPressed: onAddConnection,
              child: const TextLocale(LocaleKeys.service_connections_add),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
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
        child: AuraColumn(
          children: [
            AuraText(
              child: Text(connection.name),
              style: AuraTextStyle.heading6,
            ),
            AuraText(
              child: Text(_subtitle(context)),
              color: AuraColorVariant.onSurfaceVariant,
            ),
            if (connection.kind == ServiceConnectionListItemKind.mcpServer)
              _ConnectionStatusBadge(status: connection.displayStatus),
            if (connection.metadataValues.isNotEmpty)
              _ConnectionMetadata(values: connection.metadataValues),
          ],
          spacing: AuraSpacing.xs,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        variant: AuraTileVariant.ghost,
        leading: AuraIcon(_icon),
        trailing: AuraPopupMenu(
          child: AuraIconButton(
            icon: Icons.more_vert,
            onPressed: menuController.toggle,
          ),
          items: [
            if (connection.canReconnect)
              AuraPopupMenuItem(
                title: const TextLocale(
                  LocaleKeys.service_connections_action_reconnect,
                ),
                onTap: () => _reconnectMcpServer(context, ref),
                leading: const AuraIcon(Icons.refresh_outlined),
              ),
            if (connection.canRefresh)
              AuraPopupMenuItem(
                title: const TextLocale(
                  LocaleKeys.service_connections_action_refresh_token,
                ),
                onTap: () => _refreshToken(context, ref),
                leading: const AuraIcon(Icons.sync_outlined),
              ),
            if (connection.kind != ServiceConnectionListItemKind.mcpServer)
              AuraPopupMenuItem(
                title: const TextLocale(LocaleKeys.common_edit),
                onTap: () => context.push<bool>(
                  '/workspaces/${connection.workspaceId}/more/'
                  'service-connections/${connection.id}',
                ),
                leading: const AuraIcon(Icons.edit_outlined),
              ),
            if (connection.kind != ServiceConnectionListItemKind.mcpServer)
              AuraPopupMenuItem(
                title: const TextLocale(LocaleKeys.common_delete),
                onTap: () => _confirmDelete(context, ref),
                leading: const AuraIcon(Icons.delete_outline),
                variant: AuraTileVariant.error,
              ),
          ],
          controller: menuController,
        ),
      ),
      style: AuraCardStyle.border,
    );
  }

  IconData get _icon {
    return switch (connection.kind) {
      ServiceConnectionListItemKind.modelProvider => Icons.memory_outlined,
      ServiceConnectionListItemKind.skillCredential => Icons.key_outlined,
      ServiceConnectionListItemKind.mcpServer => Icons.hub_outlined,
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
      ServiceConnectionListItemKind.mcpServer =>
        LocaleKeys.service_connections_type_mcp_server.tr(context: context),
    };
    if (connection.kind == ServiceConnectionListItemKind.mcpServer) {
      return '$kind - ${connection.authenticationType ?? 'unknown'}/'
          '${_statusLabel(context, connection.displayStatus)} - '
          '${_serviceName(context)}';
    }
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final titleKey = switch (connection.kind) {
      ServiceConnectionListItemKind.modelProvider =>
        LocaleKeys.service_connections_delete_model_provider_title,
      ServiceConnectionListItemKind.skillCredential =>
        LocaleKeys.service_connections_delete_credential_title,
      ServiceConnectionListItemKind.mcpServer => throw StateError(
        _mcpCredentialsDeleteError,
      ),
    };
    final confirmKey = switch (connection.kind) {
      ServiceConnectionListItemKind.modelProvider =>
        LocaleKeys.service_connections_delete_model_provider_confirm,
      ServiceConnectionListItemKind.skillCredential =>
        LocaleKeys.service_connections_delete_credential_confirm,
      ServiceConnectionListItemKind.mcpServer => throw StateError(
        _mcpCredentialsDeleteError,
      ),
    };
    _logger.info(
      'debug:service connection delete confirmation opened '
      'workspace=${connection.workspaceId} connectionId=${connection.id} '
      'kind=${connection.kind.name} connectionNameLength='
      '${connection.name.length}',
    );
    final confirmed = await showAuraConfirmDialog(
      context: context,
      title: TextLocale(titleKey),
      message: Text(
        confirmKey.tr(
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
      'debug:service connection delete confirmation closed '
      'workspace=${connection.workspaceId} connectionId=${connection.id} '
      'kind=${connection.kind.name} confirmed=$confirmed '
      'contextMounted=${context.mounted}',
    );

    if (confirmed != true || !context.mounted) return;

    try {
      _logger.info(
        'debug:service connection delete start '
        'workspace=${connection.workspaceId} connectionId=${connection.id} '
        'kind=${connection.kind.name}',
      );
      switch (connection.kind) {
        case ServiceConnectionListItemKind.modelProvider:
          await ref
              .read(modelConnectionRepositoryProvider)
              .deleteModelConnection(connection.id);
        case ServiceConnectionListItemKind.skillCredential:
          await ref
              .read(skillCredentialsRepositoryProvider)
              .deleteCredential(connection.id);
        case ServiceConnectionListItemKind.mcpServer:
          throw StateError(_mcpCredentialsDeleteError);
      }
      _logger.info(
        'debug:service connection delete completed '
        'workspace=${connection.workspaceId} connectionId=${connection.id} '
        'kind=${connection.kind.name}',
      );
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'debug:service connection delete failed '
        'workspace=${connection.workspaceId} connectionId=${connection.id} '
        'kind=${connection.kind.name}',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      final errorKey = switch (connection.kind) {
        ServiceConnectionListItemKind.modelProvider =>
          LocaleKeys.service_connections_delete_model_provider_error,
        ServiceConnectionListItemKind.skillCredential =>
          LocaleKeys.service_connections_delete_credential_error,
        ServiceConnectionListItemKind.mcpServer =>
          LocaleKeys.service_connections_action_reconnect_error,
      };
      final _ = showAuraSnackBar(
        context: context,
        content: TextLocale(errorKey),
        variant: AuraSnackBarVariant.error,
      );
    }
  }

  Future<void> _reconnectMcpServer(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final serverId = connection.mcpServerId;
    if (serverId == null) return;

    try {
      await ref
          .read(serviceConnectionsActionUsecaseProvider)
          .reconnectMcpServer(
            serverId,
          );
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: const TextLocale(
          LocaleKeys.service_connections_action_reconnect_success,
        ),
      );
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'debug:mcp service connection reconnect failed '
        'workspace=${connection.workspaceId} connectionId=${connection.id} '
        'serverId=$serverId',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: const TextLocale(
          LocaleKeys.service_connections_action_reconnect_error,
        ),
        variant: AuraSnackBarVariant.error,
      );
    }
  }

  Future<void> _refreshToken(BuildContext context, WidgetRef ref) async {
    final serverId = connection.mcpServerId;
    if (serverId == null) return;

    try {
      await ref
          .read(serviceConnectionsActionUsecaseProvider)
          .refreshMcpCredential(
            connectionId: connection.id,
            mcpServerId: serverId,
          );
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: const TextLocale(
          LocaleKeys.service_connections_action_refresh_success,
        ),
      );
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'debug:mcp service connection token refresh failed '
        'workspace=${connection.workspaceId} connectionId=${connection.id} '
        'serverId=$serverId',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: const TextLocale(
          LocaleKeys.service_connections_action_refresh_error,
        ),
        variant: AuraSnackBarVariant.error,
      );
    }
  }
}

class _ConnectionStatusBadge extends StatelessWidget {
  const _ConnectionStatusBadge({required this.status});

  final ServiceConnectionDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: _color(context).withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Text(
        _statusLabel(context, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _color(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return switch (status) {
      ServiceConnectionDisplayStatus.connected => colors.primary,
      ServiceConnectionDisplayStatus.expiringSoon => colors.tertiary,
      ServiceConnectionDisplayStatus.needsReauth => colors.error,
      ServiceConnectionDisplayStatus.failed => colors.error,
      ServiceConnectionDisplayStatus.unknown => colors.outline,
    };
  }
}

class _ConnectionMetadata extends StatelessWidget {
  const _ConnectionMetadata({required this.values});

  final List<ServiceConnectionMetadataValue> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((value) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            '${_metadataLabel(context, value.key)}: ${value.value}',
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        );
      }).toList(),
    );
  }
}

String _statusLabel(
  BuildContext context,
  ServiceConnectionDisplayStatus status,
) {
  final key = switch (status) {
    ServiceConnectionDisplayStatus.connected =>
      LocaleKeys.service_connections_status_connected,
    ServiceConnectionDisplayStatus.expiringSoon =>
      LocaleKeys.service_connections_status_expiring_soon,
    ServiceConnectionDisplayStatus.needsReauth =>
      LocaleKeys.service_connections_status_needs_reauth,
    ServiceConnectionDisplayStatus.failed =>
      LocaleKeys.service_connections_status_failed,
    ServiceConnectionDisplayStatus.unknown =>
      LocaleKeys.service_connections_status_unknown,
  };

  return key.tr(context: context);
}

String _metadataLabel(
  BuildContext context,
  ServiceConnectionMetadataKey key,
) {
  final localeKey = switch (key) {
    ServiceConnectionMetadataKey.issuer =>
      LocaleKeys.service_connections_metadata_issuer,
    ServiceConnectionMetadataKey.clientId =>
      LocaleKeys.service_connections_metadata_client_id,
    ServiceConnectionMetadataKey.scopes =>
      LocaleKeys.service_connections_metadata_scopes,
    ServiceConnectionMetadataKey.expiresAt =>
      LocaleKeys.service_connections_metadata_expires_at,
    ServiceConnectionMetadataKey.lastRefreshedAt =>
      LocaleKeys.service_connections_metadata_last_refreshed_at,
    ServiceConnectionMetadataKey.lastAuthError =>
      LocaleKeys.service_connections_metadata_last_auth_error,
  };

  return localeKey.tr(context: context);
}
