// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_connections_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/models/widgets/list_model_connections_widget.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: AuraColumn(
        children: [
          _AddModelModalButton(workspaceId: workspaceId),
          Expanded(child: ListModelConnectionsWidget(workspaceId: workspaceId)),
        ],
      ),
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.models_screens_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _AddModelModalButton extends ConsumerWidget {
  const _AddModelModalButton({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraPadding(
      child: AppContent(
        child: Row(
          children: [
            Expanded(
              child: AuraButton(
                onPressed: () {
                  addCredentialsModelMutationProvider.reset(ref);
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignBorderRadius.xl,
                        ),
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: ctx.auraTheme.spacing.xl3 * 6,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(ctx.auraTheme.spacing.lg),
                          child: AddModelProviderWidget(
                            workspaceId: workspaceId,
                          ),
                        ),
                      ),
                    ),
                  ).then((onValue) {
                    ref.invalidate(
                      listWorkspaceModelConnectionsProvider(
                        workspaceId: workspaceId,
                      ),
                    );
                  });
                  // context.go(location)
                },
                child: const TextLocale(
                  LocaleKeys.models_screens_add_provider_open_button,
                ),
              ),
            ),
          ],
        ),
      ),
      padding: const .horizontal(.md),
    );
  }
}
