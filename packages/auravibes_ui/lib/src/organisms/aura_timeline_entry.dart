part of 'aura_timeline.dart';

/// One read-only timeline entry.
class AuraTimelineEntry {
  /// Creates an entry.
  const new({
    required this.title,
    this.description,
    this.time,
    this.tint = AuraTint.primary,
  });

  /// Caller-localized title.
  final String title;

  /// Optional description.
  final String? description;

  /// Optional time label.
  final String? time;

  /// Entry marker tint.
  final AuraTint tint;

  /// Whether this entry contains supporting text.
  bool hasDetails() => description != null || time != null;
}
