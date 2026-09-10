part of 'aura_date_time_input.dart';

class const _PickerButton({
  required final String label,
  required final VoidCallback onPressed,
  required final Widget child,
  final Decoration? decoration,
  final bool selected = false,
  final double width = AuraDateTimeInput._pickerControlHeight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PickerButtonSemantics(
    child: child,
    decoration: decoration,
    label: label,
    onPressed: onPressed,
    selected: selected,
    width: width,
  );
}

class const _PickerButtonSemantics({
  required final Widget child,
  required final Decoration? decoration,
  required final String label,
  required final VoidCallback onPressed,
  required final bool selected,
  required final double width,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PickerButtonThemedSurface(
    child: child,
    decoration: decoration,
    label: label,
    onPressed: onPressed,
    selected: selected,
    width: width,
  );
}

class const _PickerButtonThemedSurface({
  required final Widget child,
  required final Decoration? decoration,
  required final String label,
  required final VoidCallback onPressed,
  required final bool selected,
  required final double width,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PickerButtonThemedContent(
    child: child,
    decoration: decoration,
    label: label,
    onPressed: onPressed,
    selected: selected,
    width: width,
    colors: context.auraColors,
    borderRadius: context.auraTheme.fromBorderRadius(.md),
  );
}

class _PickerButtonThemedContent extends StatelessWidget {
  _PickerButtonThemedContent({
    required Widget child,
    required Decoration? decoration,
    required String label,
    required VoidCallback onPressed,
    required bool selected,
    required double width,
    required AuraColorScheme colors,
    required double borderRadius,
  }) : _child = _PickerButtonA11y(
         child: _PickerButtonSurface(
           child: child,
           color: colors.primary.withValues(alpha: 0.16),
           decoration:
               decoration ??
               BoxDecoration(
                 border: Border.fromBorderSide(
                   .new(color: colors.outlineVariant),
                 ),
                 borderRadius: BorderRadius.circular(borderRadius),
               ),
           onPressed: onPressed,
           width: width,
         ),
         label: label,
         selected: selected,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _PickerButtonSurface({
  required final Widget child,
  required final Color color,
  required final Decoration decoration,
  required final VoidCallback onPressed,
  required final double width,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPressable(
    child: SizedBox(
      width: width,
      height: AuraDateTimeInput._pickerControlHeight,
      child: Center(child: child),
    ),
    color: color,
    decoration: decoration,
    onPressed: onPressed,
  );
}

class const _PickerButtonA11y({
  required final Widget child,
  required final String label,
  required final bool selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Semantics(child: child, selected: selected, button: true, label: label);
}

class const _DatePicker({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final AuraColorScheme colors,
  required final ValueChanged<DateTime> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DatePickerMonthHeader(picker: this),
        const AuraSizedBox(height: .sm),
        _DatePickerWeekdayHeader(picker: this),
        const AuraSizedBox(height: .xs),
        _DatePickerGrid(picker: this),
      ],
    );
  }
}

class const _DatePickerMonthHeader({required final _DatePicker picker})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _DatePickerNavigationButton(picker: picker, previous: true),
      Expanded(
        child: Center(child: _DatePickerMonthLabel(picker: picker)),
      ),
      _DatePickerNavigationButton(picker: picker, previous: false),
    ],
  );
}

class const _DatePickerNavigationButton({
  required final _DatePicker picker,
  required final bool previous,
}) extends StatelessWidget {
  String get _label => previous
      ? picker.input.labels.previousMonth
      : picker.input.labels.nextMonth;

  String get _symbol => previous ? '<' : '>';

  @override
  Widget build(BuildContext context) => _PickerButton(
    label: _label,
    onPressed: _changeMonth,
    child: _DatePickerNavigationSymbol(
      symbol: _symbol,
      color: picker.colors.primary,
    ),
  );

  void _changeMonth() {
    picker.onChanged(
      picker.input._changeMonth(picker.value, previous ? -1 : 1),
    );
  }
}

class const _DatePickerNavigationSymbol({
  required final String symbol,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    symbol,
    style: .new(
      color: color,
      fontSize: AuraDateTimeInput._pickerControlFontSize,
      fontWeight: FontWeight.w600,
    ),
  );
}

class const _DatePickerMonthLabel({required final _DatePicker picker})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(picker.input._formatMonth(picker.value)),
    style: .heading6,
  );
}

class const _DatePickerWeekdayHeader({required final _DatePicker picker})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: .spaceAround,
    children: [
      for (final label in picker.input.labels.weekdayLabels)
        _DatePickerWeekdayLabel(label, picker.colors.mutedForeground),
    ],
  );
}

class const _DatePickerWeekdayLabel(final String label, final Color color)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(
        label,
        style: .new(
          color: color,
          fontSize: AuraDateTimeInput._pickerActionFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class const _DatePickerGrid({required final _DatePicker picker})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GridView.count(
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    crossAxisCount: AuraDateTimeInput._daysPerWeek,
    mainAxisSpacing: AuraDateTimeInput._calendarGridSpacing,
    crossAxisSpacing: AuraDateTimeInput._calendarGridSpacing,
    children: _DatePickerGridChildren(picker).children,
  );
}

class const _DatePickerGridChildren(final _DatePicker picker) {
  List<Widget> get children => buildChildren();

  List<Widget> get _emptyDays {
    final value = picker.value;
    final firstDay = DateTime(value.year, value.month);

    return [
      for (var index = 1; index < firstDay.weekday; index++)
        const SizedBox.shrink(),
    ];
  }

  List<Widget> get _dayWidgets {
    final value = picker.value;
    final daysInMonth = DateTime(value.year, value.month + 1, 0).day;

    return [
      for (var day = 1; day <= daysInMonth; day++)
        _DatePickerDay(picker: picker, day: day),
    ];
  }

  List<Widget> buildChildren() => [..._emptyDays, ..._dayWidgets];
}

class const _DatePickerDay({
  required final _DatePicker picker,
  required final int day,
}) extends StatelessWidget {
  String get _label =>
      picker.input.labels.dayLabelBuilder?.call(day) ?? 'Day $day';

  @override
  Widget build(BuildContext context) {
    final selected = day == picker.value.day;

    return _PickerButton(
      label: _label,
      onPressed: _selectDay,
      child: _DatePickerDayText(day: day, color: _color(selected)),
      decoration: _decoration(selected),
      selected: selected,
    );
  }

  Color _color(bool selected) =>
      selected ? picker.colors.onPrimary : picker.colors.onSurface;

  void _selectDay() {
    final value = picker.value;

    picker.onChanged(
      .new(value.year, value.month, day, value.hour, value.minute),
    );
  }

  Decoration _decoration(bool selected) {
    final colors = picker.colors;

    return BoxDecoration(
      color: selected ? colors.primary : null,
      border: selected
          ? null
          : Border.fromBorderSide(.new(color: colors.outlineVariant)),
      shape: .circle,
    );
  }
}

class const _DatePickerDayText({
  required final int day,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    '$day',
    style: .new(
      color: color,
      fontSize: AuraDateTimeInput._pickerDayFontSize,
      fontWeight: FontWeight.w500,
    ),
  );
}

class const _TimePicker({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimePickerTitle(label: input.labels.time),
        const AuraSizedBox(height: .xs),
        _TimePickerControls(picker: this),
      ],
    );
  }
}

class const _TimePickerTitle({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: AuraText(child: Text(label), style: .heading6),
  );
}

class const _TimePickerControls({required final _TimePicker picker})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: .center,
    spacing: AuraDateTimeInput._pickerButtonSpacing,
    runSpacing: AuraDateTimeInput._pickerButtonSpacing,
    children: [
      _TimePickerHour(picker: picker),
      _TimePickerSeparator(color: context.auraColors.onSurface),
      _TimePickerMinute(picker: picker),
    ],
  );
}

class const _TimePickerHour({required final _TimePicker picker})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _TimePickerUnit(picker: picker, hour: true);
}

class const _TimePickerMinute({required final _TimePicker picker})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _TimePickerUnit(picker: picker, hour: false);
}

class const _TimePickerUnit({
  required final _TimePicker picker,
  required final bool hour,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _TimePickerUnitLayout(
    data: .new(picker: picker, hour: hour, colors: context.auraColors),
  );
}

class const _TimePickerUnitData({
  required final _TimePicker picker,
  required final bool hour,
  required final AuraColorScheme colors,
}) {
  String get value {
    final dateTime = picker.value;

    return picker.input._twoDigits(hour ? dateTime.hour : dateTime.minute);
  }

  String get decreaseLabel => hour
      ? picker.input.labels.decreaseHour
      : picker.input.labels.decreaseMinute;

  String get increaseLabel => hour
      ? picker.input.labels.increaseHour
      : picker.input.labels.increaseMinute;

  void decrease() => picker.onChanged(_change(-1));

  void increase() => picker.onChanged(_change(1));

  @override
  String toString() => '_TimePickerUnitData(hour: $hour, value: $value)';

  DateTime _change(int delta) {
    final dateTime = picker.value;
    final input = picker.input;

    return hour
        ? input._changeHour(dateTime, delta)
        : input._changeMinute(dateTime, delta);
  }
}

class const _TimePickerUnitLayout({required final _TimePickerUnitData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      _TimePickerDecrease(data: data),
      _TimePickerValue(value: data.value, color: data.colors.onSurface),
      _TimePickerIncrease(data: data),
    ],
  );
}

class const _TimePickerDecrease({required final _TimePickerUnitData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _TimePickerAction(
    label: data.decreaseLabel,
    symbol: '-',
    colors: data.colors,
    onPressed: data.decrease,
  );
}

class const _TimePickerIncrease({required final _TimePickerUnitData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _TimePickerAction(
    label: data.increaseLabel,
    symbol: '+',
    colors: data.colors,
    onPressed: data.increase,
  );
}

class const _TimePickerValue({
  required final String value,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: AuraDateTimeInput._pickerControlHeight,
    child: Center(
      child: Text(
        value,
        style: .new(
          color: color,
          fontSize: AuraDateTimeInput._pickerControlFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class const _TimePickerAction({
  required final String label,
  required final String symbol,
  required final AuraColorScheme colors,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PickerButton(
    label: label,
    onPressed: onPressed,
    child: Text(
      symbol,
      style: .new(
        color: colors.primary,
        fontSize: AuraDateTimeInput._pickerControlFontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class const _TimePickerSeparator({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    ':',
    style: .new(
      color: color,
      fontSize: AuraDateTimeInput._pickerControlFontSize,
    ),
  );
}
