import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Date and Time', type: AuraDateTimeInput)
Widget dateTimeInputUseCase(BuildContext context) {
  final enableDate = context.knobs.boolean(
    label: 'enableDate',
    initialValue: true,
  );
  final enableTime = context.knobs.boolean(
    label: 'enableTime',
    initialValue: true,
  );

  return Navigator(
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => _DateTimeInputDemo(
        enableDate: enableDate || !enableTime,
        enableTime: enableTime || !enableDate,
        enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
      ),
    ),
  );
}

class _DateTimeInputDemo extends StatefulWidget {
  const _DateTimeInputDemo({
    required this.enableDate,
    required this.enableTime,
    required this.enabled,
  });

  final bool enableDate;
  final bool enableTime;
  final bool enabled;

  @override
  State<_DateTimeInputDemo> createState() => _DateTimeInputDemoState();
}

class _DateTimeInputDemoState extends State<_DateTimeInputDemo> {
  DateTime? _value = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AuraDateTimeInput(
          value: _value,
          enableDate: widget.enableDate,
          enableTime: widget.enableTime,
          enabled: widget.enabled,
          semanticLabel: 'Date and time',
          onChanged: (value) => setState(() => _value = value),
        ),
      ),
    );
  }
}
