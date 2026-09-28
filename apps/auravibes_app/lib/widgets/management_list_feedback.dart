import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
