// Required: Existing test and UI helpers keep compact return flow.
// Required: Component callbacks stay colocated with UI state.
// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/atoms/atoms.dart';
import 'package:auravibes_ui/src/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// A generic sidebar organism component that provides navigation functionality.
///
/// This component handles the visual presentation of the sidebar including
/// customizable header, navigation items, and footer sections. It is designed
/// to be a pure UI component that receives all necessary data and callbacks.
class AuraSidebar extends StatelessWidget {
  /// Creates a Aura sidebar organism.
  const AuraSidebar({
    required this.navigationItems,
    required this.onNavigationTap,
    this.isExpanded = true,
    this.selectedIndex = 0,
    this.header,
    this.middleSection,
    this.footer,
    super.key,
  });

  /// Whether the sidebar is currently expanded.
  final bool isExpanded;

  /// List of navigation items to display.
  final List<AuraNavigationData> navigationItems;

  /// Index of the currently selected navigation item.
  final int selectedIndex;

  /// Callback when a navigation item is tapped.
  final void Function(int value) onNavigationTap;

  /// Optional header widget to display at the top of the sidebar.
  final Widget? header;

  /// Optional middle section widget to display between
  /// main navigation and footer.
  final Widget? middleSection;

  /// Optional footer widget to display at the bottom of the sidebar.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final footer = this.footer;
    final navigation = Column(
      children: List.generate(navigationItems.length, (currentIndex) {
        final item = navigationItems[currentIndex];
        if (item.footer) return null;

        return AuraPadding(
          child: _AuraSidebarItem(
            label: isExpanded ? item.label : const SizedBox.shrink(),
            icon: item.icon,
            onTap: () => onNavigationTap(currentIndex),
            selected: currentIndex == selectedIndex,
          ),
          padding: const .symmetric(
            horizontal: .sm,
            vertical: .xs,
          ),
        );
      }).whereType<Widget>().toList(),
    );
    final footerNavigation = Column(
      children: List.generate(navigationItems.length, (currentIndex) {
        final item = navigationItems[currentIndex];
        if (!item.footer) return null;

        return AuraPadding(
          child: _AuraSidebarItem(
            label: isExpanded ? item.label : const SizedBox.shrink(),
            icon: item.icon,
            onTap: () => onNavigationTap(currentIndex),
            selected: currentIndex == selectedIndex,
          ),
          padding: const .symmetric(
            horizontal: .sm,
            vertical: .xs,
          ),
        );
      }).whereType<Widget>().toList(),
    );

    return Container(
      decoration: BoxDecoration(
        color: context.auraColors.surface,
        border: Border(
          right: BorderSide(
            color: context.auraColors.outline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: context.auraColors.shadow.withValues(alpha: 0.1),
            offset: const Offset(2, 0),
            blurRadius: 8,
          ),
        ],
      ),
      width: isExpanded ? 280 : 80,
      child: Column(
        children: [
          if (header != null) header else const AuraSizedBox(height: .lg),
          Expanded(
            child: ListView(
              children: [
                navigation,
                ?middleSection,
              ],
            ),
          ),
          SafeArea(
            top: false,
            right: false,
            child: footerNavigation,
          ),

          if (footer != null)
            Padding(
              padding: EdgeInsets.all(
                context.auraTheme.fromSpacing(.sm),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// Represents a navigation item in the sidebar.
///
/// This can be reused across multiple navigation components like
/// [AuraSidebar].
class AuraNavigationData {
  /// Creates a navigation item.
  const AuraNavigationData({
    required this.icon,
    required this.label,
    this.footer = false,
  });

  /// Icon to display for the navigation item.
  final Widget icon;

  /// Label text for the navigation item.
  final Widget label;

  /// Whether this item belongs to the footer section.
  final bool footer;
}

class _AuraSidebarItem extends StatelessWidget {
  const _AuraSidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final Widget label;

  final Widget icon;

  final bool selected;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return AuraPressable(
      child: AuraPadding(
        child: AuraText(
          child: AuraRow(children: [icon, label], spacing: .sm),
          color: selected ? .primary : null,
        ),
        padding: .small,
      ),
      color: colors.primary.withValues(alpha: 0.8),
      decoration: BoxDecoration(
        color: selected ? colors.primary.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.all(
          Radius.circular(
            context.auraTheme.fromBorderRadius(.xl),
          ),
        ),
      ),
      onPressed: onTap,
    );
  }
}
