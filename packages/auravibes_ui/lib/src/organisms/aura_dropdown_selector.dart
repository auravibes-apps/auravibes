// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-extracting-callbacks
// Required: Component callbacks stay colocated with UI state.
// ignore_for_file: prefer-single-widget-per-file
// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_dropdown_option.dart';
import 'package:auravibes_ui/src/organisms/aura_field_wrapper.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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

  /// Optional header for dropdown.
  final Widget? header;

  /// Optional footer for dropdown.
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
  FocusNode? _focusNode;
  bool _isDropdownOpen = false;

  FocusNode get _requiredFocusNode {
    final focusNode = _focusNode;
    if (focusNode == null) {
      throw StateError('_focusNode is not initialized');
    }

    return focusNode;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    // Listen for focus changes.
    _focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    final focusNode = _focusNode;
    if (focusNode != null) {
      focusNode.removeListener(_onFocusChange);
      if (widget.focusNode == null) {
        focusNode.dispose();
      }
    }
    // Ensure overlay is removed before widget is disposed.
    super.dispose();
  }

  void _onFocusChange() {
    // Close dropdown when losing focus.
    if (!_requiredFocusNode.hasFocus && _isDropdownOpen) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  void _toggleDropdown() {
    if (_requiredFocusNode.hasFocus) {
      _unfocus();
    } else {
      FocusScope.of(context).requestFocus(_requiredFocusNode);
    }
  }

  void _unfocus() => _requiredFocusNode.unfocus();

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final state = hasError ? AuraFieldState.error : AuraFieldState.normal;
    final value = widget.value;
    final selectedOption = value == null
        ? null
        : widget.options.firstWhere(
            (option) => option.value == value,
            orElse: () => AuraDropdownOption<T>(
              value: value,
              child: const Text(''),
            ),
          );
    final placeholder = widget.placeholder;
    final Widget displayText;
    if (value != null) {
      displayText = selectedOption?.child ?? const Text('');
    } else if (placeholder != null) {
      displayText = AuraText(
        child: placeholder,
        color: AuraColorVariant.onSurfaceVariant,
      );
    } else {
      displayText = const Text('');
    }

    return FocusScope(
      child: Focus(
        child: PortalTarget(
          visible: _isDropdownOpen,
          anchor: const Aligned(
            follower: Alignment.topCenter,
            target: Alignment.bottomCenter,
            widthFactor: 1,
          ),
          portalFollower: TapRegion(
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
            groupId: this,
          ),
          child: TapRegion(
            child: AuraFieldWrapper(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignSpacing.sm,
                  horizontal: DesignSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(child: AuraText(child: displayText)),
                    const SizedBox(width: DesignSpacing.sm),
                    AuraIcon(
                      _isDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: AuraIconSize.small,
                      color: AuraColorVariant.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              label: widget.label,
              hint: widget.hint,
              error: widget.error,
              isRequired: widget.isRequired,
              state: state,
              isEnabled: widget.isEnabled,
              isFocused: _isDropdownOpen,
              onTap: _toggleDropdown,
              semanticLabel: widget.semanticLabel,
            ),
            onTapOutside: (_) {
              if (_isDropdownOpen) {
                _unfocus();
              }
            },
            groupId: this,
          ),
        ),
        focusNode: _focusNode,
        onFocusChange: (hasFocus) {
          setState(() {
            _isDropdownOpen = hasFocus;
          });
        },
        descendantsAreFocusable: true,
      ),
      onKey: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape && _isDropdownOpen) {
          _unfocus();

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
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
    final header = widget.header;
    final footer = widget.footer;

    return Container(
      decoration: BoxDecoration(
        color: auraColors.surface,
        border: Border.fromBorderSide(BorderSide(color: auraColors.outline)),
        borderRadius: const BorderRadius.all(
          Radius.circular(DesignBorderRadius.md),
        ),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?header,
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final isSelected = option.value == widget.selectedValue;
                final leading = option.leading;
                final trailing = option.trailing;
                final child = option.child ?? const Text('');

                return widget.optionBuilder?.call(context, option) ??
                    AuraPressable(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: DesignSpacing.sm,
                          horizontal: DesignSpacing.md,
                        ),
                        child: Row(
                          children: [
                            if (leading != null) ...[
                              leading,
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
                                  child: child,
                                ),
                              ),
                            ),
                            if (trailing != null) ...[
                              const SizedBox(width: DesignSpacing.sm),
                              trailing,
                            ] else if (isSelected) ...[
                              const SizedBox(width: DesignSpacing.sm),
                              const AuraIcon(
                                Icons.check,
                                size: AuraIconSize.small,
                                color: AuraColorVariant.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      color: context.auraColors.primary,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? auraColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(DesignBorderRadius.sm),
                        ),
                      ),
                      onPressed: () {
                        widget.onOptionSelected(option.value);
                      },
                    );
              },
              itemCount: widget.options.length,
            ),
          ),
          ?footer,
        ],
      ),
      clipBehavior: Clip.hardEdge,
    );
  }
}
