// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Single Checkbox', type: AuraCheckbox)
Widget singleCheckboxUseCase(BuildContext context) {
  return _SingleCheckboxDemo(
    tint: context.knobs.objectOrNull.dropdown(
      label: 'tint',
      options: AuraTint.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
    autofocus: context.knobs.boolean(label: 'autofocus', initialValue: false),
  );
}

@widgetbook.UseCase(name: 'Checkbox List Tile', type: AuraCheckboxListTile)
Widget checkboxListTileUseCase(BuildContext context) {
  return _CheckboxListTileDemo(
    tint: context.knobs.objectOrNull.dropdown(
      label: 'tint',
      options: AuraTint.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
    showSubtitle: context.knobs.boolean(
      label: 'showSubtitle',
      initialValue: true,
    ),
    autofocus: context.knobs.boolean(label: 'autofocus', initialValue: false),
  );
}

@widgetbook.UseCase(name: 'Focus States', type: AuraCheckbox)
Widget checkboxFocusStatesUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: 'selected', initialValue: true);

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FocusStateRow(
            label: 'Focused',
            value: selected,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          _FocusStateRow(label: 'Not focused', value: selected),
        ],
      ),
    ),
  );
}

class _SingleCheckboxDemo extends StatefulWidget {
  const _SingleCheckboxDemo({
    required this.tint,
    required this.disabled,
    required this.autofocus,
  });

  final AuraTint? tint;
  final bool disabled;
  final bool autofocus;

  @override
  State<_SingleCheckboxDemo> createState() => _SingleCheckboxDemoState();
}

class _SingleCheckboxDemoState extends State<_SingleCheckboxDemo> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AuraCheckbox(
        value: _value,
        onChanged: widget.disabled
            ? null
            : (value) => setState(() => _value = value),
        tint: widget.tint,
        disabled: widget.disabled,
        autofocus: widget.autofocus,
      ),
    );
  }
}

class _CheckboxListTileDemo extends StatefulWidget {
  const _CheckboxListTileDemo({
    required this.tint,
    required this.disabled,
    required this.showSubtitle,
    required this.autofocus,
  });

  final AuraTint? tint;
  final bool disabled;
  final bool showSubtitle;
  final bool autofocus;

  @override
  State<_CheckboxListTileDemo> createState() => _CheckboxListTileDemoState();
}

class _CheckboxListTileDemoState extends State<_CheckboxListTileDemo> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AuraCheckboxListTile(
          value: _value,
          onChanged: widget.disabled
              ? null
              : (value) => setState(() => _value = value),
          title: const Text('Enable option'),
          subtitle: widget.showSubtitle
              ? const Text('Use this for optional settings')
              : null,
          tint: widget.tint,
          disabled: widget.disabled,
          autofocus: widget.autofocus,
        ),
      ),
    );
  }
}

class _FocusStateRow extends StatelessWidget {
  const _FocusStateRow({
    required this.label,
    required this.value,
    this.autofocus = false,
  });

  final String label;
  final bool value;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraCheckbox(
          value: value,
          onChanged: _noopCheckboxChanged,
          autofocus: autofocus,
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

void _noopCheckboxChanged(bool value) {
  if (value) return;
}
