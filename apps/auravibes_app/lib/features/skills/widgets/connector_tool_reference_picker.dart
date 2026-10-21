import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_tool_catalog_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _ConnectorToolSelectionCallback = void Function({
  required String id,
  required bool selected,
});

class const ConnectorToolReferencePicker({
  required final Set<String> selectedToolIds,
  required final ValueChanged<Set<String>> onChanged,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ConnectorToolReferencePickerContent(
      catalog: ref.watch(connectorToolCatalogProvider),
      selectedToolIds: selectedToolIds,
      onChanged: onChanged,
    );
  }
}

class const _ConnectorToolReferencePickerContent({
  required final List<ConnectorToolCatalogItem> catalog,
  required final Set<String> selectedToolIds,
  required final ValueChanged<Set<String>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selected = selectedToolIds.toList()..sort();

    return Column(
      crossAxisAlignment: .start,
      children: [
        const TextLocale(LocaleKeys.skills_screen_connector_tools_label),
        const SizedBox(height: 4),
        const TextLocale(LocaleKeys.skills_screen_connector_tools_hint),
        const SizedBox(height: 8),
        _SelectedConnectorToolLabels(
          catalog: catalog,
          selectedToolIds: selected,
        ),
        const SizedBox(height: 8),
        _SelectConnectorToolsButton(
          catalog: catalog,
          selectedToolIds: selectedToolIds,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class const _SelectedConnectorToolLabels({
  required final List<ConnectorToolCatalogItem> catalog,
  required final List<String> selectedToolIds,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (selectedToolIds.isEmpty) {
      return const TextLocale(LocaleKeys.skills_screen_connector_tools_empty);
    }

    final itemsById = {for (final item in catalog) item.toolId: item};

    return Column(
      crossAxisAlignment: .start,
      children: [
        for (final id in selectedToolIds) Text(_displayName(itemsById[id], id)),
      ],
    );
  }
}

class const _SelectConnectorToolsButton({
  required final List<ConnectorToolCatalogItem> catalog,
  required final Set<String> selectedToolIds,
  required final ValueChanged<Set<String>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => _selectTools(
      context: context,
      catalog: catalog,
      selectedToolIds: selectedToolIds,
      onChanged: onChanged,
    ),
    child: const TextLocale(LocaleKeys.skills_screen_connector_tools_select),
    variant: .outlined,
  );
}

Future<void> _selectTools({
  required BuildContext context,
  required List<ConnectorToolCatalogItem> catalog,
  required Set<String> selectedToolIds,
  required ValueChanged<Set<String>> onChanged,
}) async {
  final result = await showDialog<Set<String>>(
    context: context,
    builder: (_) => _ConnectorToolPickerDialog(
      catalog: catalog,
      selectedToolIds: selectedToolIds,
    ),
  );
  if (result != null) onChanged(result);
}

class const _ConnectorToolPickerDialog({
  required final List<ConnectorToolCatalogItem> catalog,
  required final Set<String> selectedToolIds,
}) extends StatefulWidget {
  @override
  State<_ConnectorToolPickerDialog> createState() =>
      _ConnectorToolPickerDialogState();
}

class _ConnectorToolPickerDialogState
    extends State<_ConnectorToolPickerDialog> {
  Set<String> _selectedToolIds = {};

  @override
  void initState() {
    super.initState();
    _selectedToolIds = .of(widget.selectedToolIds);
  }

  @override
  Widget build(BuildContext context) {
    final items = _connectorToolPickerItems(widget.catalog, _selectedToolIds);

    return AlertDialog(
      title: const TextLocale(
        LocaleKeys.skills_screen_connector_tools_dialog_title,
      ),
      content: _ConnectorToolPickerContent(
        items: items,
        selectedToolIds: _selectedToolIds,
        onChanged: _setSelected,
      ),
      actions: _ConnectorToolPickerDialogActions.forSelection(
        context,
        _selectedToolIds,
      ),
    );
  }

  void _setSelected({required String id, required bool selected}) {
    if (_selectedToolIds.contains(id) == selected) return;
    setState(() {
      _selectedToolIds = selected
          ? {..._selectedToolIds, id}
          : _selectedToolIds.where((toolId) => toolId != id).toSet();
    });
  }
}

List<ConnectorToolCatalogItem> _connectorToolPickerItems(
  List<ConnectorToolCatalogItem> catalog,
  Set<String> selectedToolIds,
) {
  final catalogById = {for (final item in catalog) item.toolId: item};

  return [
    ...catalog,
    for (final id in selectedToolIds)
      if (!catalogById.containsKey(id))
        ConnectorToolCatalogItem(
          toolId: id,
          connectorName: '',
          title: id,
          description: '',
        ),
  ]..sort(_compareToolItems);
}

abstract final class _ConnectorToolPickerDialogActions {
  static List<Widget> forSelection(
    BuildContext context,
    Set<String> selectedToolIds,
  ) => [
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const TextLocale(LocaleKeys.common_cancel),
    ),
    TextButton(
      onPressed: () => Navigator.of(context).pop(Set.of(selectedToolIds)),
      child: const TextLocale(LocaleKeys.skills_screen_connector_tools_apply),
    ),
  ];
}

class const _ConnectorToolPickerContent({
  required final List<ConnectorToolCatalogItem> items,
  required final Set<String> selectedToolIds,
  required final _ConnectorToolSelectionCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 440,
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        const TextLocale(LocaleKeys.skills_screen_connector_tools_hint),
        const SizedBox(height: 8),
        Flexible(
          child: _ConnectorToolPickerItems(
            items: items,
            selectedToolIds: selectedToolIds,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

class const _ConnectorToolPickerItems({
  required final List<ConnectorToolCatalogItem> items,
  required final Set<String> selectedToolIds,
  required final _ConnectorToolSelectionCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const TextLocale(LocaleKeys.skills_screen_connector_tools_empty);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        children: [
          for (final item in items)
            _ConnectorToolPickerOption(
              item: item,
              selected: selectedToolIds.contains(item.toolId),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class const _ConnectorToolPickerOption({
  required final ConnectorToolCatalogItem item,
  required final bool selected,
  required final _ConnectorToolSelectionCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = _displayName(item, item.toolId);

    return AuraCheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(id: item.toolId, selected: value),
      title: Text(label),
      subtitle: item.description.isEmpty ? null : Text(item.description),
      semanticLabel: label,
    );
  }
}

String _displayName(ConnectorToolCatalogItem? item, String fallback) {
  if (item == null || item.connectorName.isEmpty) return fallback;

  return '${item.connectorName}: ${item.title}';
}

int _compareToolItems(
  ConnectorToolCatalogItem left,
  ConnectorToolCatalogItem right,
) {
  final connectorOrder = left.connectorName.compareTo(right.connectorName);

  return connectorOrder == 0
      ? left.title.compareTo(right.title)
      : connectorOrder;
}
