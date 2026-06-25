// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Radio List Tile', type: AuraRadioListTile)
Widget radioListTileUseCase(BuildContext context) {
  return _RadioListTileDemo(
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
  );
}

class _RadioListTileDemo extends StatefulWidget {
  const _RadioListTileDemo({
    required this.tint,
    required this.disabled,
    required this.showSubtitle,
  });

  final AuraTint? tint;
  final bool disabled;
  final bool showSubtitle;

  @override
  State<_RadioListTileDemo> createState() => _RadioListTileDemoState();
}

class _RadioListTileDemoState extends State<_RadioListTileDemo> {
  String? _selectedValue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraRadioListTile<String>(
              value: 'system',
              groupValue: _selectedValue,
              onChanged: widget.disabled
                  ? null
                  : (value) => setState(() => _selectedValue = value),
              title: const Text('System Theme'),
              subtitle: widget.showSubtitle
                  ? const Text('Follow system settings')
                  : null,
              tint: widget.tint,
              disabled: widget.disabled,
            ),
            AuraRadioListTile<String>(
              value: 'light',
              groupValue: _selectedValue,
              onChanged: widget.disabled
                  ? null
                  : (value) => setState(() => _selectedValue = value),
              title: const Text('Light Theme'),
              subtitle: widget.showSubtitle
                  ? const Text('Use light color scheme')
                  : null,
              tint: widget.tint,
              disabled: widget.disabled,
            ),
            AuraRadioListTile<String>(
              value: 'dark',
              groupValue: _selectedValue,
              onChanged: widget.disabled
                  ? null
                  : (value) => setState(() => _selectedValue = value),
              title: const Text('Dark Theme'),
              subtitle: widget.showSubtitle
                  ? const Text('Use dark color scheme')
                  : null,
              tint: widget.tint,
              disabled: widget.disabled,
            ),
          ],
        ),
      ),
    );
  }
}
