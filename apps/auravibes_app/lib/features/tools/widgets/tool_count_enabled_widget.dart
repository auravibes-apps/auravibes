// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ToolCountEnabledWidget extends ConsumerWidget {
  const ToolCountEnabledWidget({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(
      workspaceToolsProvider(workspaceId).select(
        (asyncValue) => asyncValue.whenData(
          (value) => value.where((e) => e.isAvailable).nonNulls.length,
        ),
      ),
    );
    return switch (countAsync) {
      AsyncLoading() => const AuraSpinner(),

      AsyncData(value: final count) => Text(
        LocaleKeys.tools_screen_enabled_count.plural(count),
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }
}
