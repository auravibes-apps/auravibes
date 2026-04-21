import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_connections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ListModelConnectionsWidget extends ConsumerWidget {
  const ListModelConnectionsWidget({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceModelSelectionsAsync = ref.watch(
      listWorkspaceModelConnectionsProvider(workspaceId: workspaceId),
    );

    return switch (workspaceModelSelectionsAsync) {
      AsyncData(value: final workspaceModelSelections) => () {
        if (workspaceModelSelections.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workspaceModelSelections.length,
          shrinkWrap: true,
          // separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final workspaceModelSelection = workspaceModelSelections[index];
            return _ModelConnectionCard(
              workspaceModelSelection: workspaceModelSelection,
              workspaceId: workspaceId,
            );
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: context.auraTheme.spacing.md);
          },
        );
      }(),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError(:final error, stackTrace: _) => AuraText(
        child: Text(
          LocaleKeys.models_screens_list_error.tr(
            args: ['$error'],
            context: context,
          ),
        ),
      ),
    };
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: AuraColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuraIcon(
              Icons.model_training_outlined,
              size: AuraIconSize.extraLarge,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            AuraText(
              style: AuraTextStyle.heading3,
              child: TextLocale(
                LocaleKeys.models_screens_list_empty_title,
              ),
            ),
            AuraText(
              // TODO: color: Colors.grey,
              textAlign: TextAlign.center,
              child: TextLocale(
                LocaleKeys.models_screens_list_empty_subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelConnectionCard extends ConsumerWidget {
  const _ModelConnectionCard({
    required this.workspaceModelSelection,
    required this.workspaceId,
  });

  final ModelConnectionEntity workspaceModelSelection;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuController = AuraPopupMenuController();

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildModelTypeIcon(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuraText(
                      style: AuraTextStyle.heading6,
                      child: Text(workspaceModelSelection.name),
                    ),
                    const SizedBox(height: 4),
                    AuraText(
                      style: AuraTextStyle.bodySmall,

                      child: Text(_getModelTypeDisplay()),
                    ),
                  ],
                ),
              ),
              AuraPopupMenu(
                controller: menuController,
                items: [
                  AuraPopupMenuItem(
                    title: const TextLocale(LocaleKeys.common_delete),
                    leading: const AuraIcon(Icons.delete),
                    onTap: () =>
                        _confirmDelete(context, ref, workspaceModelSelection),
                    variant: .error,
                  ),
                ],
                child: AuraIconButton(
                  icon: Icons.more_vert,
                  onPressed: menuController.toggle,
                ),
              ),
            ],
          ),
          if (workspaceModelSelection.url != null) ...[
            const SizedBox(height: 12),
            AuraText(
              style: AuraTextStyle.bodySmall,

              child: Text(
                LocaleKeys.models_screens_list_url_label.tr(
                  args: [workspaceModelSelection.url!],
                  context: context,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AuraText(
            style: AuraTextStyle.bodySmall,
            child: Text(
              LocaleKeys.models_screens_list_api_key_label.tr(
                args: [_obscureApiKey(workspaceModelSelection.keySuffix)],
                context: context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTypeIcon(BuildContext context) {
    return SvgPicture.network(
      'https://models.dev/logos/${workspaceModelSelection.modelId}.svg',
      placeholderBuilder: (context) =>
          const CircularProgressIndicator(), // Optional: show a loading
      // indicator
      colorFilter: ColorFilter.mode(
        context.auraColors.onBackground,
        BlendMode.srcIn,
      ),
      height: 30, // Optional: specify height
      width: 30, // Optional: specify width
    );
  }

  String _getModelTypeDisplay() {
    return workspaceModelSelection.modelId;
  }

  String _obscureApiKey(String? keySuffix) {
    if (keySuffix == null || keySuffix.isEmpty) {
      return '*' * 20;
    }
    return '********************$keySuffix';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ModelConnectionEntity modelConnection,
  ) async {
    final confirmed = await showAuraConfirmDialog(
      context: context,
      title: const TextLocale(LocaleKeys.models_screens_list_delete_title),
      message: Text(
        LocaleKeys.models_screens_list_delete_confirm.tr(
          namedArgs: {'name': modelConnection.name},
          context: context,
        ),
      ),
      confirmLabel: const TextLocale(LocaleKeys.common_delete),
      cancelLabel: const TextLocale(LocaleKeys.common_cancel),
      isDestructive: true,
    );

    if (confirmed ?? false) {
      await ref
          .read(modelConnectionRepositoryProvider)
          .deleteModelConnection(modelConnection.id);
      ref.invalidate(
        listWorkspaceModelConnectionsProvider(workspaceId: workspaceId),
      );
    }
  }
}
