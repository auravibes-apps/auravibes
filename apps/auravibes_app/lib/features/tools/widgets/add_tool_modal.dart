// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Modal for adding new tools to the workspace.
class const AddToolModal({required final String workspaceId, super.key})
    extends StatelessWidget {
  static const _iconSize = 40.0;

  /// Shows the add tool modal as a dialog.
  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddToolModal(workspaceId: workspaceId),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _AddToolModalContent(workspaceId: workspaceId);
}

class const _AddToolModalContent({required final String workspaceId})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _AddToolModalDialog(state: _useAddToolModalState(ref, workspaceId));
}

typedef _AddToolModalState = ({
  String workspaceId,
  TextEditingController searchController,
  String searchQuery,
  AsyncValue<List<UserToolType>> availableToolsAsync,
});

_AddToolModalState _useAddToolModalState(WidgetRef ref, String workspaceId) {
  final searchController = useTextEditingController();
  final searchQuery = _useAddToolSearchQuery(searchController);

  return (
    workspaceId: workspaceId,
    searchController: searchController,
    searchQuery: searchQuery.value,
    availableToolsAsync: ref.watch(availableToolsToAddProvider(workspaceId)),
  );
}

ValueNotifier<String> _useAddToolSearchQuery(TextEditingController controller) {
  final query = useState('');

  useEffect(() => _listenToSearchQuery(controller, query), [controller]);

  return query;
}

Dispose _listenToSearchQuery(
  TextEditingController controller,
  ValueNotifier<String> query,
) {
  void listener() => query.value = controller.text;
  controller.addListener(listener);

  return () => controller.removeListener(listener);
}

class const _AddToolModalDialog({required final _AddToolModalState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.xl)),
      ),
    ),
    child: _AddToolModalSurface(state: state),
  );
}

class const _AddToolModalSurface({required final _AddToolModalState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.sizeOf(context).width * 0.9,
    constraints: .new(
      maxWidth: 400,
      maxHeight: MediaQuery.sizeOf(context).height * 0.7,
    ),
    child: _AddToolModalColumn(state: state),
  );
}

class const _AddToolModalColumn({required final _AddToolModalState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const _AddToolModalHeader(),
      _AddToolModalSearch(controller: state.searchController),
      Flexible(child: _AddToolModalTools(state: state)),
      const AuraSizedBox(height: .md),
    ],
    mainAxisSize: .min,
  );
}

class _AddToolModalHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    decoration: BoxDecoration(
      border: Border(
        bottom: .new(color: context.auraColors.outline.withValues(alpha: 0.2)),
      ),
    ),
    child: const _AddToolModalHeaderContent(),
  );
}

class _AddToolModalHeaderContent extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _AddToolModalHeaderTitle(),
      Spacer(),
      _AddToolModalHeaderClose(),
    ],
  );
}

class const _AddToolModalHeaderTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale(LocaleKeys.tools_screen_add_tool_title),
    style: .heading6,
  );
}

class const _AddToolModalHeaderClose() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.close,
    onPressed: () => Navigator.of(context).pop(),
  );
}

class const _AddToolModalSearch({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: AuraInput(
      controller: controller,
      placeholder: const TextLocale(LocaleKeys.tools_screen_search_tools),
      prefixIcon: const AuraIcon(Icons.search),
      size: .small,
    ),
  );
}

class const _AddToolModalTools({required final _AddToolModalState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state.availableToolsAsync) {
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncData(:final value) => _AvailableToolsList(
      workspaceId: state.workspaceId,
      tools: value,
      searchQuery: state.searchQuery,
    ),
    AsyncError(:final error, :final stackTrace) => AppErrorWidget(
      error: error,
      stackTrace: stackTrace,
    ),
  };
}

class const _AvailableToolsList({
  required final String workspaceId,
  required final List<UserToolType> tools,
  required final String searchQuery,
}) extends StatelessWidget {
  List<UserToolType> get _filteredTools => searchQuery.isEmpty
      ? tools
      : tools
            .where(
              (tool) =>
                  tool.value.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    final filteredTools = _filteredTools;

    return filteredTools.isEmpty
        ? _EmptyToolsState(tools: tools)
        : _FilteredToolsList(tools: filteredTools, workspaceId: workspaceId);
  }
}

class const _EmptyToolsState({required final List<UserToolType> tools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final noTools = tools.isEmpty;

    return Padding(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.lg)),
      child: Center(child: _EmptyToolsContent(noTools: noTools)),
    );
  }
}

class const _EmptyToolsContent({required final bool noTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _EmptyToolsIcon(noTools: noTools),
      _EmptyToolsMessage(noTools: noTools),
    ],
    spacing: .sm,
    mainAxisSize: .min,
  );
}

class const _EmptyToolsIcon({required final bool noTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIcon(
    noTools ? Icons.check_circle_outline : Icons.search_off,
    size: .large,
  );
}

class const _EmptyToolsMessage({required final bool noTools})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: TextLocale(
      noTools
          ? LocaleKeys.tools_screen_all_tools_added
          : LocaleKeys.tools_screen_no_tools_found,
    ),
    textAlign: .center,
  );
}

class const _FilteredToolsList({
  required final List<UserToolType> tools,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: EdgeInsets.symmetric(
      horizontal: context.auraTheme.fromSpacing(.md),
    ),
    itemBuilder: _itemBuilder,
    separatorBuilder: _separatorBuilder,
    itemCount: tools.length,
  );

  Widget _itemBuilder(BuildContext _, int index) =>
      _AvailableToolTile(toolType: tools[index], workspaceId: workspaceId);

  Widget _separatorBuilder(BuildContext _, _) {
    return const AuraSizedBox(height: .sm);
  }
}

class const _AvailableToolTile({
  required final UserToolType toolType,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraTile(
    child: _AvailableToolTileContent(toolType: toolType),
    onTap: () => unawaited(_addTool(context, ref)),
    variant: .surface,
    leading: _AvailableToolIcon(toolType: toolType),
    trailing: const AuraIcon(Icons.add_circle_outline, tint: .primary),
  );
}

class const _AvailableToolTileContent({required final UserToolType toolType})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _AvailableToolName(toolType: toolType),
      _AvailableToolDescription(toolType: toolType),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _AvailableToolName({required final UserToolType toolType})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraText(child: toolType.getNameWidget());
}

class const _AvailableToolDescription({required final UserToolType toolType})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: DefaultTextStyle.merge(
      overflow: .ellipsis,
      maxLines: 2,
      child: toolType.getDescriptionWidget(),
    ),
    style: .bodySmall,
  );
}

class const _AvailableToolIcon({required final UserToolType toolType})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.auraColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.md)),
      ),
    ),
    width: AddToolModal._iconSize,
    height: AddToolModal._iconSize,
    child: toolType.getIconWidget(),
  );
}

extension on _AvailableToolTile {
  Future<void> _addTool(BuildContext context, WidgetRef ref) async {
    await ref
        .read(workspaceToolsProvider(workspaceId).notifier)
        .addTool(toolType);
    if (!context.mounted) return;

    Navigator.of(context).pop();
  }
}
