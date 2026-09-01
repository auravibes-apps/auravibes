import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_modal.stories.g.dart';

class const _ModalInput();

const component = ComponentMeta(name: 'AuraModal');
const meta = Meta(AuraModal.new, argsType: _ModalInput.new);

final _Defaults modalDefaults = _Defaults(
  builder: (context, args) => AuraModal(
    entryPointChild: const AuraButton(
      onPressed: noopCallback,
      child: Text('Open Modal'),
    ),
    contentChild: Builder(
      builder: (modalContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Modal content',
            style: Theme.of(modalContext).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text('This content is supplied independently of the trigger.'),
          const SizedBox(height: 16),
          AuraButton(
            onPressed: Navigator.of(modalContext).pop,
            child: const Text('Close'),
          ),
        ],
      ),
    ),
    barrierLabel: 'Dismiss modal',
    semanticLabel: 'Example modal',
  ),
);

final $Modal = _Story(
  name: 'Modal',
  setup: (context, child, args) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
    child: child,
  ),
  args: _Args(),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Opens Modal',
      run: (tester, args) async {
        await tester.tap(find.text('Open Modal'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Modal content'), findsOneWidget);
      },
    ),
  ],
);
