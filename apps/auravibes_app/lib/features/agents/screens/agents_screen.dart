import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuraScreen(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraIcon(
              Icons.smart_toy_outlined,
              size: AuraIconSize.extraLarge,
            ),
            SizedBox(height: 16),
            AuraText(
              style: AuraTextStyle.heading4,
              child: Text('Agents'),
            ),
            SizedBox(height: 8),
            AuraText(
              style: AuraTextStyle.bodySmall,
              color: AuraColorVariant.onSurfaceVariant,
              child: Text('Agent management is coming soon.'),
            ),
          ],
        ),
      ),
    );
  }
}
