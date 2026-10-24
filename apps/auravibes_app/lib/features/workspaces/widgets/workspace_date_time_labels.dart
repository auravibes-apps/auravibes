import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';

class const WorkspaceDateTimeLabels() extends AuraDateTimeInputLabels {
  @override
  String get selectDateAndTime =>
      LocaleKeys.workspace_items_select_date_time.tr();
  @override
  String get selectDate => LocaleKeys.workspace_items_select_date.tr();
  @override
  String get selectTime => LocaleKeys.workspace_items_select_time.tr();
  @override
  String get dateAndTime => LocaleKeys.workspace_items_date_and_time.tr();
  @override
  String get date => LocaleKeys.workspace_items_date.tr();
  @override
  String get time => LocaleKeys.workspace_items_time.tr();
  @override
  String get cancel => LocaleKeys.workspace_items_cancel.tr();
  @override
  String get done => LocaleKeys.workspace_items_done.tr();
  @override
  String get previousMonth => LocaleKeys.workspace_items_previous_month.tr();
  @override
  String get nextMonth => LocaleKeys.workspace_items_next_month.tr();
  @override
  String get decreaseHour => LocaleKeys.workspace_items_decrease_hour.tr();
  @override
  String get increaseHour => LocaleKeys.workspace_items_increase_hour.tr();
  @override
  String get decreaseMinute => LocaleKeys.workspace_items_decrease_minute.tr();
  @override
  String get increaseMinute => LocaleKeys.workspace_items_increase_minute.tr();
  @override
  List<String> get weekdayLabels =>
      LocaleKeys.workspace_items_weekdays.tr().split(',');
}
