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
    return _AuraAccordionList(
      items: widget.items,
      expanded: _expanded,
      navigable: AuraInteractionScope.of(context).allowsNavigation,
      onToggle: _toggle,
    );
  }

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        if (!_expanded.remove(index)) return;
      } else {
        if (!_expanded.add(index)) return;
      }
    });
  }
}

class const _AuraAccordionList({
  required final List<AuraAccordionItem> items,
  required final Set<int> expanded,
  required final bool navigable,
  required final ValueChanged<int> onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      for (final (index, item) in items.indexed)
        _AccordionItemRow(
          item: item,
          isExpanded: expanded.contains(index),
          navigable: navigable,
          onTap: () => onToggle(index),
        ),
    ],
  );
}

class const _AccordionItemRow({
  required final AuraAccordionItem item,
  required final bool isExpanded,
  required final bool navigable,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: .new(color: context.auraColors.outline)),
    ),
    child: _AccordionItemBody(
      item: item,
      isExpanded: isExpanded,
      navigable: navigable,
      onTap: onTap,
    ),
  );
}

class const _AccordionItemBody({
  required final AuraAccordionItem item,
  required final bool isExpanded,
  required final bool navigable,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _AccordionItemHeader(
        title: item.title,
        isExpanded: isExpanded,
        navigable: navigable,
        onTap: onTap,
      ),
      if (isExpanded) _AccordionItemContent(child: item.child),
    ],
  );
}

class const _AccordionItemHeader({
  required final String title,
  required final bool isExpanded,
  required final bool navigable,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AccordionHeaderButton(
      title: title,
      isExpanded: isExpanded,
      navigable: navigable,
      onTap: onTap,
    ),
    enabled: navigable,
    button: true,
    expanded: isExpanded,
  );
}

class const _AccordionHeaderButton({
  required final String title,
  required final bool isExpanded,
  required final bool navigable,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => InkWell(
    child: _AccordionHeaderContent(title: title, isExpanded: isExpanded),
    onTap: navigable ? onTap : null,
  );
}

class const _AccordionHeaderContent({
  required final String title,
  required final bool isExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.auraTheme.spacing.sm),
    child: Row(
      children: [
        Expanded(
          child: AuraText(child: Text(title), style: .bodyLarge),
        ),
        _AccordionExpandIcon(isExpanded: isExpanded),
      ],
    ),
  );
}

class const _AccordionExpandIcon({required final bool isExpanded})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Icon(isExpanded ? Icons.expand_less : Icons.expand_more);
}

class const _AccordionItemContent({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.auraTheme.spacing.md),
    child: child,
  );
}
