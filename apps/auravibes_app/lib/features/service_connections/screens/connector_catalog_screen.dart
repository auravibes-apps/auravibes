import 'dart:async';

import 'package:auravibes_app/features/service_connections/models/connector_capability_filter.dart';
import 'package:auravibes_app/features/service_connections/models/connector_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_catalog_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ConnectorCatalogScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConnectorCatalogScreen> createState() =>
      _ConnectorCatalogScreenState();
}

class _ConnectorCatalogScreenState
    extends ConsumerState<ConnectorCatalogScreen> {
  ConnectorCapabilityFilter _filter = .all;

  @override
  Widget build(BuildContext context) {
    final provider = connectorCatalogProvider(
      widget.workspaceId,
      filter: _filter,
    );

    return _ConnectorCatalogPage(
      workspaceId: widget.workspaceId,
      filter: _filter,
      onFilterChanged: _updateFilter,
      catalog: ref.watch(provider),
      retry: _retry,
    );
  }

  void _updateFilter(ConnectorCapabilityFilter filter) =>
      setState(() => _filter = filter);

  void _retry() => ref.invalidate(
    connectorCatalogProvider(widget.workspaceId, filter: _filter),
  );
}

class const _ConnectorCatalogPage({
  required final String workspaceId,
  required final ConnectorCapabilityFilter filter,
  required final ValueChanged<ConnectorCapabilityFilter> onFilterChanged,
  required final AsyncValue<List<ConnectorCatalogItem>> catalog,
  required final VoidCallback retry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ConnectorCatalogFilter(value: filter, onChanged: onFilterChanged),
      Expanded(
        child: _ConnectorCatalogContent(
          workspaceId: workspaceId,
          catalog: catalog,
          retry: retry,
        ),
      ),
    ],
  );
}

class const _ConnectorCatalogContent({
  required final String workspaceId,
  required final AsyncValue<List<ConnectorCatalogItem>> catalog,
  required final VoidCallback retry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => catalog.when(
    data: (connectors) => _ConnectorCatalogResults(
      workspaceId: workspaceId,
      connectors: connectors,
    ),
    error: (_, _) => _ConnectorCatalogError(retry: retry),
    loading: () => const Center(child: AuraSpinner()),
  );
}

class const _ConnectorCatalogResults({
  required final String workspaceId,
  required final List<ConnectorCatalogItem> connectors,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => connectors.isEmpty
      ? const Center(child: TextLocale(LocaleKeys.connector_catalog_empty))
      : _ConnectorCatalogList(workspaceId: workspaceId, connectors: connectors);
}

class const _ConnectorCatalogError({required final VoidCallback retry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AuraColumn(
      children: [
        const TextLocale(LocaleKeys.service_connections_load_error),
        AuraButton(
          onPressed: retry,
          child: const TextLocale(LocaleKeys.route_state_retry),
        ),
      ],
      mainAxisAlignment: .center,
    ),
  );
}

class const _ConnectorCatalogFilter({
  required final ConnectorCapabilityFilter value,
  required final ValueChanged<ConnectorCapabilityFilter> onChanged,
}) extends StatelessWidget {
  static const List<AuraChoiceOption<ConnectorCapabilityFilter>> _options = [
    AuraChoiceOption(
      value: ConnectorCapabilityFilter.all,
      label: TextLocale(LocaleKeys.connector_catalog_filter_all),
    ),
    AuraChoiceOption(
      value: ConnectorCapabilityFilter.models,
      label: TextLocale(LocaleKeys.connector_catalog_filter_models),
    ),
    AuraChoiceOption(
      value: ConnectorCapabilityFilter.tools,
      label: TextLocale(LocaleKeys.connector_catalog_filter_tools),
    ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: AuraChoicePicker<ConnectorCapabilityFilter>(
      options: _options,
      value: [value],
      onChanged: (values) {
        if (values case [final filter]) onChanged(filter);
      },
      label: const TextLocale(LocaleKeys.connector_catalog_filter_label),
    ),
  );
}

class const _ConnectorCatalogList({
  required final String workspaceId,
  required final List<ConnectorCatalogItem> connectors,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemBuilder: (context, index) => _ConnectorCatalogCard(
      workspaceId: workspaceId,
      connector: connectors[index],
    ),
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemCount: connectors.length,
  );
}

class const _ConnectorCatalogCard({
  required final String workspaceId,
  required final ConnectorCatalogItem connector,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(
      children: [
        AuraText(child: Text(connector.name), style: .heading6),
        _ConnectorCapabilityTags(connector: connector),
        _ConnectorConnectionAction(
          workspaceId: workspaceId,
          connector: connector,
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: .stretch,
    ),
    style: .border,
  );
}

class const _ConnectorCapabilityTags({
  required final ConnectorCatalogItem connector,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    type: .transparency,
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (connector.offersModels)
          const Chip(
            label: TextLocale(LocaleKeys.connector_catalog_offers_models),
          ),
        if (connector.offersTools)
          const Chip(
            label: TextLocale(LocaleKeys.connector_catalog_offers_tools),
          ),
      ],
    ),
  );
}

class const _ConnectorConnectionAction({
  required final String workspaceId,
  required final ConnectorCatalogItem connector,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextLocale(
          connector.isConnected
              ? LocaleKeys.service_connections_status_connected
              : LocaleKeys.connector_catalog_not_connected,
        ),
      ),
      AuraButton(
        onPressed: () => _openConnectorAction(context, workspaceId, connector),
        child: TextLocale(
          connector.isConnected
              ? LocaleKeys.connector_catalog_manage
              : LocaleKeys.connector_catalog_connect,
        ),
      ),
    ],
  );
}

void _openConnectorAction(
  BuildContext context,
  String workspaceId,
  ConnectorCatalogItem connector,
) {
  if (connector.isConnected) {
    _openConnectedList(context, workspaceId);

    return;
  }

  _openConnectorCreate(context, workspaceId, connector);
}

void _openConnectedList(BuildContext context, String workspaceId) => unawaited(
  FeatureDestinations.push<void>(
    context,
    FeatureDestinations.connectionLocation(workspaceId, .overview),
  ),
);

void _openConnectorCreate(
  BuildContext context,
  String workspaceId,
  ConnectorCatalogItem connector,
) => unawaited(
  FeatureDestinations.push<void>(
    context,
    _connectorCreateLocation(workspaceId, connector),
  ),
);

String _connectorCreateLocation(
  String workspaceId,
  ConnectorCatalogItem connector,
) => ServiceConnectionCreateRoute(
  workspaceId: workspaceId,
  type: connector.offersModels ? 'modelProvider' : 'connector',
  connectorId: connector.offersModels ? null : connector.id,
  modelProviderId:
      connector.offersModels && connector.modelProviderIds.isNotEmpty
      ? connector.modelProviderIds.first
      : null,
).location;
