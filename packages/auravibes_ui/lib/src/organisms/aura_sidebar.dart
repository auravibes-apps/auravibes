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
  static const _shadowAlpha = 0.1;

  /// Creates a Aura sidebar organism.
  const new({
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
    return _AuraSidebarShell(
      isExpanded: isExpanded,
      navigationItems: navigationItems,
      selectedIndex: selectedIndex,
      onNavigationTap: onNavigationTap,
      header: header,
      middleSection: middleSection,
      footer: footer,
    );
  }
}

/// Represents a navigation item in the sidebar.
///
/// This can be reused across multiple navigation components like
/// [AuraSidebar].
class AuraNavigationData {
  /// Creates a navigation item.
  const new({
    required this.icon,
    required this.label,
    this.footer = false,
    this.semanticLabel,
  });

  /// Icon to display for the navigation item.
  final Widget icon;

  /// Label text for the navigation item.
  final Widget label;

  /// Whether this item belongs to the footer section.
  final bool footer;

  /// An accessibility label for this navigation item.
  final String? semanticLabel;

  /// Whether this item provides an accessibility label.
  bool hasSemanticLabel() => semanticLabel != null;
}

class const _AuraSidebarShell({
  required final bool isExpanded,
  required final List<AuraNavigationData> navigationItems,
  required final int selectedIndex,
  required final void Function(int value) onNavigationTap,
  final Widget? header,
  final Widget? middleSection,
  final Widget? footer,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _decoration(context),
      width: isExpanded ? 280 : 80,
      child: _AuraSidebarContent(
        navigationItems: navigationItems,
        selectedIndex: selectedIndex,
        onNavigationTap: onNavigationTap,
        isExpanded: isExpanded,
        header: header,
        middleSection: middleSection,
        footer: footer,
      ),
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    return BoxDecoration(
      color: context.auraColors.surface,
      border: BorderDirectional(end: .new(color: context.auraColors.outline)),
      boxShadow: [
        BoxShadow(
          color: context.auraColors.shadow.withValues(
            alpha: AuraSidebar._shadowAlpha,
          ),
          offset: const Offset(2, 0),
          blurRadius: 8,
        ),
      ],
    );
  }
}

class const _AuraSidebarContent({
  required final List<AuraNavigationData> navigationItems,
  required final int selectedIndex,
  required final void Function(int value) onNavigationTap,
  required final bool isExpanded,
  final Widget? header,
  final Widget? middleSection,
  final Widget? footer,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _AuraSidebarHeader(child: header),
      Expanded(
        child: _AuraSidebarBody(
          navigationItems: navigationItems,
          selectedIndex: selectedIndex,
          onNavigationTap: onNavigationTap,
          isExpanded: isExpanded,
          middleSection: middleSection,
        ),
      ),
      _AuraSidebarFooterNavigation(
        navigationItems: navigationItems,
        selectedIndex: selectedIndex,
        onNavigationTap: onNavigationTap,
        isExpanded: isExpanded,
      ),
      if (footer case final value?) _AuraSidebarFooter(child: value),
    ],
  );
}

class const _AuraSidebarFooterNavigation({
  required final List<AuraNavigationData> navigationItems,
  required final int selectedIndex,
  required final void Function(int value) onNavigationTap,
  required final bool isExpanded,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: _AuraSidebarNavigation(
      navigationItems: navigationItems,
      selectedIndex: selectedIndex,
      onNavigationTap: onNavigationTap,
      isExpanded: isExpanded,
      footer: true,
    ),
  );
}

class const _AuraSidebarHeader({required final Widget? child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      child ?? const AuraSizedBox(height: .lg);
}

class const _AuraSidebarBody({
  required final List<AuraNavigationData> navigationItems,
  required final int selectedIndex,
  required final void Function(int value) onNavigationTap,
  required final bool isExpanded,
  final Widget? middleSection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _AuraSidebarNavigation(
          navigationItems: navigationItems,
          selectedIndex: selectedIndex,
          onNavigationTap: onNavigationTap,
          isExpanded: isExpanded,
        ),
        ?middleSection,
      ],
    );
  }
}

class const _AuraSidebarFooter({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.auraTheme.fromSpacing(.sm)),
      child: child,
    );
  }
}

class const _AuraSidebarNavigation({
  required final List<AuraNavigationData> navigationItems,
  required final int selectedIndex,
  required final void Function(int value) onNavigationTap,
  required final bool isExpanded,
  final bool footer = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        navigationItems.length,
        _buildNavigationItem,
      ).whereType<Widget>().toList(),
    );
  }

  Widget? _buildNavigationItem(int index) {
    final item = navigationItems[index];
    if (item.footer != footer) return null;

    return AuraPadding(
      padding: const .symmetric(horizontal: .sm, vertical: .xs),
      child: _AuraSidebarItem(
        item: item,
        isExpanded: isExpanded,
        onTap: () => onNavigationTap(index),
        selected: index == selectedIndex,
      ),
    );
  }
}

class const _AuraSidebarItem({
  required final AuraNavigationData item,
  required final bool isExpanded,
  required final VoidCallback onTap,
  final bool selected = false,
}) extends StatelessWidget {
  static const _selectedAlpha = 0.1;

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return AuraPressable(
      child: _AuraSidebarItemContent(
        icon: item.icon,
        label: isExpanded ? item.label : const SizedBox.shrink(),
        selected: selected,
      ),
      color: colors.primary,
      decoration: _decoration(context),
      onPressed: onTap,
      semanticLabel: item.semanticLabel ?? 'Navigation item',
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    final colors = context.auraColors;

    return BoxDecoration(
      color: selected ? colors.primary.withValues(alpha: _selectedAlpha) : null,
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.xl)),
      ),
    );
  }
}

class const _AuraSidebarItemContent({
  required final Widget icon,
  required final Widget label,
  required final bool selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPadding(
      child: AuraText(
        child: AuraRow(children: [icon, label], spacing: .sm),
        tint: selected ? AuraTint.primary : null,
      ),
      padding: .small,
    );
  }
}
