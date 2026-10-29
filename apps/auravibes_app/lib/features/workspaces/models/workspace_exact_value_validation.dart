const _hoursPerDay = 24;
const _minutesPerHour = 60;
const _maximumAmountLength = 16384;
const _hourGroup = 2;
const _dateGroup = 1;
const _moneyFieldCount = 2;
const _minuteGroup = 3;
const _secondGroup = 4;

abstract final class WorkspaceExactValueValidation {
  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _instant = RegExp(
    r'^(\d{4}-\d{2}-\d{2})T'
    r'(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?Z$',
  );
  static bool date(Object? value) {
    if (value is! String || !_date.hasMatch(value)) return false;
    final parsed = DateTime.tryParse('${value}T00:00:00Z');

    return parsed != null && parsed.toIso8601String().split('T').first == value;
  }

  static bool timestamp(Object? value) {
    if (value is! String) return false;
    final match = _instant.firstMatch(value);
    if (match == null || !date(match.group(_dateGroup))) return false;

    return _validClock(match);
  }

  static bool money(Object? value) {
    if (value is! Map || value.length != _moneyFieldCount) return false;
    final amount = value['amount'];
    final currency = value['currency'];

    return amount is String &&
        amount.length <= _maximumAmountLength &&
        RegExp(r'^-?(?:0|[1-9]\d*)(?:\.\d+)?$').hasMatch(amount) &&
        currency is String &&
        RegExp(r'^[A-Z]{3}$').hasMatch(currency);
  }

  static bool _validClock(RegExpMatch match) =>
      _clock(match, _hourGroup, _hoursPerDay) &&
      _clock(match, _minuteGroup, _minutesPerHour) &&
      _clock(match, _secondGroup, _minutesPerHour);

  static bool _clock(RegExpMatch match, int group, int maximum) =>
      int.parse(match.group(group) ?? '') < maximum;
}
