import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ToolCountEnabledWidget extends ConsumerWidget {
  const ToolCountEnabledWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(
      workspaceToolsProvider.select(
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
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }
}
