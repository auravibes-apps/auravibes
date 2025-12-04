import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Single Selection (Radio)', type: AuraButtonGroup)
Widget buttonGroupSingleUseCase(BuildContext context) {
  return _SingleSelectionDemo(
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraButtonGroupSize.values,
      initialOption: AuraButtonGroupSize.base,
      labelBuilder: (value) => value.name,
    ),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraButtonGroupVariant.values,
      initialOption: AuraButtonGroupVariant.outlined,
      labelBuilder: (value) => value.name,
    ),
    orientation: context.knobs.object.dropdown(
      label: 'orientation',
      options: Axis.values,
      initialOption: Axis.horizontal,
      labelBuilder: (value) => value.name,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
    isLoading: context.knobs.boolean(label: 'isLoading', initialValue: false),
  );
}

@widgetbook.UseCase(name: 'Multi Selection (Toggle)', type: AuraButtonGroup)
Widget buttonGroupMultiUseCase(BuildContext context) {
  return _MultiSelectionDemo(
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraButtonGroupSize.values,
      initialOption: AuraButtonGroupSize.base,
      labelBuilder: (value) => value.name,
    ),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraButtonGroupVariant.values,
      initialOption: AuraButtonGroupVariant.outlined,
      labelBuilder: (value) => value.name,
    ),
    orientation: context.knobs.object.dropdown(
      label: 'orientation',
      options: Axis.values,
      initialOption: Axis.horizontal,
      labelBuilder: (value) => value.name,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
    isLoading: context.knobs.boolean(label: 'isLoading', initialValue: false),
  );
}

@widgetbook.UseCase(name: 'Action (Clickable)', type: AuraButtonGroup)
Widget buttonGroupActionUseCase(BuildContext context) {
  return _ActionDemo(
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraButtonGroupSize.values,
      initialOption: AuraButtonGroupSize.base,
      labelBuilder: (value) => value.name,
    ),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraButtonGroupVariant.values,
      initialOption: AuraButtonGroupVariant.outlined,
      labelBuilder: (value) => value.name,
    ),
    orientation: context.knobs.object.dropdown(
      label: 'orientation',
      options: Axis.values,
      initialOption: Axis.horizontal,
      labelBuilder: (value) => value.name,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
    isLoading: context.knobs.boolean(label: 'isLoading', initialValue: false),
  );
}

// Single Selection Demo
class _SingleSelectionDemo extends StatefulWidget {
  const _SingleSelectionDemo({
    required this.size,
    required this.variant,
    required this.orientation,
    required this.disabled,
    required this.isLoading,
  });

  final AuraButtonGroupSize size;
  final AuraButtonGroupVariant variant;
  final Axis orientation;
  final bool disabled;
  final bool isLoading;

  @override
  State<_SingleSelectionDemo> createState() => _SingleSelectionDemoState();
}

class _SingleSelectionDemoState extends State<_SingleSelectionDemo> {
  String? _selectedValue = 'option1';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'option1', child: Text('Option 1')),
                AuraButtonGroupItem(value: 'option2', child: Text('Option 2')),
                AuraButtonGroupItem(value: 'option3', child: Text('Option 3')),
              ],
              selectedValue: _selectedValue,
              onChanged: (value) => setState(() => _selectedValue = value),
              size: widget.size,
              variant: widget.variant,
              orientation: widget.orientation,
              disabled: widget.disabled,
              isLoading: widget.isLoading,
            ),
            const SizedBox(height: 16),
            Text('Selected: $_selectedValue'),
          ],
        ),
      ),
    );
  }
}

// Multi Selection Demo
class _MultiSelectionDemo extends StatefulWidget {
  const _MultiSelectionDemo({
    required this.size,
    required this.variant,
    required this.orientation,
    required this.disabled,
    required this.isLoading,
  });

  final AuraButtonGroupSize size;
  final AuraButtonGroupVariant variant;
  final Axis orientation;
  final bool disabled;
  final bool isLoading;

  @override
  State<_MultiSelectionDemo> createState() => _MultiSelectionDemoState();
}

class _MultiSelectionDemoState extends State<_MultiSelectionDemo> {
  Set<String> _selectedValues = {'bold'};

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraButtonGroup<String>.multi(
              items: const [
                AuraButtonGroupItem(
                  value: 'bold',
                  child: Icon(Icons.format_bold),
                ),
                AuraButtonGroupItem(
                  value: 'italic',
                  child: Icon(Icons.format_italic),
                ),
                AuraButtonGroupItem(
                  value: 'underline',
                  child: Icon(Icons.format_underline),
                ),
              ],
              selectedValues: _selectedValues,
              onMultiChanged: (values) =>
                  setState(() => _selectedValues = values),
              size: widget.size,
              variant: widget.variant,
              orientation: widget.orientation,
              disabled: widget.disabled,
              isLoading: widget.isLoading,
            ),
            const SizedBox(height: 16),
            Text('Selected: ${_selectedValues.join(", ")}'),
          ],
        ),
      ),
    );
  }
}

// Action Demo
class _ActionDemo extends StatefulWidget {
  const _ActionDemo({
    required this.size,
    required this.variant,
    required this.orientation,
    required this.disabled,
    required this.isLoading,
  });

  final AuraButtonGroupSize size;
  final AuraButtonGroupVariant variant;
  final Axis orientation;
  final bool disabled;
  final bool isLoading;

  @override
  State<_ActionDemo> createState() => _ActionDemoState();
}

class _ActionDemoState extends State<_ActionDemo> {
  String _lastPressed = 'None';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraButtonGroup<String>.action(
              items: const [
                AuraButtonGroupItem(value: 'undo', child: Icon(Icons.undo)),
                AuraButtonGroupItem(value: 'redo', child: Icon(Icons.redo)),
                AuraButtonGroupItem(value: 'copy', child: Icon(Icons.copy)),
                AuraButtonGroupItem(value: 'paste', child: Icon(Icons.paste)),
              ],
              onPressed: (value) => setState(() => _lastPressed = value),
              size: widget.size,
              variant: widget.variant,
              orientation: widget.orientation,
              disabled: widget.disabled,
              isLoading: widget.isLoading,
            ),
            const SizedBox(height: 16),
            Text('Last pressed: $_lastPressed'),
          ],
        ),
      ),
    );
  }
}
