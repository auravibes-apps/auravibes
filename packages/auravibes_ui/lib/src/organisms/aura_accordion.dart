import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';

part 'aura_accordion_item.dart';

/// Local expand/collapse navigation with no external side effects.
class AuraAccordion extends StatefulWidget {
  /// Creates an accordion.
  const new({
    required this.items,
    super.key,
    this.initiallyExpanded = const {},
  });

  /// Ordered local sections.
  final List<AuraAccordionItem> items;

  /// Initially expanded indexes.
  final Set<int> initiallyExpanded;

  @override
  State<AuraAccordion> createState() => _AuraAccordionState();
}

class _AuraAccordionState extends State<AuraAccordion> {
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _expanded.addAll(widget.initiallyExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final navigable = AuraInteractionScope.of(context).allowsNavigation;

    return Column(
      crossAxisAlignment: .stretch,
      children: widget.items.indexed
          .map((entry) {
            final (index, item) = entry;
            final isExpanded = _expanded.contains(index);

            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: .new(color: context.auraColors.outline)),
              ),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Semantics(
                    child: InkWell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.auraTheme.spacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AuraText(
                                child: Text(item.title),
                                style: .bodyLarge,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                      onTap: navigable
                          ? () => setState(() {
                              if (isExpanded) {
                                if (!_expanded.remove(index)) return;
                              } else if (!_expanded.add(index)) {
                                return;
                              }
                            })
                          : null,
                    ),
                    enabled: navigable,
                    button: true,
                    expanded: isExpanded,
                  ),
                  if (isExpanded)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: context.auraTheme.spacing.md,
                      ),
                      child: item.child,
                    ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
