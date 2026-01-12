import 'package:auravibes_ui/src/atoms/atoms.dart';
import 'package:auravibes_ui/src/organisms/auravibes_sidebar.dart';
import 'package:auravibes_ui/src/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// A bottom navigation bar component following the Aura design system.
///
/// This component provides navigation functionality for mobile interfaces,
/// displaying a horizontal row of navigation items with icons and labels.
/// It supports active/inactive states, touch interactions, and follows
/// the Aura design system styling patterns.
class AuraBottomBar extends StatelessWidget {
  /// Creates a Aura bottom bar.
  const AuraBottomBar({
    required this.navigationItems,
    required this.onNavigationTap,
    this.selectedIndex = 0,
    this.showLabels = true,
    super.key,
  });

  /// List of navigation items to display.
  final List<AuraNavigationData> navigationItems;

  /// Index of the currently selected navigation item.
  final int selectedIndex;

  /// Callback when a navigation item is tapped.
  final void Function(int value) onNavigationTap;

  /// Whether to show labels below icons.
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;

    return Container(
      decoration: BoxDecoration(
        color: auraColors.surface,
        border: Border(
          top: BorderSide(
            color: auraColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: auraColors.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _getBarHeight(auraTheme),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildItems(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    return navigationItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = index == selectedIndex;

      return Expanded(
        child: _AuraBottomBarItem(
          icon: item.icon,
          label: item.label,
          isSelected: isSelected,
          onTap: () => onNavigationTap(index),
          showLabel: showLabels,
        ),
      );
    }).toList();
  }

  double _getBarHeight(AuraTheme auraTheme) {
    if (showLabels) {
      return 80;
    }
    return 56;
  }
}

class _AuraBottomBarItem extends StatefulWidget {
  const _AuraBottomBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showLabel = true,
  });

  final Widget icon;
  final Widget label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  State<_AuraBottomBarItem> createState() => _AuraBottomBarItemState();
}

class _AuraBottomBarItemState extends State<_AuraBottomBarItem> {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;

    final iconColor = _getIconColor(auraColors);
    final textColor = _getTextColor(auraColors);

    return AuraPressable(
      padding: .small,
      color: auraColors.primary.withValues(alpha: 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(auraTheme.borderRadius.xl),
      ),
      onPressed: widget.onTap,
      child: AuraPadding(
        padding: AuraEdgeInsetsGeometry.small,
        child: AuraColumn(
          spacing: .xs,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                color: iconColor,
                size: 24,
              ),
              child: widget.icon,
            ),
            if (widget.showLabel)
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: auraTheme.typography.sizes.xs,
                  fontWeight: widget.isSelected
                      ? auraTheme.typography.weights.medium
                      : auraTheme.typography.weights.regular,
                  color: textColor,
                ),
                child: widget.label,
              ),
          ],
        ),
      ),
    );
  }

  Color _getIconColor(AuraColorScheme colors) {
    if (widget.isSelected) {
      return colors.primary;
    }
    return colors.onSurfaceVariant.withValues(alpha: 0.8);
  }

  Color _getTextColor(AuraColorScheme colors) {
    if (widget.isSelected) {
      return colors.primary;
    }
    return colors.onSurfaceVariant.withValues(alpha: 0.8);
  }
}
