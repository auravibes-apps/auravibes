// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';

import 'package:auravibes_app/features/models/notifiers/model_catalog_sync_notifier.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/service_connections_action_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/stable_ui_selector.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show MaterialLocalizations, TimeOfDay;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('service_connections_screen');
const _mcpCredentialsDeleteError =
    'MCP credentials cannot be deleted from this screen.';
const _deleteConfirmationActions = AuraConfirmDialogActions(
  confirmLabel: TextLocale(LocaleKeys.common_delete),
  cancelLabel: TextLocale(LocaleKeys.common_cancel),
);

enum _ConnectionFilter {
  all,
  modelProviders,
  skillCredentials,
  mcpServers,
  oauth,
  failed,
  expiringSoon,
  needsAuth,
}

typedef _ConnectionFilterOptionData = ({
  _ConnectionFilter value,
  String titleKey,
});

typedef _DeleteErrorRequest = ({
  BuildContext context,
  ServiceConnectionListItem connection,
  Object error,
  StackTrace stackTrace,
});

class _McpActionRequest {
  const new({
    required this.context,
    required this.ref,
    required this.connection,
    required this.serverId,
    required this.actionName,
    required this.successKey,
    required this.errorKey,
    required this.action,
  });

  new _reconnect({
    required BuildContext context,
    required WidgetRef ref,
    required ServiceConnectionListItem connection,
    required String serverId,
  }) : this(
         context: context,
         ref: ref,
         connection: connection,
         serverId: serverId,
         actionName: 'reconnect',
         successKey: LocaleKeys.service_connections_action_reconnect_success,
         errorKey: LocaleKeys.service_connections_action_reconnect_error,
         action: (usecase) => usecase.reconnectMcpServer(serverId),
       );

  new _refresh({
    required BuildContext context,
    required WidgetRef ref,
    required ServiceConnectionListItem connection,
    required String serverId,
  }) : this(
         context: context,
         ref: ref,
         connection: connection,
         serverId: serverId,
         actionName: 'token refresh',
         successKey: LocaleKeys.service_connections_action_refresh_success,
         errorKey: LocaleKeys.service_connections_action_refresh_error,
         action: (usecase) =>
             _refreshMcpCredential(usecase, connection, serverId),
       );

  final BuildContext context;
  final WidgetRef ref;
  final ServiceConnectionListItem connection;
  final String serverId;
  final String actionName;
  final String successKey;
  final String errorKey;
  final Future<void> Function(ServiceConnectionsActionUsecase usecase) action;
}

const _connectionFilterData = <_ConnectionFilterOptionData>[
  (value: .all, titleKey: LocaleKeys.service_connections_filter_all),
  (
    value: .modelProviders,
    titleKey: LocaleKeys.service_connections_filter_model_providers,
  ),
  (
    value: .skillCredentials,
    titleKey: LocaleKeys.service_connections_filter_skill_credentials,
  ),
  (
    value: .mcpServers,
    titleKey: LocaleKeys.service_connections_filter_mcp_servers,
  ),
  (value: .oauth, titleKey: LocaleKeys.service_connections_filter_oauth),
  (value: .failed, titleKey: LocaleKeys.service_connections_filter_failed),
  (
    value: .expiringSoon,
    titleKey: LocaleKeys.service_connections_filter_expiring,
  ),
  (
    value: .needsAuth,
    titleKey: LocaleKeys.service_connections_filter_needs_auth,
  ),
];

class const ServiceConnectionsScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  static const _tagSpacing = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(serviceConnectionsProvider(workspaceId));
    ref.listen(
      serviceConnectionsProvider(workspaceId),
      (_, next) => _logServiceConnectionsLoadError(workspaceId, next),
    );

    return _ServiceConnectionsView(
      connectionsAsync: connectionsAsync,
      onAddConnection: () => _openCreateConnection(context, workspaceId),
      workspaceId: workspaceId,
    );
  }
}

bool _canSyncModelCatalog(AsyncValue<WorkspaceSession> session) =>
    switch (session) {
      AsyncData(:final value) => value.cloud == null,
      AsyncLoading() || AsyncError() => false,
    };

Future<void> _syncModelCatalog(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  final wasSuccessful = await _performModelCatalogSync(context, ref, workspaceId);
  if (!context.mounted || wasSuccessful != true) return;

  _showModelCatalogSyncResult(context);
}

Future<bool?> _performModelCatalogSync(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  if (ref.read(modelCatalogSyncNotifierProvider).isSyncing) return null;

  try {
    await ref.read(modelCatalogSyncNotifierProvider.notifier).retryManually();
    if (context.mounted) {
      ref.invalidate(apiModelProvidersProvider(workspaceId: workspaceId));
    }
    return true;
  } on Object catch (error, stackTrace) {
    _logger.warning('Model catalog sync failed', error, stackTrace);
    return false;
  }
}

void _showModelCatalogSyncResult(BuildContext context) {
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(LocaleKeys.models_screens_catalog_sync_success),
    variant: .success,
  );
}

void _logServiceConnectionsLoadError(
  String workspaceId,
  AsyncValue<List<ServiceConnectionListItem>> value,
) {
  if (value case AsyncError(:final error, :final stackTrace)) {
    _logServiceConnectionsError(workspaceId, error, stackTrace);
  }
}

void _logServiceConnectionsError(
  String workspaceId,
  Object error,
  StackTrace stackTrace,
) => _logger.severe(
  'Service connections load failed for workspace $workspaceId',
  error,
  stackTrace,
);

void _openCreateConnection(BuildContext context, String workspaceId) =>
    unawaited(
      context.push<bool>(
        '/workspaces/$workspaceId/more/service-connections/new',
      ),
    );

class const _ServiceConnectionsView({
  required final AsyncValue<List<ServiceConnectionListItem>> connectionsAsync,
  required final VoidCallback onAddConnection,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _ServiceConnectionsBody(
        connectionsAsync: connectionsAsync,
        onAddConnection: onAddConnection,
      ),
      appBar: _ServiceConnectionsAppBar(
        onAddConnection: onAddConnection,
        workspaceId: workspaceId,
      ),
    );
  }
}

class const _ServiceConnectionsBody({
  required final AsyncValue<List<ServiceConnectionListItem>> connectionsAsync,
  required final VoidCallback onAddConnection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connections = _connectionsValue(connectionsAsync);
    final Widget content;
    if (connections != null) {
      content = _ConnectionsList(
        connections: connections,
        onAddConnection: onAddConnection,
      );
    } else {
      content = connectionsAsync.isLoading
          ? const Center(child: AuraSpinner())
          : const Center(child: _ConnectionsLoadError());
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const _ModelCatalogSyncStatus(),
        Expanded(child: content),
      ],
    );
  }
}

class const _ModelCatalogSyncStatus() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modelCatalogSyncNotifierProvider);
    final lastAttemptAt = state.lastAttemptAt;
    if (lastAttemptAt == null) return const SizedBox.shrink();

    final localizations = MaterialLocalizations.of(context);
    String formatTimestamp(DateTime timestamp) =>
        '${localizations.formatMediumDate(timestamp)} '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(timestamp))}';
    Widget statusRow(String labelKey, DateTime timestamp) => Row(
      children: [
        Expanded(child: TextLocale(labelKey)),
        const SizedBox(width: 8),
        Text(formatTimestamp(timestamp)),
      ],
    );
    final lastSuccessfulSyncAt = state.lastSuccessfulSyncAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (state.isSyncing)
            statusRow(
              LocaleKeys.models_screens_catalog_sync_tooltip,
              lastAttemptAt,
            ),
          if (state.failure != null)
            statusRow(LocaleKeys.models_screens_catalog_sync_error, lastAttemptAt),
          if (lastSuccessfulSyncAt != null)
            statusRow(
              LocaleKeys.service_connections_metadata_last_refreshed_at,
              lastSuccessfulSyncAt,
            ),
        ],
      ),
    );
  }
}

List<ServiceConnectionListItem>? _connectionsValue(
  AsyncValue<List<ServiceConnectionListItem>> value,
) => switch (value) {
  AsyncData(:final value) => value,
  AsyncLoading(value: final value?, hasValue: true) => value,
  AsyncLoading() => null,
  AsyncError() => null,
};

class const _ConnectionsLoadError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.service_connections_load_error),
    tint: .error,
  );
}

class const _ServiceConnectionsAppBar({
  required final VoidCallback onAddConnection,
  required final String workspaceId,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBarWithDrawer(
      title: const TextLocale(LocaleKeys.service_connections_title),
      actions: [
        _SyncModelCatalogButton(workspaceId: workspaceId),
        _ConnectionsAddButton(onPressed: onAddConnection),
      ],
      leading: const _ConnectionsBackButton(),
    );
  }
}

class const _SyncModelCatalogButton({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workspaceSessionForRouteProvider(workspaceId));
    if (!_canSyncModelCatalog(session)) return const SizedBox.shrink();

    return _SyncModelCatalogControl(workspaceId: workspaceId);
  }
}

class const _SyncModelCatalogControl({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(modelCatalogSyncNotifierProvider).isSyncing;

    return _ModelCatalogSyncIconButton(
      onPressed: () => unawaited(_syncModelCatalog(context, ref, workspaceId)),
      isSyncing: isSyncing,
    );
  }
}

class const _ModelCatalogSyncIconButton({
  required final VoidCallback onPressed,
  required final bool isSyncing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('service_connections_sync'),
    child: AuraIconButton.custom(
      child: isSyncing
          ? const AuraSpinner(size: .small)
          : const AuraIcon(Icons.sync),
      onPressed: isSyncing ? null : onPressed,
      disabled: isSyncing,
      tooltip: LocaleKeys.models_screens_catalog_sync_tooltip.tr(
        context: context,
      ),
    ),
    identifier: 'service_connections_sync',
  );
}

class const _ConnectionsAddButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('service_connections_add'),
    child: AuraIconButton(
      icon: Icons.add,
      onPressed: onPressed,
      tooltip: LocaleKeys.service_connections_add.tr(context: context),
    ),
    identifier: 'service_connections_add',
  );
}

class const _ConnectionsBackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('service_connections_back'),
    child: AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    ),
    identifier: 'service_connections_back',
  );
}

class const _ConnectionsList({
  required final List<ServiceConnectionListItem> connections,
  required final VoidCallback onAddConnection,
}) extends StatefulWidget {
  @override
  State<_ConnectionsList> createState() => _ConnectionsListState();
}

class _ConnectionsListState extends State<_ConnectionsList> {
  _ConnectionFilter _selectedFilter = .all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (widget.connections.isEmpty) {
      return _EmptyConnections(onAddConnection: widget.onAddConnection);
    }

    return _ConnectionsListContent(
      connections: widget.connections,
      filter: _selectedFilter,
      onAddConnection: widget.onAddConnection,
      onFilterChanged: _onFilterChanged,
      onSearchChanged: _onSearchChanged,
      searchQuery: _searchQuery,
    );
  }

  void _onFilterChanged(_ConnectionFilter filter) {
    setState(() => _selectedFilter = filter);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }
}

class const _EmptyConnections({required final VoidCallback onAddConnection})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: _EmptyConnectionsContent(onAddConnection: onAddConnection));
}

class const _EmptyConnectionsContent({
  required final VoidCallback onAddConnection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const _EmptyConnectionsIntro(),
      _ConnectionsAddAction(onPressed: onAddConnection),
    ],
    mainAxisAlignment: .center,
  );
}

class const _EmptyConnectionsIntro() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraColumn(
    children: [
      AuraIcon(Icons.hub_outlined, size: .extraLarge),
      _EmptyConnectionsCopy(),
    ],
    mainAxisSize: .min,
  );
}

class const _EmptyConnectionsCopy() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraColumn(
    children: [
      AuraText(
        child: TextLocale(LocaleKeys.service_connections_empty_title),
        style: .heading3,
      ),
      AuraText(
        child: TextLocale(LocaleKeys.service_connections_empty_subtitle),
        textAlign: .center,
      ),
    ],
    mainAxisSize: .min,
  );
}

class const _ConnectionsAddAction({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('service_connections_empty_add'),
    child: AuraButton(
      onPressed: onPressed,
      child: const TextLocale(LocaleKeys.service_connections_add),
    ),
    identifier: 'service_connections_empty_add',
  );
}

class const _ConnectionsListContent({
  required final List<ServiceConnectionListItem> connections,
  required final _ConnectionFilter filter,
  required final VoidCallback onAddConnection,
  required final ValueChanged<_ConnectionFilter> onFilterChanged,
  required final ValueChanged<String> onSearchChanged,
  required final String searchQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _ConnectionSearchInput(onChanged: onSearchChanged),
        _ConnectionFilterSelector(value: filter, onChanged: onFilterChanged),
        Expanded(
          child: _ConnectionsTab(
            connections: connections,
            onAddConnection: onAddConnection,
            filter: filter,
            searchQuery: searchQuery,
          ),
        ),
      ],
    );
  }
}

class const _ConnectionSearchInput({
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: AuraInput(
      key: const ValueKey<String>('service_connections_search'),
      placeholder: const TextLocale(
        LocaleKeys.service_connections_search_placeholder,
      ),
      prefixIcon: const AuraIcon(Icons.search),
      size: .small,
      onChanged: onChanged,
    ),
  );
}

class const _ConnectionFilterSelector({
  required final _ConnectionFilter value,
  required final ValueChanged<_ConnectionFilter> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTabs<_ConnectionFilter>.selector(
      options: _connectionFilterOptions(context),
      value: value,
      onChanged: onChanged,
    );
  }
}

List<AuraTabOption<_ConnectionFilter>> _connectionFilterOptions(
  BuildContext context,
) =>
    _connectionFilterData.map((option) => option.toTabOption(context)).toList();

extension on _ConnectionFilterOptionData {
  AuraTabOption<_ConnectionFilter> toTabOption(BuildContext context) =>
      AuraTabOption(
        value: value,
        title: TextLocale(titleKey),
        semanticLabel: titleKey.tr(context: context),
      );
}

bool _matchesConnectionFilter(
  ServiceConnectionListItem connection,
  _ConnectionFilter filter,
) => switch (filter) {
  .all => true,
  .modelProviders ||
  .skillCredentials ||
  .mcpServers => _matchesConnectionKind(connection, filter),
  .oauth => _isOauthConnection(connection),
  .failed ||
  .expiringSoon ||
  .needsAuth => _matchesConnectionStatus(connection, filter),
};

bool _matchesConnectionKind(
  ServiceConnectionListItem connection,
  _ConnectionFilter filter,
) => switch (filter) {
  .modelProviders => connection.kind == .modelProvider,
  .skillCredentials => connection.kind == .skillCredential,
  .mcpServers => connection.kind == .mcpServer,
  _ => false,
};

bool _isOauthConnection(ServiceConnectionListItem connection) =>
    connection.authenticationType?.toLowerCase().contains('oauth') ?? false;

bool _matchesConnectionStatus(
  ServiceConnectionListItem connection,
  _ConnectionFilter filter,
) => switch (filter) {
  .failed => connection.displayStatus == .failed,
  .expiringSoon => connection.displayStatus == .expiringSoon,
  .needsAuth => connection.displayStatus == .needsReauth,
  _ => false,
};

Iterable<String?> _connectionSearchValues(
  ServiceConnectionListItem connection,
) => [
  connection.name,
  connection.serviceName,
  connection.authenticationType,
  ...connection.metadataValues.map((value) => value.value),
];

List<ServiceConnectionListItem> _filterConnections(
  List<ServiceConnectionListItem> connections,
  _ConnectionFilter filter,
  String searchQuery,
) {
  final normalizedQuery = _normalizeSearchQuery(searchQuery);

  return connections
      .where(
        (connection) =>
            _matchesConnectionFilter(connection, filter) &&
            _matchesConnectionSearch(connection, normalizedQuery),
      )
      .toList();
}

String _normalizeSearchQuery(String searchQuery) =>
    searchQuery.trim().toLowerCase();

bool _matchesConnectionSearch(
  ServiceConnectionListItem connection,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return true;

  return _connectionSearchValues(connection)
      .any((value) => value?.toLowerCase().contains(normalizedQuery) ?? false);
}

class const _ConnectionsTab({
  required final List<ServiceConnectionListItem> connections,
  required final VoidCallback onAddConnection,
  required final _ConnectionFilter filter,
  required final String searchQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visibleConnections = _filterConnections(
      connections,
      filter,
      searchQuery,
    );

    if (visibleConnections.isEmpty) {
      return _EmptyFilteredConnections(
        filter: filter,
        onAddConnection: onAddConnection,
        searchQuery: searchQuery,
      );
    }

    return _ConnectionsListView(connections: visibleConnections);
  }
}

class const _EmptyFilteredConnections({
  required final _ConnectionFilter filter,
  required final VoidCallback onAddConnection,
  required final String searchQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: _EmptyFilteredConnectionsContent(
      filter: filter,
      onAddConnection: onAddConnection,
      searchQuery: searchQuery,
    ),
  );
}

class const _EmptyFilteredConnectionsContent({
  required final _ConnectionFilter filter,
  required final VoidCallback onAddConnection,
  required final String searchQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraIcon(
        searchQuery.trim().isEmpty ? Icons.hub_outlined : Icons.search_off,
        size: .extraLarge,
      ),
      AuraText(
        child: Text(_filteredConnectionsMessage(context, filter, searchQuery)),
        style: .heading3,
      ),
      _ConnectionsAddAction(onPressed: onAddConnection),
    ],
    mainAxisAlignment: .center,
  );
}

String _filteredConnectionsMessage(
  BuildContext context,
  _ConnectionFilter filter,
  String searchQuery,
) {
  if (searchQuery.trim().isNotEmpty) {
    return LocaleKeys.service_connections_empty_search.tr(context: context);
  }

  return LocaleKeys.service_connections_empty_filter.tr(
    namedArgs: {'type': _connectionFilterLabel(context, filter)},
    context: context,
  );
}

class const _ConnectionsListView({
  required final List<ServiceConnectionListItem> connections,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) =>
          _ConnectionTile(connection: connections[index]),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: connections.length,
    );
  }
}

String _connectionFilterLabel(BuildContext context, _ConnectionFilter filter) {
  final localeKey = switch (filter) {
    .all => LocaleKeys.service_connections_filter_all,
    .modelProviders => LocaleKeys.service_connections_filter_model_providers,
    .skillCredentials =>
      LocaleKeys.service_connections_filter_skill_credentials,
    .mcpServers => LocaleKeys.service_connections_filter_mcp_servers,
    .oauth => LocaleKeys.service_connections_filter_oauth,
    .failed => LocaleKeys.service_connections_filter_failed,
    .expiringSoon => LocaleKeys.service_connections_filter_expiring,
    .needsAuth => LocaleKeys.service_connections_filter_needs_auth,
  };

  return localeKey.tr(context: context);
}

class const _ConnectionTile({
  required final ServiceConnectionListItem connection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraTile(
        child: _ConnectionTileContent(
          connection: connection,
          subtitle: _connectionSubtitle(context, connection),
        ),
        variant: .ghost,
        leading: AuraIcon(_connectionIcon(connection)),
        trailing: _ConnectionTileMenu(connection: connection),
      ),
      style: .border,
    );
  }
}

class const _ConnectionTileContent({
  required final ServiceConnectionListItem connection,
  required final String subtitle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ConnectionTitle(name: connection.name),
      _ConnectionSubtitle(value: subtitle),
      _ConnectionTileDetails(connection: connection),
      _ConnectionWarning(connection: connection),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _ConnectionTitle({required final String name})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraText(child: Text(name), style: .heading6);
}

class const _ConnectionSubtitle({required final String value})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(child: Text(value));
}

class const _ConnectionTileDetails({
  required final ServiceConnectionListItem connection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (connection.kind == ServiceConnectionListItemKind.mcpServer)
        _ConnectionStatusBadge(status: connection.displayStatus),
      if (connection.metadataValues.isNotEmpty)
        _ConnectionMetadata(values: connection.metadataValues),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
    mainAxisSize: .min,
  );
}

typedef _ConnectionWarningData = ({String titleKey, AuraTint tint});

typedef _ConnectionWarningAction = ({String labelKey, bool refresh});

class const _ConnectionWarning({
  required final ServiceConnectionListItem connection,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warning = _connectionWarning(connection);
    if (warning == null) return const SizedBox.shrink();

    return _ConnectionWarningBody(connection: connection, warning: warning);
  }
}

class const _ConnectionWarningBody({
  required final ServiceConnectionListItem connection,
  required final _ConnectionWarningData warning,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final action = _connectionWarningAction(connection);

    return AuraColumn(
      children: [
        _ConnectionWarningCallout(warning: warning),
        if (action case final action?)
          _ConnectionWarningActionButton(
            connection: connection,
            action: action,
          ),
      ],
      spacing: .xs,
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
    );
  }
}

class const _ConnectionWarningCallout({
  required final _ConnectionWarningData warning,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCallout(
    title: warning.titleKey.tr(context: context),
    icon: Icons.warning_amber_outlined,
    tint: warning.tint,
  );
}

class const _ConnectionWarningActionButton({
  required final ServiceConnectionListItem connection,
  required final _ConnectionWarningAction action,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: .centerRight,
      child: StableUiSelector(
        identifier: 'service_connection_warning_${connection.id}',
        child: AuraButton(
          onPressed: () => unawaited(
            _runConnectionWarningAction(
              context,
              ref,
              connection,
              action.refresh,
            ),
          ),
          child: TextLocale(action.labelKey),
          variant: .outlined,
          size: .small,
        ),
      ),
    );
  }
}

_ConnectionWarningData? _connectionWarning(
  ServiceConnectionListItem connection,
) => switch (connection.displayStatus) {
  .expiringSoon => (
    titleKey: LocaleKeys.service_connections_warning_expiring_soon,
    tint: .warning,
  ),
  .expired => (
    titleKey: LocaleKeys.service_connections_warning_expired,
    tint: .error,
  ),
  .needsReauth => (
    titleKey: LocaleKeys.service_connections_warning_needs_reauth,
    tint: .error,
  ),
  .failed => (
    titleKey: LocaleKeys.service_connections_warning_failed,
    tint: .error,
  ),
  .connected || .unknown => null,
};

_ConnectionWarningAction? _connectionWarningAction(
  ServiceConnectionListItem connection,
) {
  final status = connection.displayStatus;
  if (status == .expiringSoon || status == .expired) {
    if (connection.canRefresh) {
      return (
        labelKey: LocaleKeys.service_connections_action_refresh_token,
        refresh: true,
      );
    }
  }

  if (connection.canReconnect) {
    return (
      labelKey: LocaleKeys.service_connections_action_reconnect,
      refresh: false,
    );
  }
  if (connection.canRefresh) {
    return (
      labelKey: LocaleKeys.service_connections_action_refresh_token,
      refresh: true,
    );
  }

  return null;
}

Future<void> _runConnectionWarningAction(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
  bool refresh,
) => refresh
    ? _refreshToken(context, ref, connection)
    : _reconnectMcpServer(context, ref, connection);

class const _ConnectionTileMenu({
  required final ServiceConnectionListItem connection,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuController = AuraPopupMenuController();
    final selectorId = 'service_connection_menu_${connection.id}';

    return StableUiSelector(
      identifier: selectorId,
      child: AuraPopupMenu(
        child: AuraIconButton(
          icon: Icons.more_vert,
          onPressed: menuController.toggle,
        ),
        items: [..._connectionMenuItems(context, ref, connection)],
        controller: menuController,
      ),
    );
  }
}

IconData _connectionIcon(ServiceConnectionListItem connection) {
  return switch (connection.kind) {
    .modelProvider => Icons.memory_outlined,
    .skillCredential => Icons.key_outlined,
    .mcpServer => Icons.hub_outlined,
  };
}

String _connectionSubtitle(
  BuildContext context,
  ServiceConnectionListItem connection,
) {
  final kind = _connectionTypeLabel(context, connection.kind);
  if (connection.kind == ServiceConnectionListItemKind.mcpServer) {
    return _mcpConnectionSubtitle(context, connection, kind);
  }

  return _credentialConnectionSubtitle(context, connection, kind);
}

String _connectionTypeLabel(
  BuildContext context,
  ServiceConnectionListItemKind kind,
) {
  return switch (kind) {
    .modelProvider => LocaleKeys.service_connections_type_model_provider.tr(
      context: context,
    ),
    .skillCredential => LocaleKeys.service_connections_type_skill_credential.tr(
      context: context,
    ),
    .mcpServer => LocaleKeys.service_connections_type_mcp_server.tr(
      context: context,
    ),
  };
}

String _mcpConnectionSubtitle(
  BuildContext context,
  ServiceConnectionListItem connection,
  String kind,
) {
  return '$kind - ${connection.authenticationType ?? 'unknown'}/'
      '${_statusLabel(context, connection.displayStatus)} - '
      '${_connectionServiceName(context, connection)}';
}

String _credentialConnectionSubtitle(
  BuildContext context,
  ServiceConnectionListItem connection,
  String kind,
) {
  final suffix = connection.keySuffix;
  if (suffix == null || suffix.isEmpty) {
    return '$kind - ${_connectionServiceName(context, connection)}';
  }

  return '$kind - ${_connectionServiceName(context, connection)} - ****$suffix';
}

String _connectionServiceName(
  BuildContext context,
  ServiceConnectionListItem connection,
) {
  final serviceName = connection.serviceName;
  if (serviceName != null && serviceName.isNotEmpty) return serviceName;

  return LocaleKeys.service_connections_missing_credential_definition.tr(
    context: context,
  );
}

List<AuraPopupMenuItem> _connectionMenuItems(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
) {
  return [
    if (connection.canReconnect) _reconnectMenuItem(context, ref, connection),
    if (connection.canRefresh) _refreshMenuItem(context, ref, connection),
    if (_canEditConnection(connection)) _editMenuItem(context, connection),
    if (_canDeleteConnection(connection))
      _deleteMenuItem(context, ref, connection),
  ];
}

bool _canEditConnection(ServiceConnectionListItem connection) {
  return connection.kind == ServiceConnectionListItemKind.modelProvider ||
      connection.kind == ServiceConnectionListItemKind.skillCredential;
}

bool _canDeleteConnection(ServiceConnectionListItem connection) {
  return connection.kind != ServiceConnectionListItemKind.mcpServer;
}

AuraPopupMenuItem _reconnectMenuItem(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
) {
  return AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.service_connections_action_reconnect),
    onTap: () => _reconnectMcpServer(context, ref, connection),
    leading: const AuraIcon(Icons.refresh_outlined),
  );
}

AuraPopupMenuItem _refreshMenuItem(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
) {
  return AuraPopupMenuItem(
    title: const TextLocale(
      LocaleKeys.service_connections_action_refresh_token,
    ),
    onTap: () => _refreshToken(context, ref, connection),
    leading: const AuraIcon(Icons.sync_outlined),
  );
}

AuraPopupMenuItem _editMenuItem(
  BuildContext context,
  ServiceConnectionListItem connection,
) {
  return AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.common_edit),
    onTap: () => context.push<bool>(
      '/workspaces/${connection.workspaceId}/more/'
      'service-connections/${connection.id}',
    ),
    leading: const AuraIcon(Icons.edit_outlined),
  );
}

AuraPopupMenuItem _deleteMenuItem(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
) {
  return AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.common_delete),
    onTap: () => _confirmDelete(context, ref, connection),
    leading: const AuraIcon(Icons.delete_outline),
    variant: .error,
  );
}

({String titleKey, String confirmKey}) _deleteDialogKeys(
  ServiceConnectionListItemKind kind,
) {
  return switch (kind) {
    .modelProvider => (
      titleKey: LocaleKeys.service_connections_delete_model_provider_title,
      confirmKey: LocaleKeys.service_connections_delete_model_provider_confirm,
    ),
    .skillCredential => (
      titleKey: LocaleKeys.service_connections_delete_credential_title,
      confirmKey: LocaleKeys.service_connections_delete_credential_confirm,
    ),
    .mcpServer => throw StateError(_mcpCredentialsDeleteError),
  };
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
) async {
  final confirmed = await _confirmDeleteDialog(context, connection);

  if (confirmed != true || !context.mounted) return;

  await _deleteConfirmedConnection(
    context: context,
    ref: ref,
    connection: connection,
  );
}

Future<void> _deleteConfirmedConnection({
  required BuildContext context,
  required WidgetRef ref,
  required ServiceConnectionListItem connection,
}) async {
  try {
    await _deleteConnection(ref, connection);
    _logDeleteCompleted(connection);
  } on Object catch (error, stackTrace) {
    if (!context.mounted) return;
    _handleDeleteError((
      context: context,
      connection: connection,
      error: error,
      stackTrace: stackTrace,
    ));
  }
}

Future<bool?> _confirmDeleteDialog(
  BuildContext context,
  ServiceConnectionListItem connection,
) async {
  final keys = _deleteDialogKeys(connection.kind);
  _logDeleteConfirmationOpened(connection);
  final confirmed = await _showDeleteConfirmation(context, connection, keys);
  _logDeleteConfirmationClosed(connection, confirmed, context.mounted);

  return confirmed;
}

class const _DeleteConfirmationMessage({
  required final String messageKey,
  required final String connectionName,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    messageKey.tr(namedArgs: {'name': connectionName}, context: context),
  );
}

Future<bool?> _showDeleteConfirmation(
  BuildContext context,
  ServiceConnectionListItem connection,
  ({String titleKey, String confirmKey}) keys,
) {
  return AuraDialogs.confirm(
    context: context,
    title: TextLocale(keys.titleKey),
    message: _DeleteConfirmationMessage(
      messageKey: keys.confirmKey,
      connectionName: connection.name,
    ),
    actions: _deleteConfirmationActions,
    isDestructive: true,
  );
}

void _logDeleteConfirmationOpened(ServiceConnectionListItem connection) {
  _logger.info(
    'debug:service connection delete confirmation opened '
    'workspace=${connection.workspaceId} connectionId=${connection.id} '
    'kind=${connection.kind.name} connectionNameLength='
    '${connection.name.length}',
  );
}

void _logDeleteConfirmationClosed(
  ServiceConnectionListItem connection,
  bool? confirmed,
  bool contextMounted,
) {
  _logger.info(
    'debug:service connection delete confirmation closed '
    'workspace=${connection.workspaceId} connectionId=${connection.id} '
    'kind=${connection.kind.name} confirmed=$confirmed '
    'contextMounted=$contextMounted',
  );
}

Future<void> _deleteConnection(
  WidgetRef ref,
  ServiceConnectionListItem connection,
) async {
  _logger.info(
    'debug:service connection delete start '
    'workspace=${connection.workspaceId} connectionId=${connection.id} '
    'kind=${connection.kind.name}',
  );
  final usecase = await ref.read(
    serviceConnectionsActionUsecaseProvider(connection.workspaceId).future,
  );
  await usecase.deleteConnection(
    connectionId: connection.id,
    kind: connection.kind,
  );
}

void _logDeleteCompleted(ServiceConnectionListItem connection) {
  _logger.info(
    'debug:service connection delete completed '
    'workspace=${connection.workspaceId} connectionId=${connection.id} '
    'kind=${connection.kind.name}',
  );
}

void _handleDeleteError(_DeleteErrorRequest request) {
  _logDeleteError(request);
  _showServiceConnectionSnack(
    request.context,
    _deleteErrorKey(request.connection.kind),
    variant: .error,
  );
}

void _logDeleteError(_DeleteErrorRequest request) {
  _logger.severe(
    'debug:service connection delete failed '
    'workspace=${request.connection.workspaceId} '
    'connectionId=${request.connection.id} '
    'kind=${request.connection.kind.name}',
    request.error,
    request.stackTrace,
  );
}

String _deleteErrorKey(ServiceConnectionListItemKind kind) {
  return switch (kind) {
    .modelProvider =>
      LocaleKeys.service_connections_delete_model_provider_error,
    .skillCredential => LocaleKeys.service_connections_delete_credential_error,
    .mcpServer => LocaleKeys.service_connections_action_reconnect_error,
  };
}

Future<void> _reconnectMcpServer(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
) async {
  final serverId = connection.mcpServerId;
  if (serverId == null) return;

  await _runMcpAction(
    ._reconnect(
      context: context,
      ref: ref,
      connection: connection,
      serverId: serverId,
    ),
  );
}

Future<void> _refreshToken(
  BuildContext context,
  WidgetRef ref,
  ServiceConnectionListItem connection,
) async {
  final serverId = connection.mcpServerId;
  if (serverId == null) return;

  await _runMcpAction(
    ._refresh(
      context: context,
      ref: ref,
      connection: connection,
      serverId: serverId,
    ),
  );
}

Future<void> _refreshMcpCredential(
  ServiceConnectionsActionUsecase usecase,
  ServiceConnectionListItem connection,
  String serverId,
) {
  return usecase.refreshMcpCredential(
    connectionId: connection.id,
    mcpServerId: serverId,
  );
}

Future<void> _runMcpAction(_McpActionRequest request) async {
  try {
    await _performMcpAction(request);
    _showMcpActionSuccess(request);
  } on Object catch (error, stackTrace) {
    _handleMcpActionFailure(request, error, stackTrace);
  }
}

Future<void> _performMcpAction(_McpActionRequest request) async {
  final usecase = await request.ref.read(
    serviceConnectionsActionUsecaseProvider(request.connection.workspaceId)
        .future,
  );
  await request.action(usecase);
}

void _showMcpActionSuccess(_McpActionRequest request) {
  if (!request.context.mounted) return;
  _showServiceConnectionSnack(request.context, request.successKey);
}

void _handleMcpActionFailure(
  _McpActionRequest request,
  Object error,
  StackTrace stackTrace,
) {
  _logMcpActionFailure(request, error, stackTrace);
  if (!request.context.mounted) return;
  _showServiceConnectionSnack(
    request.context,
    request.errorKey,
    variant: .error,
  );
}

void _logMcpActionFailure(
  _McpActionRequest request,
  Object error,
  StackTrace stackTrace,
) {
  _logger.severe(
    'debug:mcp service connection ${request.actionName} failed '
    'workspace=${request.connection.workspaceId} '
    'connectionId=${request.connection.id} '
    'serverId=${request.serverId}',
    error,
    stackTrace,
  );
}

void _showServiceConnectionSnack(
  BuildContext context,
  String messageKey, {
  AuraSnackBarVariant variant = .default_,
}) {
  if (!context.mounted) return;

  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(messageKey),
    variant: variant,
  );
}

class const _ConnectionStatusBadge({
  required final ServiceConnectionDisplayStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(.circular(6)),
      ),
      child: _ConnectionStatusBadgeText(status: status, color: color),
    );
  }

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return switch (status) {
      .connected => colors.primary,
      .expiringSoon => colors.tertiary,
      .expired => colors.error,
      .needsReauth => colors.error,
      .failed => colors.error,
      .unknown => colors.outline,
    };
  }
}

class const _ConnectionStatusBadgeText({
  required final ServiceConnectionDisplayStatus status,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      _statusLabel(context, status),
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: color, fontWeight: .w600),
    );
  }
}

class const _ConnectionMetadata({
  required final List<ServiceConnectionMetadataValue> values,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ServiceConnectionsScreen._tagSpacing,
      runSpacing: ServiceConnectionsScreen._tagSpacing,
      children: [
        for (final value in values) _ConnectionMetadataChip(value: value),
      ],
    );
  }
}

class const _ConnectionMetadataChip({
  required final ServiceConnectionMetadataValue value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(.circular(6)),
      ),
      constraints: const BoxConstraints(maxWidth: 520),
      child: _ConnectionMetadataChipText(value: value),
    );
  }
}

class const _ConnectionMetadataChipText({
  required final ServiceConnectionMetadataValue value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '${_metadataLabel(context, value.key)}: ${value.value}',
      style: Theme.of(context).textTheme.labelSmall,
      overflow: .ellipsis,
      maxLines: 2,
    );
  }
}

String _statusLabel(
  BuildContext context,
  ServiceConnectionDisplayStatus status,
) {
  final key = switch (status) {
    .connected => LocaleKeys.service_connections_status_connected,
    .expiringSoon => LocaleKeys.service_connections_status_expiring_soon,
    .expired => LocaleKeys.service_connections_status_expired,
    .needsReauth => LocaleKeys.service_connections_status_needs_reauth,
    .failed => LocaleKeys.service_connections_status_failed,
    .unknown => LocaleKeys.service_connections_status_unknown,
  };

  return key.tr(context: context);
}

String _metadataLabel(BuildContext context, ServiceConnectionMetadataKey key) {
  final localeKey = switch (key) {
    .issuer => LocaleKeys.service_connections_metadata_issuer,
    .clientId => LocaleKeys.service_connections_metadata_client_id,
    .scopes => LocaleKeys.service_connections_metadata_scopes,
    .expiresAt => LocaleKeys.service_connections_metadata_expires_at,
    .lastRefreshedAt =>
      LocaleKeys.service_connections_metadata_last_refreshed_at,
    .lastAuthError => LocaleKeys.service_connections_metadata_last_auth_error,
  };

  return localeKey.tr(context: context);
}
