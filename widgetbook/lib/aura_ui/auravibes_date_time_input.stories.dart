import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_date_time_input.stories.g.dart';

class _DateTimeInputControls {
  const _DateTimeInputControls({
    required this.enableDate,
    required this.enableTime,
    required this.enabled,
    required this.initialValue,
  });

  final bool enableDate;
  final bool enableTime;
  final bool enabled;
  final DateTime initialValue;
}

const component = ComponentMeta(name: 'AuraDateTimeInput');
const meta = Meta(DateTimeInputDemo.new, argsType: _DateTimeInputControls.new);

final _Defaults dateTimeInputDefaults = _Defaults(
  builder: (context, args) => DateTimeInputDemo(
    enableDate: args.enableDate || !args.enableTime,
    enableTime: args.enableTime || !args.enableDate,
    enabled: args.enabled,
    initialValue: args.initialValue,
  ),
);

final $DateAndTime = _Story(
  name: 'Date and Time',
  setup: (context, child, args) => constrainStoryWidth(child, maxWidth: 480),
  args: _Args(
    enableDate: BoolArg(true, name: 'enableDate'),
    enableTime: BoolArg(true, name: 'enableTime'),
    enabled: BoolArg(true, name: 'enabled'),
    initialValue: DateTimeArg(
      DateTime(2026, 8, 28, 12),
      name: 'Initial Value',
      start: DateTime(2026, 1),
      end: DateTime(2026, 12, 31, 23, 59),
    ),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Opens Picker',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraDateTimeInput));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates the controlled date and time picker in its supported modes.
class DateTimeInputDemo extends StatefulWidget {
  const DateTimeInputDemo({
    super.key,
    required this.enableDate,
    required this.enableTime,
    required this.enabled,
    required this.initialValue,
  });

  final bool enableDate;
  final bool enableTime;
  final bool enabled;
  final DateTime initialValue;

  @override
  State<DateTimeInputDemo> createState() => _DateTimeInputDemoState();
}

class _DateTimeInputDemoState extends State<DateTimeInputDemo> {
  DateTime? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant DateTimeInputDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AuraDateTimeInput(
        value: _value,
        enableDate: widget.enableDate,
        enableTime: widget.enableTime,
        enabled: widget.enabled,
        semanticLabel: 'Date and time',
        onChanged: (value) => setState(() => _value = value),
        now: () => DateTime(2026, 8, 28, 12),
      ),
    );
  }
}
