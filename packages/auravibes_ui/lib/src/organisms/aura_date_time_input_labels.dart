part of 'aura_date_time_input.dart';

/// Caller-provided visible and semantic strings used by [AuraDateTimeInput].
class AuraDateTimeInputLabels {
  /// Creates optional overrides for date/time picker labels.
  ///
  /// Empty values use the host's Material localizations, falling back to
  /// Flutter's default English localizations when none are provided.
  const new({
    this.selectDateAndTime = '',
    this.selectDate = '',
    this.selectTime = '',
    this.dateAndTime = '',
    this.date = '',
    this.time = '',
    this.cancel = '',
    this.done = '',
    this.previousMonth = '',
    this.nextMonth = '',
    this.decreaseHour = '',
    this.increaseHour = '',
    this.decreaseMinute = '',
    this.increaseMinute = '',
    this.weekdayLabels = const [],
    this.dayLabelBuilder,
  });

  /// Label for a date and time picker.
  final String selectDateAndTime;

  /// Label for a date picker.
  final String selectDate;

  /// Label for a time picker.
  final String selectTime;

  /// Label for combined date and time mode.
  final String dateAndTime;

  /// Label for date-only mode.
  final String date;

  /// Label for time-only mode.
  final String time;

  /// Confirmation cancellation label.
  final String cancel;

  /// Confirmation completion label.
  final String done;

  /// Previous-month control label.
  final String previousMonth;

  /// Next-month control label.
  final String nextMonth;

  /// Decrease-hour control label.
  final String decreaseHour;

  /// Increase-hour control label.
  final String increaseHour;

  /// Decrease-minute control label.
  final String decreaseMinute;

  /// Increase-minute control label.
  final String increaseMinute;

  /// Short weekday labels from Monday through Sunday.
  final List<String> weekdayLabels;

  /// Builds a semantic label for a calendar day.
  final String Function(int day)? dayLabelBuilder;

  /// Whether callers provided a custom day-label builder.
  bool hasCustomDayLabels() => dayLabelBuilder != null;

  AuraDateTimeInputLabels _resolved(BuildContext context) =>
      _ResolvedDateTimeInputLabels(
        this,
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ??
            const DefaultMaterialLocalizations(),
      );
}

class _ResolvedDateTimeInputLabels extends AuraDateTimeInputLabels {
  new(AuraDateTimeInputLabels labels, MaterialLocalizations localizations)
    : super(
        selectDateAndTime: _label(
          labels.selectDateAndTime,
          '${localizations.datePickerHelpText}, '
          '${localizations.timePickerDialHelpText}',
        ),
        selectDate: _label(labels.selectDate, localizations.datePickerHelpText),
        selectTime: _label(
          labels.selectTime,
          localizations.timePickerDialHelpText,
        ),
        dateAndTime: _label(
          labels.dateAndTime,
          '${localizations.unspecifiedDate}, '
          '${localizations.timePickerHourLabel} / '
          '${localizations.timePickerMinuteLabel}',
        ),
        date: _label(labels.date, localizations.unspecifiedDate),
        time: _label(
          labels.time,
          '${localizations.timePickerHourLabel} / '
          '${localizations.timePickerMinuteLabel}',
        ),
        cancel: _label(labels.cancel, localizations.cancelButtonLabel),
        done: _label(labels.done, localizations.okButtonLabel),
        previousMonth: _label(
          labels.previousMonth,
          localizations.previousMonthTooltip,
        ),
        nextMonth: _label(labels.nextMonth, localizations.nextMonthTooltip),
        decreaseHour: _label(
          labels.decreaseHour,
          '- ${localizations.timePickerHourLabel}',
        ),
        increaseHour: _label(
          labels.increaseHour,
          '+ ${localizations.timePickerHourLabel}',
        ),
        decreaseMinute: _label(
          labels.decreaseMinute,
          '- ${localizations.timePickerMinuteLabel}',
        ),
        increaseMinute: _label(
          labels.increaseMinute,
          '+ ${localizations.timePickerMinuteLabel}',
        ),
        weekdayLabels: labels.weekdayLabels.isEmpty
            ? [
                ...localizations.narrowWeekdays.skip(1),
                ...localizations.narrowWeekdays.take(1),
              ]
            : labels.weekdayLabels,
        dayLabelBuilder: labels.dayLabelBuilder,
      );
}

String _label(String value, String fallback) =>
    value.isEmpty ? fallback : value;
