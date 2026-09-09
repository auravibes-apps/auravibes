import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/organisms/aura_field_wrapper.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'aura_date_time_input_labels.dart';
part 'picker_button.dart';

/// A controlled date and/or time input using a widgets-only picker.
class AuraDateTimeInput extends StatelessWidget {
  static const _daysPerWeek = 7;
  static const _yearWidth = 4;
  static const _twoDigitWidth = 2;
  static const _pickerMaxWidth = 360.0;
  static const _pickerPadding = 16.0;
  static const _pickerControlHeight = 48.0;
  static const _pickerActionWidth = 80.0;
  static const _pickerButtonSpacing = 8.0;
  static const _pickerActionFontSize = 14.0;
  static const _pickerControlFontSize = 18.0;
  static const _pickerDayFontSize = 14.0;
  static const _pickerShadowBlurRadius = 16.0;
  static const _calendarGridSpacing = 2.0;

  /// Creates a date and/or time input.
  new({
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
    this.minimum,
    this.maximum,
  }) : assert(
         enableDate || enableTime,
         'At least one of enableDate or enableTime must be true',
       ),
       assert(
         minimum == null || maximum == null || !minimum.isAfter(maximum),
         'minimum must not be after maximum',
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

  /// Inclusive earliest value accepted when the picker is confirmed.
  final DateTime? minimum;

  /// Inclusive latest value accepted when the picker is confirmed.
  final DateTime? maximum;

  @override
  Widget build(BuildContext context) => _AuraDateTimeInputHost(input: this);

  Widget _buildField(
    BuildContext _,
    VoidCallback? onTap, {
    required bool isEnabled,
  }) {
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
                style: .bodySmall,
              ),
            ],
          ),
        ),
        isEnabled: isEnabled,
        onTap: isEnabled ? onTap : null,
      ),
      excludeSemantics: true,
      enabled: isEnabled,
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

    return '${value.year.toString().padLeft(_yearWidth, '0')}-'
        '${value.month.toString().padLeft(_twoDigitWidth, '0')}-'
        '${value.day.toString().padLeft(_twoDigitWidth, '0')}';
  }

  String _formatTime(DateTime value) {
    final formatter = timeFormatter;
    if (formatter != null) return formatter(value);

    return '${value.hour.toString().padLeft(_twoDigitWidth, '0')}:'
        '${value.minute.toString().padLeft(_twoDigitWidth, '0')}';
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
    if (!enabled || !AuraInteractionScope.of(context).allowsValueChanges) {
      return;
    }
    final initialValue = _constrain(
      _normalise(value ?? (now?.call() ?? DateTime.now())),
    );
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
                      Navigator.of(context)
                          .pop(_constrain(_normalise(draftValue))),
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
    final borderRadius = context.auraTheme.fromBorderRadius(.lg);

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
                      blurRadius: _pickerShadowBlurRadius,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_pickerPadding),
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .stretch,
                    children: [
                      AuraText(child: Text(_pickerTitle()), style: .heading6),
                      const AuraSizedBox(height: .md),
                      Wrap(
                        alignment: .end,
                        spacing: _pickerButtonSpacing,
                        children: [
                          _PickerButton(
                            label: labels.cancel,
                            onPressed: onCancel,
                            child: Text(
                              labels.cancel,
                              style: .new(
                                color: colors.primary,
                                fontSize: _pickerActionFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            width: _pickerActionWidth,
                          ),
                          _PickerButton(
                            label: labels.done,
                            onPressed: onDone,
                            child: Text(
                              labels.done,
                              style: .new(
                                color: colors.onPrimary,
                                fontSize: _pickerActionFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(
                                context.auraTheme.fromBorderRadius(.md),
                              ),
                            ),
                            width: _pickerActionWidth,
                          ),
                        ],
                      ),
                      const AuraSizedBox(height: .md),
                      if (enableDate)
                        _DatePicker(
                          input: this,
                          value: value,
                          colors: colors,
                          onChanged: onChanged,
                        ),
                      if (enableDate && enableTime)
                        const AuraSizedBox(height: .md),
                      if (enableTime)
                        _TimePicker(
                          input: this,
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

  DateTime _constrain(DateTime value) {
    final lower = minimum;
    if (lower != null && value.isBefore(lower)) return lower;
    final upper = maximum;
    if (upper != null && value.isAfter(upper)) return upper;

    return value;
  }

  String _pickerTitle() {
    if (enableDate && enableTime) return labels.selectDateAndTime;

    return enableDate ? labels.selectDate : labels.selectTime;
  }

  String _formatMonth(DateTime value) {
    return '${value.year.toString().padLeft(_yearWidth, '0')}-'
        '${value.month.toString().padLeft(_twoDigitWidth, '0')}';
  }

  String _twoDigits(int value) => value.toString().padLeft(_twoDigitWidth, '0');

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

class const _AuraDateTimeInputHost({required final AuraDateTimeInput input})
    extends StatefulWidget {
  @override
  State<_AuraDateTimeInputHost> createState() => _AuraDateTimeInputHostState();
}

class _AuraDateTimeInputHostState extends State<_AuraDateTimeInputHost> {
  ValueNotifier<_PickerEnvironment>? _environment;

  @override
  void dispose() {
    _environment?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextEnvironment = _PickerEnvironment.from(context);
    final environment = _environment;
    if (environment == null) {
      _environment = .new(nextEnvironment);
    } else if (environment.value != nextEnvironment) {
      environment.value = nextEnvironment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final environment = _environment ??= .new(_PickerEnvironment.from(context));
    final input = widget.input;
    final isEnabled =
        input.enabled && AuraInteractionScope.of(context).allowsValueChanges;

    return input._buildField(
      context,
      isEnabled ? () => input._pick(context, environment) : null,
      isEnabled: isEnabled,
    );
  }
}

@immutable
class const _PickerEnvironment({
  required final ThemeData theme,
  required final MediaQueryData mediaQuery,
  required final TextDirection textDirection,
  required final Locale locale,
}) {
  factory from(BuildContext context) {
    return _PickerEnvironment(
      theme: Theme.of(context),
      mediaQuery: MediaQuery.of(context),
      textDirection: Directionality.of(context),
      locale: Localizations.maybeLocaleOf(context) ?? const Locale('en'),
    );
  }

  @override
  int get hashCode => Object.hash(theme, mediaQuery, textDirection, locale);

  @override
  bool operator ==(Object other) {
    return other is _PickerEnvironment &&
        theme == other.theme &&
        mediaQuery == other.mediaQuery &&
        textDirection == other.textDirection &&
        locale == other.locale;
  }
}
