import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/organisms/aura_field_wrapper.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Caller-provided visible and semantic strings used by [AuraDateTimeInput].
class AuraDateTimeInputLabels {
  /// Creates localized date/time picker labels.
  const AuraDateTimeInputLabels({
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

/// A controlled date and/or time input using a widgets-only picker.
class AuraDateTimeInput extends StatelessWidget {
  static const _daysPerWeek = 7;
  static const _pickerMaxWidth = 360.0;
  static const _pickerPadding = 16.0;
  static const _pickerControlHeight = 48.0;
  static const _pickerActionWidth = 80.0;
  static const _pickerButtonSpacing = 8.0;
  static const _pickerActionFontSize = 14.0;
  static const _pickerControlFontSize = 18.0;
  static const _pickerDayFontSize = 14.0;

  /// Creates a date and/or time input.
  const AuraDateTimeInput({
    super.key,
    this.value,
    this.enableDate = true,
    this.enableTime = true,
    this.enabled = true,
    this.semanticLabel,
    this.onChanged,
    this.labels = const AuraDateTimeInputLabels(),
    this.dateFormatter,
    this.timeFormatter,
    this.now,
  }) : assert(
         enableDate || enableTime,
         'At least one of enableDate or enableTime must be true',
       );

  /// The selected date and time, or null when no value is selected.
  final DateTime? value;

  /// Whether the date picker is enabled.
  final bool enableDate;

  /// Whether the time picker is enabled.
  final bool enableTime;

  /// Whether the input can be opened.
  final bool enabled;

  /// A semantic label for the input.
  final String? semanticLabel;

  /// Called with the selected date and time after the picker is confirmed.
  final ValueChanged<DateTime?>? onChanged;

  /// Visible and semantic labels used by the picker.
  final AuraDateTimeInputLabels labels;

  /// Formats the displayed date when provided.
  final String Function(DateTime value)? dateFormatter;

  /// Formats the displayed time when provided.
  final String Function(DateTime value)? timeFormatter;

  /// Supplies the current time for deterministic initial picker values.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => _AuraDateTimeInputHost(input: this);

  Widget _buildField(BuildContext _, VoidCallback onTap) {
    final displayValue = _displayValue();

    return Semantics(
      child: AuraFieldWrapper(
        child: Padding(
          padding: DesignInputSizes.paddingMd,
          child: Row(
            children: [
              Expanded(child: AuraText(child: Text(displayValue))),
              const AuraSizedBox(width: .sm),
              AuraText(
                child: Text(
                  enableDate && enableTime ? labels.dateAndTime : _modeLabel(),
                ),
                style: AuraTextStyle.bodySmall,
              ),
            ],
          ),
        ),
        isEnabled: enabled,
        onTap: enabled ? onTap : null,
      ),
      excludeSemantics: true,
      enabled: enabled,
      button: true,
      label: semanticLabel ?? displayValue,
      value: displayValue,
    );
  }

  String _displayValue() {
    final value = this.value;
    if (value == null) return _placeholder();

    final date = _formatDate(value);
    if (enableDate && enableTime) return '$date ${_formatTime(value)}';
    if (enableDate) return date;

    return _formatTime(value);
  }

  String _formatDate(DateTime value) {
    final formatter = dateFormatter;
    if (formatter != null) return formatter(value);

    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime value) {
    final formatter = timeFormatter;
    if (formatter != null) return formatter(value);

    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _placeholder() {
    if (enableDate && enableTime) return labels.selectDateAndTime;

    return enableDate ? labels.selectDate : labels.selectTime;
  }

  String _modeLabel() => enableDate ? labels.date : labels.time;

  Future<void> _pick(
    BuildContext context,
    ValueListenable<_PickerEnvironment> environment,
  ) async {
    final initialValue = _normalise(value ?? (now?.call() ?? DateTime.now()));
    final navigator = Navigator.of(context);
    final capturedThemes = InheritedTheme.capture(
      from: context,
      to: navigator.context,
    );
    final pickedValue = await showGeneralDialog<DateTime>(
      context: context,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        var draftValue = initialValue;

        return ValueListenableBuilder<_PickerEnvironment>(
          valueListenable: environment,
          builder: (pickerContext, currentEnvironment, child) {
            final picker = StatefulBuilder(
              builder: (pickerContext, setState) {
                return _buildPickerDialog(
                  context: pickerContext,
                  value: draftValue,
                  onChanged: (nextValue) {
                    setState(() => draftValue = nextValue);
                  },
                  onCancel: () => Navigator.of(context).pop(),
                  onDone: () =>
                      Navigator.of(context).pop(_normalise(draftValue)),
                );
              },
            );

            return capturedThemes.wrap(
              Localizations.override(
                context: context,
                locale: currentEnvironment.locale,
                child: Theme(
                  data: currentEnvironment.theme,
                  child: Directionality(
                    textDirection: currentEnvironment.textDirection,
                    child: MediaQuery(
                      data: currentEnvironment.mediaQuery,
                      child: picker,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      barrierColor: context.auraColors.scrim,
      useRootNavigator: false,
    );

    if (!context.mounted || pickedValue == null) return;
    onChanged?.call(pickedValue);
  }

  Widget _buildPickerDialog({
    required BuildContext context,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    required VoidCallback onCancel,
    required VoidCallback onDone,
  }) {
    final colors = context.auraColors;
    final borderRadius = context.auraTheme.fromBorderRadius(
      AuraBorderRadius.lg,
    );

    return Semantics(
      key: const ValueKey<String>('auraDateTimeInputPicker'),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_pickerPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _pickerMaxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_pickerPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuraText(
                        child: Text(_pickerTitle()),
                        style: AuraTextStyle.heading6,
                      ),
                      const AuraSizedBox(height: .md),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: _pickerButtonSpacing,
                        children: [
                          _buildPickerButton(
                            context: context,
                            label: labels.cancel,
                            onPressed: onCancel,
                            width: _pickerActionWidth,
                            child: Text(
                              labels.cancel,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: _pickerActionFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _buildPickerButton(
                            context: context,
                            label: labels.done,
                            onPressed: onDone,
                            width: _pickerActionWidth,
                            child: Text(
                              labels.done,
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: _pickerActionFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(
                                context.auraTheme.fromBorderRadius(
                                  AuraBorderRadius.md,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const AuraSizedBox(height: .md),
                      if (enableDate)
                        _buildDatePicker(
                          context: context,
                          value: value,
                          colors: colors,
                          onChanged: onChanged,
                        ),
                      if (enableDate && enableTime)
                        const AuraSizedBox(height: .md),
                      if (enableTime)
                        _buildTimePicker(
                          context: context,
                          value: value,
                          onChanged: onChanged,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: _pickerTitle(),
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required DateTime value,
    required AuraColorScheme colors,
    required ValueChanged<DateTime> onChanged,
  }) {
    final firstDay = DateTime(value.year, value.month);
    final daysInMonth = DateTime(value.year, value.month + 1, 0).day;
    final days = <Widget>[
      for (var index = 1; index < firstDay.weekday; index++)
        const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _buildPickerButton(
          context: context,
          label: labels.dayLabelBuilder?.call(day) ?? 'Day $day',
          onPressed: () {
            onChanged(
              DateTime(value.year, value.month, day, value.hour, value.minute),
            );
          },
          child: Text(
            '$day',
            style: TextStyle(
              color: day == value.day ? colors.onPrimary : colors.onSurface,
              fontSize: _pickerDayFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          decoration: BoxDecoration(
            color: day == value.day ? colors.primary : null,
            border: day == value.day
                ? null
                : Border.fromBorderSide(
                    BorderSide(color: colors.outlineVariant),
                  ),
            shape: BoxShape.circle,
          ),
          selected: day == value.day,
        ),
    ];

    return Column(
      children: [
        Row(
          children: [
            _buildPickerButton(
              context: context,
              label: labels.previousMonth,
              onPressed: () => onChanged(_changeMonth(value, -1)),
              child: Text(
                '<',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: _pickerControlFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: AuraText(
                  child: Text(_formatMonth(value)),
                  style: AuraTextStyle.heading6,
                ),
              ),
            ),
            _buildPickerButton(
              context: context,
              label: labels.nextMonth,
              onPressed: () => onChanged(_changeMonth(value, 1)),
              child: Text(
                '>',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: _pickerControlFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const AuraSizedBox(height: .sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var weekday = 1; weekday <= _daysPerWeek; weekday++)
              Expanded(
                child: Center(
                  child: Text(
                    labels.weekdayLabels[weekday - 1],
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: _pickerActionFontSize,
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
          crossAxisCount: _daysPerWeek,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: days,
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    final colors = context.auraColors;

    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AuraText(
            child: Text(labels.time),
            style: AuraTextStyle.heading6,
          ),
        ),
        const AuraSizedBox(height: .xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: _pickerButtonSpacing,
          runSpacing: _pickerButtonSpacing,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPickerButton(
                  context: context,
                  label: labels.decreaseHour,
                  onPressed: () => onChanged(_changeHour(value, -1)),
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: _pickerControlFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: _pickerControlHeight,
                  child: Center(
                    child: Text(
                      _twoDigits(value.hour),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: _pickerControlFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _buildPickerButton(
                  context: context,
                  label: labels.increaseHour,
                  onPressed: () => onChanged(_changeHour(value, 1)),
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: _pickerControlFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              ':',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: _pickerControlFontSize,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPickerButton(
                  context: context,
                  label: labels.decreaseMinute,
                  onPressed: () => onChanged(_changeMinute(value, -1)),
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: _pickerControlFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: _pickerControlHeight,
                  child: Center(
                    child: Text(
                      _twoDigits(value.minute),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: _pickerControlFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _buildPickerButton(
                  context: context,
                  label: labels.increaseMinute,
                  onPressed: () => onChanged(_changeMinute(value, 1)),
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: _pickerControlFontSize,
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

  Widget _buildPickerButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required Widget child,
    Decoration? decoration,
    bool selected = false,
    double width = _pickerControlHeight,
  }) {
    final colors = context.auraColors;
    final controlRadius = context.auraTheme.fromBorderRadius(
      AuraBorderRadius.md,
    );

    return Semantics(
      child: AuraPressable(
        child: SizedBox(
          width: width,
          height: _pickerControlHeight,
          child: Center(child: child),
        ),
        color: colors.primary.withValues(alpha: 0.16),
        decoration:
            decoration ??
            BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: colors.outlineVariant),
              ),
              borderRadius: BorderRadius.circular(controlRadius),
            ),
        onPressed: onPressed,
      ),
      selected: selected,
      button: true,
      label: label,
    );
  }

  String _pickerTitle() {
    if (enableDate && enableTime) return labels.selectDateAndTime;

    return enableDate ? labels.selectDate : labels.selectTime;
  }

  String _formatMonth(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  DateTime _changeMonth(DateTime value, int delta) {
    final month = DateTime(value.year, value.month + delta);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final day = value.day > lastDay ? lastDay : value.day;

    return DateTime(month.year, month.month, day, value.hour, value.minute);
  }

  DateTime _changeHour(DateTime value, int delta) {
    final hour = (value.hour + delta + 24) % 24;

    return DateTime(value.year, value.month, value.day, hour, value.minute);
  }

  DateTime _changeMinute(DateTime value, int delta) {
    final minute = (value.minute + delta + 60) % 60;

    return DateTime(value.year, value.month, value.day, value.hour, minute);
  }

  DateTime _normalise(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      enableTime ? value.hour : 0,
      enableTime ? value.minute : 0,
    );
  }
}

class _AuraDateTimeInputHost extends StatefulWidget {
  const _AuraDateTimeInputHost({required this.input});

  final AuraDateTimeInput input;

  @override
  State<_AuraDateTimeInputHost> createState() => _AuraDateTimeInputHostState();
}

class _AuraDateTimeInputHostState extends State<_AuraDateTimeInputHost> {
  ValueNotifier<_PickerEnvironment>? _environment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextEnvironment = _PickerEnvironment.from(context);
    final environment = _environment;
    if (environment == null) {
      _environment = ValueNotifier(nextEnvironment);
    } else if (environment.value != nextEnvironment) {
      environment.value = nextEnvironment;
    }
  }

  @override
  void dispose() {
    _environment?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final environment = _environment ??= ValueNotifier(
      _PickerEnvironment.from(context),
    );
    final input = widget.input;

    return input._buildField(context, () => input._pick(context, environment));
  }
}

@immutable
class _PickerEnvironment {
  const _PickerEnvironment({
    required this.theme,
    required this.mediaQuery,
    required this.textDirection,
    required this.locale,
  });

  factory _PickerEnvironment.from(BuildContext context) {
    return _PickerEnvironment(
      theme: Theme.of(context),
      mediaQuery: MediaQuery.of(context),
      textDirection: Directionality.of(context),
      locale: Localizations.maybeLocaleOf(context) ?? const Locale('en'),
    );
  }

  final ThemeData theme;
  final MediaQueryData mediaQuery;
  final TextDirection textDirection;
  final Locale locale;

  @override
  bool operator ==(Object other) {
    return other is _PickerEnvironment &&
        theme == other.theme &&
        mediaQuery == other.mediaQuery &&
        textDirection == other.textDirection &&
        locale == other.locale;
  }

  @override
  int get hashCode => Object.hash(theme, mediaQuery, textDirection, locale);
}
