import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every step state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AuraStepper(
            steps: [
              AuraStep(title: 'Complete', state: .complete),
              AuraStep(
                title: 'Current',
                description: 'In progress',
                state: .current,
              ),
              AuraStep(title: 'Error', state: .error),
              AuraStep(title: 'Pending'),
            ],
          ),
        ),
        theme: .new(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });
}
