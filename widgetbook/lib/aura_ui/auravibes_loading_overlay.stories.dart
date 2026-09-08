import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_loading_overlay.stories.g.dart';

class const _LoadingOverlayInput({
  required final bool isLoading,
  required final String? message,
});

const component = ComponentMeta(name: 'AuraLoadingOverlay');
const meta = Meta(LoadingOverlayDemo.new, argsType: _LoadingOverlayInput.new);

final _Defaults loadingOverlayDefaults = _Defaults(
  builder: (context, args) =>
      LoadingOverlayDemo(isLoading: args.isLoading, message: args.message),
);

final $LoadingOverlay = _Story(
  name: 'Loading Overlay',
  setup: (context, child, args) =>
      SizedBox(width: 360, height: 300, child: child),
  args: _Args(
    isLoading: BoolArg(true, name: 'Loading'),
    message: NullableStringArg('Loading workspace', name: 'Message'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'Arabic', modes: [AuraArabicLocaleMode()]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
  ],
);

/// Demonstrates loading content with an optional message and accessible state.
class const LoadingOverlayDemo({
  required final bool isLoading,
  required final String? message,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraLoadingOverlay(
      isLoading: isLoading,
      child: ColoredBox(
        color: context.auraColors.surfaceVariant,
        child: Center(
          child: Text(
            'Workspace content',
            style: TextStyle(color: context.auraColors.onSurface),
          ),
        ),
      ),
      message: message,
      semanticLabel: message ?? 'Loading workspace',
    );
  }
}
