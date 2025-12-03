import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/atoms/auravibes_pressable.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/molecules/auravibes_dropdown_option.dart';
import 'package:auravibes_ui/src/organisms/auravibes_field_wrapper.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';

/// A customizable dropdown selector component following the Aura design system.
///
/// This selector provides a dropdown interface with consistent styling,
/// search functionality, and keyboard navigation.
class AuraDropdownSelector<T> extends StatefulWidget {
  /// Creates a Aura dropdown selector.
  const AuraDropdownSelector({
    required this.options,
    super.key,
    this.value,
    this.onChanged,
    this.placeholder,
    this.label,
    this.hint,
    this.error,
    this.header,
    this.footer,
    this.isRequired = false,
    this.isEnabled = true,
    this.focusNode,
    this.semanticLabel,
    this.optionBuilder,
  });

  /// The list of options to display in the dropdown.
  final List<AuraDropdownOption<T>> options;

  /// The currently selected value.
  final T? value;

  /// Callback when the selection changes.
  final ValueChanged<T?>? onChanged;

  /// Placeholder text to display when no value is selected.
  final Widget? placeholder;

  /// Optional label text to display above the field.
  final Widget? label;

  /// Optional hint text to display below the field.
  final Widget? hint;

  /// Optional error text to display below the field.
  final Widget? error;

  /// optional header for dropdown
  final Widget? header;

  /// optional footer for dropdown
  final Widget? footer;

  /// Whether the field is required.
  final bool isRequired;

  /// Whether the dropdown is enabled.
  final bool isEnabled;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  /// A semantic label for accessibility.
  final String? semanticLabel;

  /// Optional custom builder for dropdown options.
  final Widget Function(BuildContext, AuraDropdownOption<T>)? optionBuilder;

  @override
  State<AuraDropdownSelector<T>> createState() =>
      _AuraDropdownSelectorState<T>();
}

class _AuraDropdownSelectorState<T> extends State<AuraDropdownSelector<T>> {
  late FocusNode _focusNode;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    // Ensure overlay is removed before widget is disposed
    super.dispose();
  }

  void _toggleDropdown() {
    if (_focusNode.hasFocus) {
      _unfocus();
    } else {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  void _unfocus() => _focusNode.unfocus();

  Widget _getDisplayText() {
    if (widget.value == null) {
      if (widget.placeholder != null) {
        return AuraText(
          color: AuraColorVariant.onSurfaceVariant,
          child: widget.placeholder!,
        );
      }
      return const Text('');
    }

    final selectedOption = widget.options.firstWhere(
      (option) => option.value == widget.value,
      orElse: () => AuraDropdownOption<T>(
        value: widget.value as T,
        child: const Text(''),
      ),
    );

    return selectedOption.child ?? const Text('');
  }

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final hasError = widget.error != null;
    final state = hasError ? AuraFieldState.error : AuraFieldState.normal;

    return FocusScope(
      onKey: (node, event) {
        // Handle ESC key to close dropdown
        if (event.logicalKey == LogicalKeyboardKey.escape && _isDropdownOpen) {
          _unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Focus(
        focusNode: _focusNode,
        descendantsAreFocusable: true,
        onFocusChange: (hasFocus) {
          setState(() {
            _isDropdownOpen = hasFocus;
          });
        },
        child: PortalTarget(
          visible: _isDropdownOpen,
          anchor: const Aligned(
            follower: Alignment.topCenter,
            target: Alignment.bottomCenter,
            widthFactor: 1,
          ),
          portalFollower: FocusScope(
            child: _DropdownMenu<T>(
              options: widget.options,
              selectedValue: widget.value,
              onOptionSelected: (option) {
                _unfocus();
                if (mounted) {
                  widget.onChanged?.call(option);
                }
              },
              header: widget.header,
              footer: widget.footer,
              optionBuilder: widget.optionBuilder,
            ),
          ),
          child: AuraFieldWrapper(
            label: widget.label,
            hint: widget.hint,
            error: widget.error,
            isRequired: widget.isRequired,
            state: state,
            isEnabled: widget.isEnabled,
            isFocused: _isDropdownOpen,
            onTap: _toggleDropdown,
            semanticLabel: widget.semanticLabel,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesignSpacing.sm,
                horizontal: DesignSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AuraText(
                      child: _getDisplayText(),
                    ),
                  ),
                  const SizedBox(width: DesignSpacing.sm),
                  AuraIcon(
                    _isDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: auraColors.onSurfaceVariant,
                    size: AuraIconSize.small,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownMenu<T> extends StatefulWidget {
  const _DropdownMenu({
    required this.options,
    required this.selectedValue,
    required this.onOptionSelected,
    required this.header,
    required this.footer,
    this.optionBuilder,
    super.key,
  });

  final List<AuraDropdownOption<T>> options;
  final T? selectedValue;
  final void Function(T) onOptionSelected;
  final Widget? header;
  final Widget? footer;
  final Widget Function(BuildContext, AuraDropdownOption<T>)? optionBuilder;

  @override
  State<_DropdownMenu<T>> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<_DropdownMenu<T>> {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: auraColors.outline),
        borderRadius: BorderRadius.circular(DesignBorderRadius.md),
        color: auraColors.surface,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            // constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final option = widget.options[index];

                final isSelected = option.value == widget.selectedValue;
                return widget.optionBuilder?.call(context, option) ??
                    AuraPressable(
                      onPressed: () {
                        widget.onOptionSelected(option.value);
                      },
                      color: context.auraColors.primary,

                      decoration: BoxDecoration(
                        color: isSelected
                            ? auraColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          DesignBorderRadius.sm,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignSpacing.md,
                          vertical: DesignSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            if (option.leading != null) ...[
                              option.leading!,
                              const SizedBox(width: DesignSpacing.sm),
                            ],
                            Expanded(
                              child: AuraText(
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    color: option.isEnabled
                                        ? auraColors.onSurface
                                        : auraColors.onSurface.withValues(
                                            alpha: 0.6,
                                          ),
                                  ),
                                  child: option.child!,
                                ),
                              ),
                            ),
                            if (option.trailing != null) ...[
                              const SizedBox(width: DesignSpacing.sm),
                              option.trailing!,
                            ] else if (isSelected) ...[
                              const SizedBox(width: DesignSpacing.sm),
                              AuraIcon(
                                Icons.check,
                                color: auraColors.primary,
                                size: AuraIconSize.small,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
              },
            ),
          ),

          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}
