part of 'aura_date_time_input.dart';

/// Caller-provided visible and semantic strings used by [AuraDateTimeInput].
class AuraDateTimeInputLabels {
  /// Creates localized date/time picker labels.
  const new({
    this.selectDateAndTime = 'Select date and time',
    this.selectDate = 'Select date',
    this.selectTime = 'Select time',
    this.dateAndTime = 'Date and time',
    this.date = 'Date',
    this.time = 'Time',
    this.cancel = 'Cancel',
    this.done = 'Done',
    this.previousMonth = 'Previous month',
    this.nextMonth = 'Next month',
    this.decreaseHour = 'Decrease hour',
    this.increaseHour = 'Increase hour',
    this.decreaseMinute = 'Decrease minute',
    this.increaseMinute = 'Increase minute',
    this.weekdayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
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
}
