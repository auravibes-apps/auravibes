// ignore_for_file: type=lint, type=warning
import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
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
  const new({
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
  bool _ownsFocusNode = false;
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
    _initFocusNode(widget.focusNode);
    _menuFocusScopeNode = FocusScopeNode(
      debugLabel: 'AuraDropdownSelector menu',
      onKeyEvent: _handleMenuKeyEvent,
    );
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _requiredFocusNode.dispose();
    }
    _requiredMenuFocusScopeNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AuraDropdownSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }

    if (_ownsFocusNode) {
      _requiredFocusNode.dispose();
    }
    _initFocusNode(widget.focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.isEnabled && AuraInteractionScope.of(context).allowsValueChanges;
    final hasError = widget.error != null;
    final state = hasError ? AuraFieldState.error : AuraFieldState.normal;
    return _DropdownSelectorShell<T>(
      options: widget.options,
      value: widget.value,
      placeholder: widget.placeholder,
      label: widget.label,
      hint: widget.hint,
      error: widget.error,
      header: widget.header,
      footer: widget.footer,
      isRequired: widget.isRequired,
      isEnabled: isEnabled,
      isDropdownOpen: _isDropdownOpen,
      isTriggerFocused: _isTriggerFocused,
      state: state,
      focusNode: _requiredFocusNode,
      menuFocusScopeNode: _requiredMenuFocusScopeNode,
      semanticLabel: widget.semanticLabel,
      onChanged: widget.onChanged,
      onToggle: _toggleDropdown,
      onClose: _closeDropdown,
      onFocusChange: _handleTriggerFocusChange,
      onKeyEvent: _handleTriggerKeyEvent,
      optionBuilder: widget.optionBuilder,
    );
  }

  KeyEventResult _handleMenuKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _closeDropdown();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _initFocusNode(FocusNode? focusNode) {
    _focusNode = focusNode ?? FocusNode();
    _ownsFocusNode = focusNode == null;
  }

  void _toggleDropdown() {
    if (!AuraInteractionScope.of(context).allowsValueChanges) return;
    if (_isDropdownOpen) {
      _closeDropdown();

      return;
    }

    _openDropdown();
  }

  void _openDropdown() {
    if (!widget.isEnabled ||
        !AuraInteractionScope.of(context).allowsValueChanges ||
        _isDropdownOpen) {
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

  KeyEventResult _handleTriggerKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _toggleDropdown();

      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _isDropdownOpen) {
      _closeDropdown();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleTriggerFocusChange(bool value) {
    setState(() {
      _isTriggerFocused = value;
    });
  }
}

class const _DropdownSelectorShell<T>({
  required final List<AuraDropdownOption<T>> options,
  required final T? value,
  required final Widget? placeholder,
  required final Widget? label,
  required final Widget? hint,
  required final Widget? error,
  required final Widget? header,
  required final Widget? footer,
  required final bool isRequired,
  required final bool isEnabled,
  required final bool isDropdownOpen,
  required final bool isTriggerFocused,
  required final AuraFieldState state,
  required final FocusNode focusNode,
  required final FocusScopeNode menuFocusScopeNode,
  required final String? semanticLabel,
  required final ValueChanged<T?>? onChanged,
  required final VoidCallback onToggle,
  required final VoidCallback onClose,
  required final ValueChanged<bool> onFocusChange,
  required final KeyEventResult Function(FocusNode, KeyEvent) onKeyEvent,
  required final Widget Function(BuildContext, AuraDropdownOption<T>)?
  optionBuilder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PortalTarget(
    visible: isDropdownOpen && isEnabled,
    anchor: const Aligned(
      follower: Alignment.topCenter,
      target: Alignment.bottomCenter,
      portal: Alignment.bottomCenter,
      shiftToWithinBound: AxisFlag(x: true, y: true),
      widthFactor: 1,
    ),
    portalFollower: TapRegion(
      child: FocusScope(
        node: menuFocusScopeNode,
        child: _DropdownMenu<T>(
          options: options,
          selectedValue: value,
          onOptionSelected: (option) {
            onClose();
            onChanged?.call(option);
          },
          header: header,
          footer: footer,
          optionBuilder: optionBuilder,
        ),
      ),
      onTapOutside: (_) => onClose(),
      groupId: this,
    ),
    child: Focus(
      child: TapRegion(
        child: AuraFieldWrapper(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.auraTheme.fromSpacing(.sm),
              horizontal: context.auraTheme.fromSpacing(.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AuraText(
                    child: _DropdownDisplay<T>(
                      options: options,
                      value: value,
                      placeholder: placeholder,
                    ),
                  ),
                ),
                const AuraSizedBox(width: .sm),
                AuraIcon(
                  isDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: AuraIconSize.small,
                ),
              ],
            ),
          ),
          label: label,
          hint: hint,
          error: error,
          isRequired: isRequired,
          state: state,
          isEnabled: isEnabled,
          isFocused: isDropdownOpen || isTriggerFocused,
          onTap: isEnabled ? onToggle : null,
          onFocusChange: onFocusChange,
          semanticLabel: semanticLabel,
        ),
        groupId: this,
      ),
      focusNode: focusNode,
      canRequestFocus: isEnabled,
      onFocusChange: onFocusChange,
      onKeyEvent: onKeyEvent,
      descendantsAreFocusable: false,
    ),
  );
}

class const _DropdownDisplay<T>({
  required final List<AuraDropdownOption<T>> options,
  required final T? value,
  required final Widget? placeholder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectedValue = value;
    final placeholderValue = placeholder;
    final selectedOption = selectedValue == null
        ? null
        : options.firstWhere(
            (option) => option.value == selectedValue,
            orElse: () => AuraDropdownOption<T>(
              value: selectedValue,
              child: const Text(''),
            ),
          );
    if (selectedValue != null) {
      return selectedOption?.child ?? const Text('');
    }
    if (placeholderValue == null) return const Text('');

    return AuraText(child: placeholderValue, style: AuraTextStyle.bodySmall);
  }
}

class const _DropdownMenu<T>({
  required final List<AuraDropdownOption<T>> options,
  required final T? selectedValue,
  required final void Function(T) onOptionSelected,
  required final Widget? header,
  required final Widget? footer,
  final Widget Function(BuildContext, AuraDropdownOption<T>)? optionBuilder,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Container(
      decoration: BoxDecoration(
        color: auraColors.surface,
        border: Border.fromBorderSide(BorderSide(color: auraColors.outline)),
        borderRadius: BorderRadius.all(
          Radius.circular(context.auraTheme.fromBorderRadius(.xl)),
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
                          vertical: context.auraTheme.fromSpacing(.sm),
                          horizontal: context.auraTheme.fromSpacing(.md),
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
                                tint: AuraTint.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      color: context.auraColors.primary,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? auraColors.primary.withValues(alpha: 0.08)
                            : DesignColors.transparent,
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            context.auraTheme.fromBorderRadius(.sm),
                          ),
                        ),
                      ),
                      onPressed: option.isEnabled
                          ? () {
                              onOptionSelected(option.value);
                            }
                          : null,
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
