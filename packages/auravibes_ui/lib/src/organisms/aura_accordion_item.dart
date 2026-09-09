part of 'aura_accordion.dart';

/// One locally navigable accordion item.
class AuraAccordionItem {
  /// Creates an accordion item.
  const new({required this.title, required this.child});

  /// Caller-localized title.
  final String title;

  /// Expanded content.
  final Widget child;
}
