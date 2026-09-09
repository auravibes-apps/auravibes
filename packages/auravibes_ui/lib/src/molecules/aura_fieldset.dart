part of 'aura_section.dart';

/// A section whose title acts as a form legend.
class AuraFieldset extends AuraSection {
  /// Creates a fieldset.
  const new({
    required super.title,
    required super.child,
    super.key,
    super.description,
  });
}
