import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompactionFailedException', () {
    test('has correct locale key and recovery hint', () {
      const ex = CompactionFailedException();
      expect(ex.localeKey, LocaleKeys.compaction_errors_compaction_failed);
      expect(ex.recoveryHint, LocaleKeys.compaction_manual_failure);
      expect(ex.cause, isNull);
      expect(ex.toString(), contains('CompactionFailedException'));
    });

    test('accepts optional cause', () {
      final inner = Exception('inner');
      final ex = CompactionFailedException(cause: inner);
      expect(ex.cause, same(inner));
      expect(ex.toString(), contains('Caused by: $inner'));
    });
  });

  group('CompactionUnsafeException', () {
    test('has correct locale key', () {
      const ex = CompactionUnsafeException();
      expect(ex.localeKey, LocaleKeys.compaction_errors_compaction_unsafe);
      expect(ex.toString(), contains('CompactionUnsafeException'));
    });
  });

  group('CompactionUnavailableException', () {
    test('has correct locale key', () {
      const ex = CompactionUnavailableException();
      expect(
        ex.localeKey,
        LocaleKeys.compaction_errors_compaction_unavailable,
      );
    });
  });

  group('ContextOverflowRetryFailedException', () {
    test('has correct locale key', () {
      const ex = ContextOverflowRetryFailedException();
      expect(
        ex.localeKey,
        LocaleKeys.compaction_errors_context_overflow_retry_failed,
      );
    });
  });

  group('AutoCompactionBlockedException', () {
    test('has correct locale key', () {
      const ex = AutoCompactionBlockedException();
      expect(ex.localeKey, LocaleKeys.compaction_errors_auto_blocked);
    });
  });

  group('CompactionSettingsValidationException', () {
    test('uses custom locale key', () {
      const ex = CompactionSettingsValidationException(
        LocaleKeys.compaction_settings_validation_usage_range,
      );
      expect(
        ex.localeKey,
        LocaleKeys.compaction_settings_validation_usage_range,
      );
    });
  });
}
