import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

abstract final class ManagementListFeedback {
  static const _failurePreviewLimit = 2;
  static const _failureNameLength = 24;

  static String selectionText(
    BuildContext context, {
    required int selectedCount,
    required int hiddenCount,
  }) {
    final selected = context.plural(
      LocaleKeys.common_selected_count,
      selectedCount,
    );
    if (hiddenCount == 0) return selected;

    final hidden = context.plural(
      LocaleKeys.common_hidden_selected_count,
      hiddenCount,
    );

    return '$selected\n$hidden';
  }

  static Widget confirmationMessage(
    BuildContext context,
    String messageKey, {
    required int selectedCount,
    required int hiddenCount,
  }) => hiddenCount == 0
      ? Text(messageKey.tr(context: context))
      : Text(
          _confirmationText(
            context,
            messageKey,
            selectedCount: selectedCount,
            hiddenCount: hiddenCount,
          ),
        );

  static Future<void> showFailuresDialog<T>({
    required BuildContext context,
    required List<T> failedItems,
    required String Function(T) nameOf,
    required Future<List<T>> Function(List<T>) onRetry,
  }) async {
    if (failedItems.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _ManagementListFailuresDialog<T>(
        failedItems: failedItems,
        nameOf: nameOf,
        onRetry: onRetry,
      ),
    );
  }

  static String failureText(
    BuildContext context,
    String key,
    List<String> failedNames,
  ) {
    final preview = _failurePreview(failedNames);
    final summary = _failureSummary(context, key, failedNames.length, preview);
    if (failedNames.length <= _failurePreviewLimit) return summary;

    final omitted = failedNames.length - _failurePreviewLimit;

    final additional = context.plural(
      LocaleKeys.common_additional_failures,
      omitted,
    );

    return '$summary$additional';
  }

  static String _confirmationText(
    BuildContext context,
    String messageKey, {
    required int selectedCount,
    required int hiddenCount,
  }) {
    final message = messageKey.tr(context: context);
    final selection = selectionText(
      context,
      selectedCount: selectedCount,
      hiddenCount: hiddenCount,
    );

    return '$message\n\n$selection';
  }

  static String _failurePreview(List<String> failedNames) => failedNames
      .take(_failurePreviewLimit)
      .map(
        (name) => name
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ')
            .truncateCharacters(_failureNameLength),
      )
      .join(', ');

  static String _failureSummary(
    BuildContext context,
    String key,
    int count,
    String preview,
  ) => context.plural(key, count, namedArgs: {'names': preview});
}

class const _ManagementListFailuresDialog<T>({
  required final List<T> failedItems,
  required final String Function(T) nameOf,
  required final Future<List<T>> Function(List<T>) onRetry,
}) extends StatefulWidget {
  @override
  State<_ManagementListFailuresDialog<T>> createState() =>
      _ManagementListFailuresDialogState<T>();
}

class _ManagementListFailuresDialogState<T>
    extends State<_ManagementListFailuresDialog<T>> {
  List<T>? _nextFailures;
  bool _isRetrying = false;

  List<T> get _failures => _nextFailures ?? widget.failedItems;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const _FailureDialogTitle(),
    content: _FailureDialogContent(failures: _failures, nameOf: widget.nameOf),
    actions: [
      _FailureDialogCloseButton(isRetrying: _isRetrying),
      _FailureDialogRetryButton(
        isRetrying: _isRetrying,
        onPressed: _startRetry,
      ),
    ],
  );

  void _startRetry() {
    setState(() => _isRetrying = true);
    unawaited(_retry());
  }

  Future<void> _retry() async {
    try {
      final failures = await widget.onRetry(.unmodifiable(_failures));
      if (!mounted) return;
      if (failures.isEmpty) {
        Navigator.of(context).pop();

        return;
      }
      setState(() => _nextFailures = failures);
    } on Object {
      // Keep the current items listed as failures for another retry.
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }
}

class const _FailureDialogTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(LocaleKeys.common_failed_items_title.tr(context: context));
}

class const _FailureDialogContent<T>({
  required final List<T> failures,
  required final String Function(T) nameOf,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: failures.map((item) => Text(nameOf(item))).toList(),
    ),
  );
}

class const _FailureDialogCloseButton({required final bool isRetrying})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: isRetrying ? null : () => Navigator.of(context).pop(),
    child: Text(LocaleKeys.common_close.tr(context: context)),
  );
}

class const _FailureDialogRetryButton({
  required final bool isRetrying,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: isRetrying ? null : onPressed,
    child: Text(LocaleKeys.common_retry_failed.tr(context: context)),
  );
}
