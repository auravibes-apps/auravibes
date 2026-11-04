import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/localization_context.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// App-owned translations for shared date and time controls.
abstract final class AuraDateTimeLabels {
  static AuraDateTimeInputLabels forContext(BuildContext context) {
    if (!LocalizationContext.hasAppLocalizations(context)) {
      return const AuraDateTimeInputLabels();
    }

    final dayLabel = LocaleKeys.aura_ui_day.tr(context: context);

    return _LocalizedDateTimeInputLabels(context, dayLabel);
  }
}

class _LocalizedDateTimeInputLabels extends AuraDateTimeInputLabels {
  new(BuildContext context, String dayLabel)
    : super(
        selectDateAndTime: LocaleKeys.workspace_items_select_date_time.tr(
          context: context,
        ),
        selectDate: LocaleKeys.workspace_items_select_date.tr(context: context),
        selectTime: LocaleKeys.workspace_items_select_time.tr(context: context),
        dateAndTime: LocaleKeys.workspace_items_date_and_time.tr(
          context: context,
        ),
        date: LocaleKeys.workspace_items_date.tr(context: context),
        time: LocaleKeys.workspace_items_time.tr(context: context),
        cancel: LocaleKeys.workspace_items_cancel.tr(context: context),
        done: LocaleKeys.workspace_items_done.tr(context: context),
        previousMonth: LocaleKeys.workspace_items_previous_month.tr(
          context: context,
        ),
        nextMonth: LocaleKeys.workspace_items_next_month.tr(context: context),
        decreaseHour: LocaleKeys.workspace_items_decrease_hour.tr(
          context: context,
        ),
        increaseHour: LocaleKeys.workspace_items_increase_hour.tr(
          context: context,
        ),
        decreaseMinute: LocaleKeys.workspace_items_decrease_minute.tr(
          context: context,
        ),
        increaseMinute: LocaleKeys.workspace_items_increase_minute.tr(
          context: context,
        ),
        weekdayLabels: LocaleKeys.workspace_items_weekdays
            .tr(context: context)
            .split(','),
        dayLabelBuilder: (day) => dayLabel.replaceFirst('{}', day.toString()),
      );
}
