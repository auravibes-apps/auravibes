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

/// A selectable Aura tab strip with optional content.
///
/// Use [AuraTabs] when each tab owns content. Use [AuraTabs.selector] when the
/// tab strip selects a value and the caller renders content separately.
class AuraTabs<T> extends StatefulWidget {
  /// Creates Aura tabs with one child per tab.
  const AuraTabs({
    required this.items,
    super.key,
    this.initialIndex = 0,
    this.selectedIndex,
    this.onChanged,
  }) : options = const [],
       value = null,
       initialValue = null,
       _selectorOnChanged = null,
       _mode = _AuraTabsMode.content;

  /// Creates value-selecting tabs without tab children.
  const AuraTabs.selector({
    required this.options,
    this.value,
    this.initialValue,
    ValueChanged<T>? onChanged,
    super.key,
  }) : assert(
         value == null || initialValue == null,
         'Use either value or initialValue, not both.',
       ),
       items = const [],
       initialIndex = 0,
       selectedIndex = null,
       onChanged = null,
       _selectorOnChanged = onChanged,
       _mode = _AuraTabsMode.selector;

  /// The tab title widgets and content.
  final List<AuraTabItem> items;

  /// The value-selecting options for [AuraTabs.selector].
  final List<AuraTabOption<T>> options;

  /// The initially selected tab for uncontrolled use.
  final int initialIndex;

  /// The selected tab for controlled use. This takes precedence over
  /// [initialIndex].
  final int? selectedIndex;

  /// Called when the selected tab changes.
  final ValueChanged<int>? onChanged;

  /// The selected value for [AuraTabs.selector].
  final T? value;

  /// The initial value for uncontrolled [AuraTabs.selector] use.
  final T? initialValue;

  final ValueChanged<T>? _selectorOnChanged;
  final _AuraTabsMode _mode;

  @override
  State<AuraTabs<T>> createState() => _AuraTabsState<T>();
}

enum _AuraTabsMode { content, selector }

class _AuraTabsState<T> extends State<AuraTabs<T>> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialIndex();
  }

  @override
  void didUpdateWidget(covariant AuraTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget._mode != oldWidget._mode) {
      _selectedIndex = _initialIndex();

      return;
    }

    if (widget._mode == _AuraTabsMode.selector) {
      final options = widget.options;
      if (widget.value != null) {
        _selectedIndex = _indexForValue(widget.value, options);
      } else if (oldWidget.options.isEmpty && options.isNotEmpty) {
        _selectedIndex = _indexForValue(widget.initialValue, options);
      } else {
        _selectedIndex = _normalizeIndex(_selectedIndex, options.length);
      }

      return;
    }

    final requestedIndex =
        widget.selectedIndex ??
        (oldWidget.items.isEmpty ? widget.initialIndex : _selectedIndex);
    _selectedIndex = _normalizeIndex(requestedIndex, widget.items.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget._mode == _AuraTabsMode.selector) {
      final options = widget.options;
      if (options.isEmpty) return const SizedBox.shrink();

      return _AuraTabBar(
        titles: [for (final option in options) option.title],
        semanticLabels: [for (final option in options) option.semanticLabel],
        selectedIndex: _selectedOptionIndex(options),
        onChanged: _select,
      );
    }

    if (widget.items.isEmpty) return const SizedBox.shrink();

    final selectedIndex = _normalizeIndex(
      widget.selectedIndex ?? _selectedIndex,
      widget.items.length,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AuraTabBar(
          titles: [for (final item in widget.items) item.title],
          semanticLabels: [for (final item in widget.items) item.semanticLabel],
          selectedIndex: selectedIndex,
          onChanged: _select,
        ),
        Flexible(
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

  void _select(int index) {
    if (widget._mode == _AuraTabsMode.selector) {
      final options = widget.options;
      final selectedIndex = _selectedOptionIndex(options);
      if (index == selectedIndex) return;

      if (widget.value == null) {
        setState(() => _selectedIndex = index);
      }
      widget._selectorOnChanged?.call(options[index].value);

      return;
    }

    final selectedIndex = _normalizeIndex(
      widget.selectedIndex ?? _selectedIndex,
      widget.items.length,
    );
    if (index == selectedIndex) return;

    if (widget.selectedIndex == null) {
      setState(() => _selectedIndex = index);
    }
    widget.onChanged?.call(index);
  }

  int _initialIndex() {
    if (widget._mode == _AuraTabsMode.selector) {
      final options = widget.options;

      return _indexForValue(widget.value ?? widget.initialValue, options);
    }

    return _normalizeIndex(
      widget.selectedIndex ?? widget.initialIndex,
      widget.items.length,
    );
  }

  int _selectedOptionIndex(List<AuraTabOption<T>> options) {
    if (widget.value != null) {
      return _indexForValue(widget.value, options);
    }

    return _normalizeIndex(_selectedIndex, options.length);
  }

  int _indexForValue(T? value, List<AuraTabOption<T>> options) {
    if (value == null) return 0;

    final index = options.indexWhere((option) => option.value == value);

    return index < 0 ? 0 : index;
  }

  int _normalizeIndex(int index, int length) {
    if (length == 0 || index < 0) return 0;
    if (index >= length) return length - 1;

    return index;
  }
}

class _AuraTabBar extends StatelessWidget {
  const _AuraTabBar({
    required this.titles,
    required this.semanticLabels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<Widget> titles;
  final List<String?> semanticLabels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < titles.length; index++)
                _buildTab(context, index),
            ],
          ),
        ),
        const AuraDivider(),
      ],
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final isSelected = index == selectedIndex;
    final auraColors = context.auraColors;
    final borderRadius = context.auraTheme.fromBorderRadius(.md);
    final title = titles[index];

    return Semantics(
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AuraPressable(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48),
                  child: AuraSizedBox(
                    height: .xl2,
                    child: AuraPadding(
                      child: Center(
                        child: AuraText(
                          child: title,
                          style: AuraTextStyle.bodySmall,
                          tint: isSelected ? AuraTint.primary : null,
                        ),
                      ),
                      padding: const AuraEdgeInsetsGeometry.horizontal(.md),
                    ),
                  ),
                ),
                color: auraColors.primary,
                decoration: BoxDecoration(
                  color: isSelected
                      ? auraColors.primary.withValues(alpha: 0.08)
                      : DesignColors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                ),
                onPressed: () => onChanged(index),
                semanticLabel:
                    semanticLabels[index] ?? _textSemanticLabel(title) ?? 'Tab',
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
        ),
      ),
      container: true,
      excludeSemantics: true,
      selected: isSelected,
      label: semanticLabels[index] ?? _textSemanticLabel(title),
      onTap: () => onChanged(index),
      role: SemanticsRole.tab,
    );
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

/// Defines one value-selecting tab option.
class AuraTabOption<T> {
  /// Creates a value-selecting tab option.
  const AuraTabOption({
    required this.value,
    required this.title,
    this.semanticLabel,
  });

  /// The value emitted when this option is selected.
  final T value;

  /// The widget shown in the tab bar.
  final Widget title;

  /// An accessible label for title widgets that do not expose their own label.
  final String? semanticLabel;
}
