import 'package:auravibes_app/i18n/locale_keys.dart';

abstract class CompactionException implements Exception {
  const CompactionException(this.localeKey, {this.recoveryHint, this.cause});

  final String localeKey;
  final String? recoveryHint;
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';
    return '$runtimeType: $localeKey$causedBy';
  }
}

class CompactionFailedException extends CompactionException {
  const CompactionFailedException({Exception? cause})
    : super(
        LocaleKeys.compaction_errors_compaction_failed,
        recoveryHint: LocaleKeys.compaction_manual_failure,
        cause: cause,
      );
}

class CompactionUnsafeException extends CompactionException {
  const CompactionUnsafeException()
    : super(
        LocaleKeys.compaction_errors_compaction_unsafe,
        recoveryHint: LocaleKeys.compaction_errors_compaction_unsafe,
      );
}

class CompactionUnavailableException extends CompactionException {
  const CompactionUnavailableException()
    : super(
        LocaleKeys.compaction_errors_compaction_unavailable,
        recoveryHint: LocaleKeys.compaction_errors_compaction_unavailable,
      );
}

class CompactionSettingsValidationException extends CompactionException {
  const CompactionSettingsValidationException(super.localeKey);
}
