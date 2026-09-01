// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_selectable_text.stories.g.dart';

class const _SelectableTextInput({
  required final String data,
  required final AuraTextStyle style,
  required final AuraTint? tint,
  required final TextAlign? textAlign,
  required final int? maxLines,
  required final double cursorWidth,
  required final double? cursorHeight,
  required final Radius? cursorRadius,
  required final AuraTint? cursorTint,
  required final bool showCursor,
  required final bool autofocus,
  required final int? minLines,
  required final bool enableTap,
  required final bool enableSelectionChanged,
});

const component = ComponentMeta(name: 'AuraSelectableText');
const meta = Meta(SelectableTextDemo.new, argsType: _SelectableTextInput.new);

final _Defaults selectableTextDefaults = _Defaults(
  builder: (context, args) => SelectableTextDemo(
    data: args.data,
    style: args.style,
    tint: args.tint,
    textAlign: args.textAlign,
    maxLines: args.maxLines,
    cursorWidth: args.cursorWidth,
    cursorHeight: args.cursorHeight,
    cursorRadius: args.cursorRadius,
    cursorTint: args.cursorTint,
    showCursor: args.showCursor,
    autofocus: args.autofocus,
    minLines: args.minLines,
    enableTap: args.enableTap,
    enableSelectionChanged: args.enableSelectionChanged,
  ),
);

final $DefaultSelectableText = _Story(
  name: 'Default SelectableText',
  setup: (context, child, args) => constrainStoryWidth(
    Padding(padding: const EdgeInsets.all(16), child: child),
  ),
  args: _Args(
    data: StringArg('This text can be selected and copied.', name: 'text'),
    style: EnumArg(
      AuraTextStyle.body,
      name: 'style',
      values: AuraTextStyle.values,
    ),
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
    textAlign: NullableEnumArg(
      null,
      name: 'textAlign',
      values: const [
        TextAlign.left,
        TextAlign.center,
        TextAlign.right,
        TextAlign.justify,
      ],
    ),
    maxLines: NullableIntArg(
      null,
      name: 'maxLines',
      style: const SliderIntArgStyle(min: 1, max: 10, divisions: 9),
    ),
    cursorWidth: DoubleArg(
      2,
      name: 'cursorWidth',
      style: const SliderDoubleArgStyle(min: 1, max: 6, divisions: 5),
    ),
    cursorHeight: NullableDoubleArg(
      null,
      name: 'cursorHeight',
      style: const SliderDoubleArgStyle(min: 8, max: 48, divisions: 10),
    ),
    cursorRadius: NullableSingleArg<Radius>(
      null,
      name: 'cursorRadius',
      values: const [Radius.zero, Radius.circular(2), Radius.circular(6)],
      labelBuilder: (value) => '${value.x}px',
    ),
    cursorTint: NullableEnumArg(
      null,
      name: 'cursorTint',
      values: AuraTint.values,
    ),
    showCursor: BoolArg(false, name: 'showCursor'),
    autofocus: BoolArg(false, name: 'autofocus'),
    minLines: NullableIntArg(
      null,
      name: 'minLines',
      style: const SliderIntArgStyle(min: 1, max: 10, divisions: 9),
    ),
    enableTap: BoolArg(true, name: 'Enable Tap'),
    enableSelectionChanged: BoolArg(true, name: 'Enable Selection Changed'),
  ),
  scenarios: [
    _Scenario(
      name: 'Tapped',
      run: (tester, args) async {
        await tester.tap(find.byType(SelectableText));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
    _Scenario(
      name: 'Selects Text',
      run: (tester, args) async {
        await tester.longPress(find.byType(SelectableText));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates selectable text callbacks and cursor configuration.
class const SelectableTextDemo({
  super.key,
  required final String data,
  required final AuraTextStyle style,
  required final AuraTint? tint,
  required final TextAlign? textAlign,
  required final int? maxLines,
  required final double cursorWidth,
  required final double? cursorHeight,
  required final Radius? cursorRadius,
  required final AuraTint? cursorTint,
  required final bool showCursor,
  required final bool autofocus,
  required final int? minLines,
  required final bool enableTap,
  required final bool enableSelectionChanged,
}) extends StatefulWidget {
  @override
  State<SelectableTextDemo> createState() => _SelectableTextDemoState();
}

class _SelectableTextDemoState extends State<SelectableTextDemo> {
  String? _lastInteraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuraSelectableText(
          widget.data,
          style: widget.style,
          tint: widget.tint,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          onTap: widget.enableTap
              ? () => setState(() => _lastInteraction = 'Tapped')
              : null,
          cursorWidth: widget.cursorWidth,
          cursorHeight: widget.cursorHeight,
          cursorRadius: widget.cursorRadius,
          cursorTint: widget.cursorTint,
          onSelectionChanged: widget.enableSelectionChanged
              ? (_, _) => setState(() => _lastInteraction = 'Selection changed')
              : null,
          showCursor: widget.showCursor,
          autofocus: widget.autofocus,
          minLines: widget.minLines,
        ),
        if (_lastInteraction case final interaction?)
          Text('Last interaction: $interaction'),
      ],
    );
  }
}
