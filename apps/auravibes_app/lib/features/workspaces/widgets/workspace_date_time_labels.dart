import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';

AuraDateTimeInputLabels workspaceDateTimeLabels() => AuraDateTimeInputLabels(
  selectDateAndTime: LocaleKeys.workspace_items_select_date_time.tr(),
  selectDate: LocaleKeys.workspace_items_select_date.tr(),
  selectTime: LocaleKeys.workspace_items_select_time.tr(),
  dateAndTime: LocaleKeys.workspace_items_date_and_time.tr(),
  date: LocaleKeys.workspace_items_date.tr(),
  time: LocaleKeys.workspace_items_time.tr(),
  cancel: LocaleKeys.workspace_items_cancel.tr(),
  done: LocaleKeys.workspace_items_done.tr(),
  previousMonth: LocaleKeys.workspace_items_previous_month.tr(),
  nextMonth: LocaleKeys.workspace_items_next_month.tr(),
  decreaseHour: LocaleKeys.workspace_items_decrease_hour.tr(),
  increaseHour: LocaleKeys.workspace_items_increase_hour.tr(),
  decreaseMinute: LocaleKeys.workspace_items_decrease_minute.tr(),
  increaseMinute: LocaleKeys.workspace_items_increase_minute.tr(),
  weekdayLabels: LocaleKeys.workspace_items_weekdays.tr().split(','),
);
