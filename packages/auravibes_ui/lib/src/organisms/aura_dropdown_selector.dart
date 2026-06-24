// Required: Existing test and UI helpers keep compact return flow.
// Required: Component callbacks stay colocated with UI state.
// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
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
  FocusScopeNode? _menuFocusScopeNode;
  bool _isDropdownOpen = false;
  bool _isTriggerFocused = false;

  FocusNode get _requiredFocusNode {
    final node = _focusNode;
    if (node == null) {
      throw StateError('Focus node not initialized');
    }

    return node;
  }

  FocusScopeNode get _requiredMenuFocusScopeNode {
    final node = _menuFocusScopeNode;
    if (node == null) {
      throw StateError('Menu focus scope node not initialized');
    }

    return node;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _menuFocusScopeNode = FocusScopeNode(
      debugLabel: 'AuraDropdownSelector menu',
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _closeDropdown();

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _requiredFocusNode.dispose();
    }
    _requiredMenuFocusScopeNode.dispose();
    // Ensure overlay is removed before widget is disposed.
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();

      return;
    }

    _openDropdown();
  }

  void _openDropdown() {
    if (!widget.isEnabled || _isDropdownOpen) {
      return;
    }

    setState(() {
      _isDropdownOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isDropdownOpen) return;

      _requiredMenuFocusScopeNode.requestFocus();
    });
  }

  void _closeDropdown() {
    if (!_isDropdownOpen) {
      return;
    }

    setState(() {
      _isDropdownOpen = false;
    });
    FocusScope.of(context).unfocus();
    _requiredFocusNode.unfocus();
  }

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

    return Focus(
      child: PortalTarget(
        visible: _isDropdownOpen,
        portalFollower: GestureDetector(
          onTap: _closeDropdown,
          behavior: HitTestBehavior.opaque,
        ),
        child: PortalTarget(
          visible: _isDropdownOpen,
          anchor: const Aligned(
            follower: Alignment.topCenter,
            target: Alignment.bottomCenter,
            portal: Alignment.bottomCenter,
            shiftToWithinBound: AxisFlag(x: true, y: true),
            widthFactor: 1,
          ),
          portalFollower: TapRegion(
            child: FocusScope(
              node: _requiredMenuFocusScopeNode,
              child: _DropdownMenu<T>(
                options: widget.options,
                selectedValue: widget.value,
                onOptionSelected: (option) {
                  _closeDropdown();
                  widget.onChanged?.call(option);
                },
                header: widget.header,
                footer: widget.footer,
                optionBuilder: widget.optionBuilder,
              ),
            ),
            groupId: this,
          ),
          child: TapRegion(
            child: AuraFieldWrapper(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.auraTheme.fromSpacing(.sm),
                  horizontal: context.auraTheme.fromSpacing(.md),
                ),
                child: Row(
                  children: [
                    Expanded(child: AuraText(child: displayText)),
                    const AuraSizedBox(width: .sm),
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
              isFocused: _isDropdownOpen || _isTriggerFocused,
              onTap: _toggleDropdown,
              onFocusChange: (value) {
                setState(() {
                  _isTriggerFocused = value;
                });
              },
              semanticLabel: widget.semanticLabel,
            ),
            groupId: this,
          ),
        ),
      ),
      focusNode: _requiredFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _isDropdownOpen) {
          _closeDropdown();

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      skipTraversal: true,
      descendantsAreFocusable: true,
    );
  }
}

class _DropdownMenu<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Container(
      decoration: BoxDecoration(
        color: auraColors.surface,
        border: Border.fromBorderSide(BorderSide(color: auraColors.outline)),
        borderRadius: BorderRadius.all(
          Radius.circular(
            context.auraTheme.fromBorderRadius(.xl),
          ),
        ),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?header,
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.value == selectedValue;
                final leading = option.leading;
                final trailing = option.trailing;
                final child = option.child ?? const Text('');

                return optionBuilder?.call(context, option) ??
                    AuraPressable(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.auraTheme.fromSpacing(
                            .sm,
                          ),
                          horizontal: context.auraTheme.fromSpacing(
                            .md,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (leading != null) ...[
                              leading,
                              const AuraSizedBox(width: .sm),
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
                              const AuraSizedBox(width: .sm),
                              trailing,
                            ] else if (isSelected) ...[
                              const AuraSizedBox(width: .sm),
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
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            context.auraTheme.fromBorderRadius(
                              .sm,
                            ),
                          ),
                        ),
                      ),
                      onPressed: () {
                        onOptionSelected(option.value);
                      },
                    );
              },
              itemCount: options.length,
            ),
          ),
          ?footer,
        ],
      ),
      clipBehavior: Clip.hardEdge,
    );
  }
}
