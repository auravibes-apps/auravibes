import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';

abstract final class WorkspaceDateTimeLabels {
  static AuraDateTimeInputLabels date() => AuraDateTimeInputLabels(
    selectDate: LocaleKeys.workspace_items_select_date.tr(),
    date: LocaleKeys.workspace_items_date.tr(),
    cancel: LocaleKeys.workspace_items_cancel.tr(),
    done: LocaleKeys.workspace_items_done.tr(),
    previousMonth: LocaleKeys.workspace_items_previous_month.tr(),
    nextMonth: LocaleKeys.workspace_items_next_month.tr(),
    weekdayLabels: LocaleKeys.workspace_items_weekdays.tr().split(','),
  );

  static AuraDateTimeInputLabels time() => AuraDateTimeInputLabels(
    selectTime: LocaleKeys.workspace_items_select_time.tr(),
    time: LocaleKeys.workspace_items_time.tr(),
    cancel: LocaleKeys.workspace_items_cancel.tr(),
    done: LocaleKeys.workspace_items_done.tr(),
    decreaseHour: LocaleKeys.workspace_items_decrease_hour.tr(),
    increaseHour: LocaleKeys.workspace_items_increase_hour.tr(),
    decreaseMinute: LocaleKeys.workspace_items_decrease_minute.tr(),
    increaseMinute: LocaleKeys.workspace_items_increase_minute.tr(),
  );
}
