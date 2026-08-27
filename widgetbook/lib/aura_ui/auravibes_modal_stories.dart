import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Modal', type: AuraModal)
Widget modalUseCase(BuildContext _) {
  return Scaffold(
    body: Center(
      child: AuraModal(
        entryPointChild: AuraButton(
          onPressed: () {
            final _ = Object();
          },
          child: const Text('Open Modal'),
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
              const Text(
                'This content is supplied independently of the trigger.',
              ),
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
    ),
  );
}
