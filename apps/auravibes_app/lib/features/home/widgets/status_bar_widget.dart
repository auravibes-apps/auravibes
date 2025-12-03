import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StatusBarWidget extends ConsumerWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraContainer(
      backgroundColor: context.auraColors.surfaceVariant,
      borderRadius: context.auraTheme.borderRadius.md,
      child: const AuraPadding(
        child: AuraRow(
          children: [
            // Model status
            Expanded(
              child: _ModelStatus(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelStatus extends ConsumerWidget {
  const _ModelStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(listCredentialsCredentialsProvider);

    return switch (modelsAsync) {
      AsyncData(value: final models) => () {
        final modelCount = models.length;
        return AuraRow(
          spacing: .sm,
          children: [
            AuraIcon(
              Icons.model_training_outlined,
              size: AuraIconSize.small,
              color: context.auraColors.success,
            ),
            AuraText(
              style: AuraTextStyle.bodySmall,
              child: Text(
                LocaleKeys.status_bar_models_available.plural(modelCount),
              ),
            ),
          ],
        );
      }(),
      AsyncLoading() => AuraRow(
        children: [
          const AuraSpinner(size: AuraSpinnerSize.small),
          AuraText(
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
            child: Text(LocaleKeys.status_bar_loading_models.tr()),
          ),
        ],
      ),
      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }
}
