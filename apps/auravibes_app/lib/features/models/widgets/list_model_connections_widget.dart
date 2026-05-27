// ignore_for_file: avoid-returning-widgets
// Required: Existing helper builders return widgets.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
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
          return _buildEmptyState();
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
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
          itemCount: workspaceModelSelections.length,
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: AuraColumn(
          children: [
            AuraIcon(
              Icons.model_training_outlined,
              size: AuraIconSize.extraLarge,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            AuraText(
              child: TextLocale(
                LocaleKeys.models_screens_list_empty_title,
              ),
              style: AuraTextStyle.heading3,
            ),
            AuraText(
              child: TextLocale(
                LocaleKeys.models_screens_list_empty_subtitle,
              ),
              textAlign: TextAlign.center,
              color: AuraColorVariant.onSurfaceVariant,
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
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
                      child: Text(workspaceModelSelection.name),
                      style: AuraTextStyle.heading6,
                    ),
                    const SizedBox(height: 4),
                    AuraText(
                      child: Text(_getModelTypeDisplay()),
                      style: AuraTextStyle.bodySmall,
                    ),
                  ],
                ),
              ),
              AuraPopupMenu(
                child: AuraIconButton(
                  icon: Icons.more_vert,
                  onPressed: menuController.toggle,
                ),
                items: [
                  AuraPopupMenuItem(
                    title: const TextLocale(LocaleKeys.common_delete),
                    onTap: () =>
                        _confirmDelete(context, ref, workspaceModelSelection),
                    leading: const AuraIcon(Icons.delete),
                    variant: .error,
                  ),
                ],
                controller: menuController,
              ),
            ],
          ),
          if (workspaceModelSelection.url != null) ...[
            const SizedBox(height: 12),
            AuraText(
              child: Text(
                LocaleKeys.models_screens_list_url_label.tr(
                  args: [workspaceModelSelection.url!],
                  context: context,
                ),
              ),
              style: AuraTextStyle.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          AuraText(
            child: Text(
              LocaleKeys.models_screens_list_api_key_label.tr(
                args: [_obscureApiKey(workspaceModelSelection.keySuffix)],
                context: context,
              ),
            ),
            style: AuraTextStyle.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildModelTypeIcon(BuildContext context) {
    return SvgPicture.network(
      'https://models.dev/logos/${workspaceModelSelection.modelId}.svg',
      width: 30,
      height: 30,
      placeholderBuilder: (context) => const CircularProgressIndicator(),
      colorFilter: ColorFilter.mode(
        context.auraColors.onBackground,
        BlendMode.srcIn,
      ), // Optional: specify width
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
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_delete),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
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
