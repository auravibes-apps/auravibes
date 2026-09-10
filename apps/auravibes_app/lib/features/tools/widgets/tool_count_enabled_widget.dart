// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ToolCountEnabledWidget({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ToolCountState(countAsync: _countAsync(ref));
  }

  AsyncValue<int> _countAsync(WidgetRef ref) => ref.watch(
    workspaceToolsProvider(workspaceId).select(
      (asyncValue) => asyncValue.whenData(
        (value) => value.where((e) => e.isAvailable).nonNulls.length,
      ),
    ),
  );
}

class const _ToolCountState({required final AsyncValue<int> countAsync})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (countAsync) {
      AsyncLoading() => const AuraSpinner(),

      AsyncData(value: final count) => _ToolCountText(count: count),

      AsyncError(:final error, :final stackTrace) => AppErrorWidget(
        error: error,
        stackTrace: stackTrace,
      ),
    };
  }
}

class const _ToolCountText({required final int count}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.tools_screen_enabled_count.plural(count),
      style: .new(
        color: context.auraColors.onSuccess,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
