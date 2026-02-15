import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class PromptsScreen extends StatelessWidget {
  const PromptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuraScreen(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraIcon(
              Icons.description_outlined,
              size: AuraIconSize.extraLarge,
            ),
            SizedBox(height: 16),
            AuraText(
              style: AuraTextStyle.heading4,
              child: Text('Prompts'),
            ),
            SizedBox(height: 8),
            AuraText(
              style: AuraTextStyle.bodySmall,
              color: AuraColorVariant.onSurfaceVariant,
              child: Text('Prompt templates are coming soon.'),
            ),
          ],
        ),
      ),
    );
  }
}
