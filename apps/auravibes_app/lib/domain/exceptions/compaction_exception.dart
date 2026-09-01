// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/i18n/locale_keys.dart';

abstract class const CompactionException(
  final String localeKey, {
  final String? recoveryHint,
  final Exception? cause,
}) implements Exception {
  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';

    return '$runtimeType: $localeKey$causedBy';
  }
}

class const CompactionFailedException({super.cause})
    extends CompactionException {
  // Cause is absent for user-triggered failures.
  // ignore: unnecessary-nullable
  this
    : super(
        LocaleKeys.compaction_errors_compaction_failed,
        recoveryHint: LocaleKeys.compaction_manual_failure,
      );
}

class const CompactionUnsafeException() extends CompactionException {
  this
    : super(
        LocaleKeys.compaction_errors_compaction_unsafe,
        recoveryHint: LocaleKeys.compaction_errors_compaction_unsafe,
      );
}

class const CompactionUnavailableException() extends CompactionException {
  this
    : super(
        LocaleKeys.compaction_errors_compaction_unavailable,
        recoveryHint: LocaleKeys.compaction_errors_compaction_unavailable,
      );
}

class const CompactionSettingsValidationException(super.localeKey)
    extends CompactionException;
