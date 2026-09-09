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
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final controlRadius = context.auraTheme.fromBorderRadius(.md);

    return Semantics(
      child: AuraPressable(
        child: SizedBox(
          width: width,
          height: AuraDateTimeInput._pickerControlHeight,
          child: Center(child: child),
        ),
        color: colors.primary.withValues(alpha: 0.16),
        decoration:
            decoration ??
            BoxDecoration(
              border: Border.fromBorderSide(.new(color: colors.outlineVariant)),
              borderRadius: BorderRadius.circular(controlRadius),
            ),
        onPressed: onPressed,
      ),
      selected: selected,
      button: true,
      label: label,
    );
  }
}

class const _DatePicker({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final AuraColorScheme colors,
  required final ValueChanged<DateTime> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = input.labels;
    final firstDay = DateTime(value.year, value.month);
    final daysInMonth = DateTime(value.year, value.month + 1, 0).day;
    final days = <Widget>[
      for (var index = 1; index < firstDay.weekday; index++)
        const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _PickerButton(
          label: labels.dayLabelBuilder?.call(day) ?? 'Day $day',
          onPressed: () => _selectDay(day),
          child: Text(
            '$day',
            style: .new(
              color: day == value.day ? colors.onPrimary : colors.onSurface,
              fontSize: AuraDateTimeInput._pickerDayFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          decoration: BoxDecoration(
            color: day == value.day ? colors.primary : null,
            border: day == value.day
                ? null
                : Border.fromBorderSide(.new(color: colors.outlineVariant)),
            shape: .circle,
          ),
          selected: day == value.day,
        ),
    ];

    return Column(
      children: [
        Row(
          children: [
            _PickerButton(
              label: labels.previousMonth,
              onPressed: () => onChanged(input._changeMonth(value, -1)),
              child: Text(
                '<',
                style: .new(
                  color: colors.primary,
                  fontSize: AuraDateTimeInput._pickerControlFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: AuraText(
                  child: Text(input._formatMonth(value)),
                  style: .heading6,
                ),
              ),
            ),
            _PickerButton(
              label: labels.nextMonth,
              onPressed: () => onChanged(input._changeMonth(value, 1)),
              child: Text(
                '>',
                style: .new(
                  color: colors.primary,
                  fontSize: AuraDateTimeInput._pickerControlFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const AuraSizedBox(height: .sm),
        Row(
          mainAxisAlignment: .spaceAround,
          children: [
            for (
              var weekday = 1;
              weekday <= AuraDateTimeInput._daysPerWeek;
              weekday++
            )
              Expanded(
                child: Center(
                  child: Text(
                    labels.weekdayLabels[weekday - 1],
                    style: .new(
                      color: colors.mutedForeground,
                      fontSize: AuraDateTimeInput._pickerActionFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const AuraSizedBox(height: .xs),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: AuraDateTimeInput._daysPerWeek,
          mainAxisSpacing: AuraDateTimeInput._calendarGridSpacing,
          crossAxisSpacing: AuraDateTimeInput._calendarGridSpacing,
          children: days,
        ),
      ],
    );
  }

  void _selectDay(int day) {
    onChanged(.new(value.year, value.month, day, value.hour, value.minute));
  }
}

class const _TimePicker({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final labels = input.labels;

    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AuraText(child: Text(labels.time), style: .heading6),
        ),
        const AuraSizedBox(height: .xs),
        Wrap(
          alignment: .center,
          spacing: AuraDateTimeInput._pickerButtonSpacing,
          runSpacing: AuraDateTimeInput._pickerButtonSpacing,
          children: [
            Row(
              mainAxisSize: .min,
              children: [
                _PickerButton(
                  label: labels.decreaseHour,
                  onPressed: () => onChanged(input._changeHour(value, -1)),
                  child: Text(
                    '-',
                    style: .new(
                      color: colors.primary,
                      fontSize: AuraDateTimeInput._pickerControlFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: AuraDateTimeInput._pickerControlHeight,
                  child: Center(
                    child: Text(
                      input._twoDigits(value.hour),
                      style: .new(
                        color: colors.onSurface,
                        fontSize: AuraDateTimeInput._pickerControlFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _PickerButton(
                  label: labels.increaseHour,
                  onPressed: () => onChanged(input._changeHour(value, 1)),
                  child: Text(
                    '+',
                    style: .new(
                      color: colors.primary,
                      fontSize: AuraDateTimeInput._pickerControlFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              ':',
              style: .new(
                color: colors.onSurface,
                fontSize: AuraDateTimeInput._pickerControlFontSize,
              ),
            ),
            Row(
              mainAxisSize: .min,
              children: [
                _PickerButton(
                  label: labels.decreaseMinute,
                  onPressed: () => onChanged(input._changeMinute(value, -1)),
                  child: Text(
                    '-',
                    style: .new(
                      color: colors.primary,
                      fontSize: AuraDateTimeInput._pickerControlFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: AuraDateTimeInput._pickerControlHeight,
                  child: Center(
                    child: Text(
                      input._twoDigits(value.minute),
                      style: .new(
                        color: colors.onSurface,
                        fontSize: AuraDateTimeInput._pickerControlFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _PickerButton(
                  label: labels.increaseMinute,
                  onPressed: () => onChanged(input._changeMinute(value, 1)),
                  child: Text(
                    '+',
                    style: .new(
                      color: colors.primary,
                      fontSize: AuraDateTimeInput._pickerControlFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
