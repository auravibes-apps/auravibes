import 'dart:ui' show SemanticsRole;

import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_container.dart';
import 'package:auravibes_ui/src/molecules/aura_divider.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A static set of selectable tabs with one child per tab.
class AuraTabs extends StatefulWidget {
  /// Creates Aura tabs.
  const AuraTabs({
    required this.items,
    super.key,
    this.initialIndex = 0,
    this.selectedIndex,
    this.onChanged,
  });

  /// The tab title widgets and content.
  final List<AuraTabItem> items;

  /// The initially selected tab for uncontrolled use.
  final int initialIndex;

  /// The selected tab for controlled use. This takes precedence over
  /// [initialIndex].
  final int? selectedIndex;

  /// Called when the selected tab changes.
  final ValueChanged<int>? onChanged;

  @override
  State<AuraTabs> createState() => _AuraTabsState();
}

class _AuraTabsState extends State<AuraTabs> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _normalizeIndex(
      widget.selectedIndex ?? widget.initialIndex,
      widget.items.length,
    );
  }

  @override
  void didUpdateWidget(covariant AuraTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    final requestedIndex =
        widget.selectedIndex ??
        (oldWidget.items.isEmpty ? widget.initialIndex : _selectedIndex);
    _selectedIndex = _normalizeIndex(requestedIndex, widget.items.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final selectedIndex = _normalizeIndex(
      widget.selectedIndex ?? _selectedIndex,
      widget.items.length,
    );

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < widget.items.length; index++)
                _buildTab(context, index, selectedIndex),
            ],
          ),
        ),
        const AuraDivider(height: 1, thickness: DesignBorderWidth.thin),
        Expanded(
          child: Semantics(
            child: AuraContainer(
              child: IndexedStack(
                index: selectedIndex,
                children: [for (final item in widget.items) item.child],
              ),
            ),
            role: SemanticsRole.tabPanel,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(BuildContext context, int index, int selectedIndex) {
    final item = widget.items[index];
    final isSelected = index == selectedIndex;
    final auraColors = context.auraColors;
    final borderRadius = context.auraTheme.fromBorderRadius(.md);

    return Semantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AuraPressable(
            child: AuraSizedBox(
              height: .xl2,
              child: AuraPadding(
                child: Center(
                  child: AuraText(
                    child: item.title,
                    style: AuraTextStyle.bodySmall,
                    tint: isSelected ? AuraTint.primary : null,
                  ),
                ),
                padding: const AuraEdgeInsetsGeometry.horizontal(.md),
              ),
            ),
            color: auraColors.primary,
            decoration: BoxDecoration(
              color: isSelected
                  ? auraColors.primary.withValues(alpha: 0.08)
                  : DesignColors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            ),
            onPressed: () => _select(index),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedContainer(
                key: ValueKey('aura-tabs-indicator-$index'),
                color: isSelected
                    ? auraColors.primary
                    : DesignColors.transparent,
                height: DesignBorderWidth.medium,
                duration: context.auraTheme.animation.normal,
              ),
            ),
          ),
        ],
      ),
      container: true,
      selected: isSelected,
      label: item.semanticLabel ?? _textSemanticLabel(item.title),
      onTap: () => _select(index),
      role: SemanticsRole.tab,
    );
  }

  void _select(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);
    widget.onChanged?.call(index);
  }

  int _normalizeIndex(int index, int length) {
    if (length == 0 || index < 0) return 0;
    if (index >= length) return length - 1;

    return index;
  }

  String? _textSemanticLabel(Widget title) {
    if (title is! Text) return null;

    return title.data ?? title.textSpan?.toPlainText();
  }
}

/// Defines one tab title widget and its static content.
class AuraTabItem {
  /// Creates a tab item.
  const AuraTabItem({
    required this.title,
    required this.child,
    this.semanticLabel,
  });

  /// The widget shown in the tab bar.
  final Widget title;

  /// The content shown when this tab is selected.
  final Widget child;

  /// An accessible label for title widgets that do not expose their own label.
  final String? semanticLabel;
}
