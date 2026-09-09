part of 'aura_key_value.dart';

/// A caller-localized display row.
class AuraKeyValueEntry {
  /// Creates one key/value row.
  const new({required this.label, required this.value});

  /// Visible key.
  final String label;

  /// Visible value.
  final String value;
}
