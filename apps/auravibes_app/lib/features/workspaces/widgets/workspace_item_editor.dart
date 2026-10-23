import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemEditor({
  required final String workspaceId,
  required final String name,
  required final String? parentId,
  required final String? parentName,
  required final Future<void> Function(String, String?) onSave,
  required final VoidCallback onBack,
  final String? excludedFolderId,
  super.key,
}) extends StatefulWidget {
  @override
  State<WorkspaceItemEditor> createState() => _WorkspaceItemEditorState();
}

class _WorkspaceItemEditorState extends State<WorkspaceItemEditor> {
  late final TextEditingController _name;
  late String? _destination;
  late String? _destinationName;
  bool _pending = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final editor = widget;
    _name = TextEditingController(text: editor.name);
    _destination = editor.parentId;
    _destinationName = editor.parentName;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [_header(), _nameInput(), ..._destinationWidgets(), ..._actions()],
  );

  Widget _header() => ListTile(
    leading: const Icon(Icons.arrow_back),
    title: const TextLocale(LocaleKeys.workspace_items_edit_item),
    onTap: _pending ? null : widget.onBack,
  );

  Widget _nameInput() => AuraInput(
    controller: _name,
    label: const TextLocale(LocaleKeys.workspace_items_item_name),
    enabled: !_pending,
    identifier: 'workspace_item_name',
  );

  List<Widget> _destinationWidgets() => [
    const TextLocale(LocaleKeys.workspace_items_destination),
    if (_destinationName case final current?) Text(current),
    _Destinations(workspaceId: widget.workspaceId, parentId: _destination,
      excludedId: widget.excludedFolderId, enabled: !_pending,
      onChanged: _changeDestination),
  ];

  void _changeDestination(WorkspaceFolder? folder) => setState(() {
    _destination = folder?.id;
    _destinationName = folder?.name;
  });

  List<Widget> _actions() => [
    if (_error case final failure?) WorkspaceItemFailure(error: failure),
    AuraButton(onPressed: () => unawaited(_save()), isLoading: _pending,
      disabled: _pending, identifier: 'workspace_item_save',
      child: const TextLocale(LocaleKeys.common_save)),
    AuraButton(onPressed: widget.onBack, disabled: _pending,
      child: const TextLocale(LocaleKeys.common_cancel)),
  ];

  Future<void> _save() async {
    if (_pending) return;
    _saving(true);
    try {
      await widget.onSave(_name.text, _destination);
      if (mounted) widget.onBack();
    } on Object catch (failure) {
      if (mounted) setState(() => _error = failure);
    } finally {
      _saving(false);
    }
  }

  void _saving(bool value) {
    if (!mounted) return;
    setState(() {
      _pending = value;
      if (value) _error = null;
    });
  }
}

class const _Destinations({
  required final String workspaceId,
  required final String? parentId,
  required final String? excludedId,
  required final bool enabled,
  required final ValueChanged<WorkspaceFolder?> onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(workspaceFoldersProvider(workspaceId, parentId));

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const TextLocale(LocaleKeys.workspace_items_root),
          onTap: enabled ? () => onChanged(null) : null,
        ),
        switch (folders) {
          AsyncData(:final value) => Column(
            children: [
              for (final folder in value)
                if (folder.id != excludedId)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.name),
                    onTap: enabled ? () => onChanged(folder) : null,
                  ),
            ],
          ),
          AsyncError(:final error) => WorkspaceItemFailure(error: error),
          AsyncLoading() => const CircularProgressIndicator(),
        },
      ],
    );
  }
}
