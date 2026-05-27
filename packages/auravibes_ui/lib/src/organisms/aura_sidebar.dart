// ignore_for_file: avoid-returning-widgets
// Required: Existing helper builders return widgets.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

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
          if (header != null)
            _buildHeaderSection()
          else
            SizedBox(height: context.auraTheme.spacing.lg),
          Expanded(
            child: ListView(
              children: [
                _buildNavigationItems(),
                ?middleSection,
              ],
            ),
          ),
          SafeArea(
            top: false,
            right: false,
            child: _buildNavigationItems(footer: true),
          ),

          if (footer != null) _buildFooterSection(context),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return header!;
  }

  Widget _buildNavigationItems({
    bool footer = false,
  }) {
    return Column(
      children: List.generate(navigationItems.length, (currentIndex) {
        final item = navigationItems[currentIndex];
        if (item.footer != footer) return null;
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
  }

  Widget _buildFooterSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.auraTheme.spacing.sm),
      child: footer,
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

  /// copy with
  AuraNavigationData copyWith({
    Widget? icon,
    Widget? label,
    bool? footer,
  }) {
    return AuraNavigationData(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      footer: footer ?? this.footer,
    );
  }
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
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.xl),
      ),
      onPressed: onTap,
    );
  }
}
