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

typedef _PickerDialogRequest = ({
  AuraDateTimeInput input,
  DateTime initialValue,
  ValueListenable<_PickerEnvironment> environment,
  CapturedThemes capturedThemes,
  BuildContext parentContext,
});

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

  Widget _buildField(VoidCallback? onTap, {required bool isEnabled}) =>
      _AuraDateTimeInputField(input: this, onTap: onTap, isEnabled: isEnabled);

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
    if (!_canPick(context)) return;

    final pickedValue = await _showPickerDialog(context, environment);

    if (!context.mounted || pickedValue == null) return;
    onChanged?.call(pickedValue);
  }

  bool _canPick(BuildContext context) =>
      enabled && AuraInteractionScope.of(context).allowsValueChanges;

  Future<DateTime?> _showPickerDialog(
    BuildContext context,
    ValueListenable<_PickerEnvironment> environment,
  ) => _openPickerDialog(_pickerDialogRequest(context, environment));

  _PickerDialogRequest _pickerDialogRequest(
    BuildContext context,
    ValueListenable<_PickerEnvironment> environment,
  ) {
    return (
      input: this,
      initialValue: _initialPickerValue(),
      environment: environment,
      capturedThemes: _capturedPickerThemes(context),
      parentContext: context,
    );
  }

  DateTime _initialPickerValue() =>
      _constrain(_normalise(value ?? (now?.call() ?? DateTime.now())));

  CapturedThemes _capturedPickerThemes(BuildContext context) {
    final navigator = Navigator.of(context);

    return InheritedTheme.capture(from: context, to: navigator.context);
  }

  Future<DateTime?> _openPickerDialog(_PickerDialogRequest request) =>
      showGeneralDialog<DateTime>(
        context: request.parentContext,
        pageBuilder: (_, _, _) => _AuraDateTimePickerPage(request: request),
        barrierColor: request.parentContext.auraColors.scrim,
        useRootNavigator: false,
      );

  Widget _buildPickerDialog({
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    required VoidCallback onCancel,
    required VoidCallback onDone,
  }) => _AuraDateTimePickerDialog(
    input: this,
    value: value,
    onChanged: onChanged,
    onCancel: onCancel,
    onDone: onDone,
  );

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
    final day = _clampMonthDay(
      value.day,
      DateTime(month.year, month.month + 1, 0).day,
    );

    return DateTime(month.year, month.month, day, value.hour, value.minute);
  }

  int _clampMonthDay(int day, int lastDay) => day > lastDay ? lastDay : day;

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

class const _AuraDateTimeInputField({
  required final AuraDateTimeInput input,
  required final VoidCallback? onTap,
  required final bool isEnabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final displayValue = input._displayValue();

    return Semantics(
      child: _AuraDateTimeInputFieldSurface(
        input: input,
        onTap: onTap,
        isEnabled: isEnabled,
        displayValue: displayValue,
      ),
      excludeSemantics: true,
      enabled: isEnabled,
      button: true,
      label: input.semanticLabel ?? displayValue,
      value: displayValue,
    );
  }
}

class const _AuraDateTimeInputFieldSurface({
  required final AuraDateTimeInput input,
  required final VoidCallback? onTap,
  required final bool isEnabled,
  required final String displayValue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraFieldWrapper(
    child: _AuraDateTimeInputFieldContent(
      input: input,
      displayValue: displayValue,
    ),
    isEnabled: isEnabled,
    onTap: isEnabled ? onTap : null,
  );
}

class const _AuraDateTimeInputFieldContent({
  required final AuraDateTimeInput input,
  required final String displayValue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: DesignInputSizes.paddingMd,
    child: Row(
      children: [
        Expanded(child: AuraText(child: Text(displayValue))),
        const AuraSizedBox(width: .sm),
        _AuraDateTimeInputMode(input: input),
      ],
    ),
  );
}

class const _AuraDateTimeInputMode({required final AuraDateTimeInput input})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      input.enableDate && input.enableTime
          ? input.labels.dateAndTime
          : input._modeLabel(),
    ),
    style: .bodySmall,
  );
}

class const _AuraDateTimePickerPage({
  required final _PickerDialogRequest request,
}) extends StatefulWidget {
  @override
  State<_AuraDateTimePickerPage> createState() =>
      _AuraDateTimePickerPageState();
}

class _AuraDateTimePickerPageState extends State<_AuraDateTimePickerPage> {
  DateTime? _draftValue;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return ValueListenableBuilder<_PickerEnvironment>(
      valueListenable: request.environment,
      builder: (_, currentEnvironment, _) => _AuraDateTimePickerEnvironment(
        page: this,
        environment: currentEnvironment,
      ),
    );
  }

  void _updateValue(DateTime value) => setState(() => _draftValue = value);

  void _cancel() => Navigator.of(widget.request.parentContext).pop();

  void _done() {
    final value = _draftValue ?? widget.request.initialValue;
    Navigator.of(widget.request.parentContext).pop(
      widget.request.input._constrain(widget.request.input._normalise(value)),
    );
  }
}

class const _AuraDateTimePickerDialog({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('auraDateTimeInputPicker'),
    child: SafeArea(
      child: _AuraDateTimePickerCard(
        input: input,
        value: value,
        onChanged: onChanged,
        onCancel: onCancel,
        onDone: onDone,
      ),
    ),
    explicitChildNodes: true,
    scopesRoute: true,
    namesRoute: true,
    label: input._pickerTitle(),
  );
}

class const _AuraDateTimePickerEnvironment({
  required final _AuraDateTimePickerPageState page,
  required final _PickerEnvironment environment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final request = page.widget.request;
    final value = page._draftValue ??= request.initialValue;

    return _AuraDateTimePickerLocale(
      request: request,
      page: page,
      environment: environment,
      value: value,
    );
  }
}

class const _AuraDateTimePickerLocale({
  required final _PickerDialogRequest request,
  required final _AuraDateTimePickerPageState page,
  required final _PickerEnvironment environment,
  required final DateTime value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => request.capturedThemes.wrap(
    _AuraDateTimePickerLocalized(
      request: request,
      page: page,
      environment: environment,
      value: value,
    ),
  );
}

class const _AuraDateTimePickerLocalized({
  required final _PickerDialogRequest request,
  required final _AuraDateTimePickerPageState page,
  required final _PickerEnvironment environment,
  required final DateTime value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Localizations.override(
    context: request.parentContext,
    locale: environment.locale,
    child: _AuraDateTimePickerThemeContent(
      request: request,
      page: page,
      environment: environment,
      value: value,
    ),
  );
}

class const _AuraDateTimePickerThemeContent({
  required final _PickerDialogRequest request,
  required final _AuraDateTimePickerPageState page,
  required final _PickerEnvironment environment,
  required final DateTime value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraDateTimePickerTheme(
    input: request.input,
    value: value,
    onChanged: page._updateValue,
    onCancel: page._cancel,
    onDone: page._done,
    theme: environment.theme,
    textDirection: environment.textDirection,
    mediaQuery: environment.mediaQuery,
  );
}

class const _AuraDateTimePickerTheme({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
  required final ThemeData theme,
  required final TextDirection textDirection,
  required final MediaQueryData mediaQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Theme(
    data: theme,
    child: _AuraDateTimePickerDirectionality(
      input: input,
      value: value,
      onChanged: onChanged,
      onCancel: onCancel,
      onDone: onDone,
      textDirection: textDirection,
      mediaQuery: mediaQuery,
    ),
  );
}

class const _AuraDateTimePickerDirectionality({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
  required final TextDirection textDirection,
  required final MediaQueryData mediaQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: textDirection,
    child: _AuraDateTimePickerMediaQuery(
      input: input,
      value: value,
      onChanged: onChanged,
      onCancel: onCancel,
      onDone: onDone,
      mediaQuery: mediaQuery,
    ),
  );
}

class const _AuraDateTimePickerMediaQuery({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
  required final MediaQueryData mediaQuery,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MediaQuery(
    data: mediaQuery,
    child: input._buildPickerDialog(
      value: value,
      onChanged: onChanged,
      onCancel: onCancel,
      onDone: onDone,
    ),
  );
}

class const _AuraDateTimePickerCard({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AuraDateTimeInput._pickerPadding),
      child: _AuraDateTimePickerSurface(
        input: input,
        value: value,
        onChanged: onChanged,
        onCancel: onCancel,
        onDone: onDone,
      ),
    ),
  );
}

class const _AuraDateTimePickerSurface({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: AuraDateTimeInput._pickerMaxWidth,
    ),
    child: _AuraDateTimePickerFrame(
      input: input,
      value: value,
      onChanged: onChanged,
      onCancel: onCancel,
      onDone: onDone,
    ),
  );
}

class const _AuraDateTimePickerFrame({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return _AuraDateTimePickerFrameSurface(
      input: input,
      value: value,
      colors: colors,
      onChanged: onChanged,
      onCancel: onCancel,
      onDone: onDone,
    );
  }
}

class const _AuraDateTimePickerBody({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final AuraColorScheme colors,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _AuraDateTimePickerHeader(
        input: input,
        colors: colors,
        onCancel: onCancel,
        onDone: onDone,
      ),
      const AuraSizedBox(height: .md),
      _AuraDateTimePickerSelection(
        input: input,
        value: value,
        colors: colors,
        onChanged: onChanged,
      ),
    ],
  );
}

class const _AuraDateTimePickerHeader({
  required final AuraDateTimeInput input,
  required final AuraColorScheme colors,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AuraText(child: Text(input._pickerTitle()), style: .heading6),
      const AuraSizedBox(height: .md),
      _AuraDateTimePickerActions(
        input: input,
        colors: colors,
        onCancel: onCancel,
        onDone: onDone,
      ),
    ],
  );
}

class const _AuraDateTimePickerSelection({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final AuraColorScheme colors,
  required final ValueChanged<DateTime> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (input.enableDate)
        _DatePicker(
          input: input,
          value: value,
          colors: colors,
          onChanged: onChanged,
        ),
      if (input.enableDate && input.enableTime) const AuraSizedBox(height: .md),
      if (input.enableTime)
        _TimePicker(input: input, value: value, onChanged: onChanged),
    ],
  );
}

class const _AuraDateTimePickerActions({
  required final AuraDateTimeInput input,
  required final AuraColorScheme colors,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: .end,
    spacing: AuraDateTimeInput._pickerButtonSpacing,
    children: [
      _AuraDateTimePickerCancelButton(
        input: input,
        colors: colors,
        onPressed: onCancel,
      ),
      _AuraDateTimePickerDoneButton(
        input: input,
        colors: colors,
        onPressed: onDone,
      ),
    ],
  );
}

class const _AuraDateTimePickerCancelButton({
  required final AuraDateTimeInput input,
  required final AuraColorScheme colors,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PickerButton(
    label: input.labels.cancel,
    onPressed: onPressed,
    child: Text(
      input.labels.cancel,
      style: .new(
        color: colors.primary,
        fontSize: AuraDateTimeInput._pickerActionFontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    width: AuraDateTimeInput._pickerActionWidth,
  );
}

class const _AuraDateTimePickerDoneButton({
  required final AuraDateTimeInput input,
  required final AuraColorScheme colors,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _PickerButton(
    label: input.labels.done,
    onPressed: onPressed,
    child: _AuraDateTimePickerDoneLabel(
      label: input.labels.done,
      color: colors.onPrimary,
    ),
    decoration: _doneDecoration(context, colors),
    width: AuraDateTimeInput._pickerActionWidth,
  );

  Decoration _doneDecoration(BuildContext context, AuraColorScheme colors) =>
      BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(.md),
        ),
      );
}

class const _AuraDateTimePickerDoneLabel({
  required final String label,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: .new(
      color: color,
      fontSize: AuraDateTimeInput._pickerActionFontSize,
      fontWeight: FontWeight.w600,
    ),
  );
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

    return _AuraDateTimeInputHostContent(
      input: widget.input,
      environment: environment,
    );
  }
}

class const _AuraDateTimePickerFrameSurface({
  required final AuraDateTimeInput input,
  required final DateTime value,
  required final AuraColorScheme colors,
  required final ValueChanged<DateTime> onChanged,
  required final VoidCallback onCancel,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _pickerDecoration(context, colors),
    child: Padding(
      padding: const EdgeInsets.all(AuraDateTimeInput._pickerPadding),
      child: _AuraDateTimePickerBody(
        input: input,
        value: value,
        colors: colors,
        onChanged: onChanged,
        onCancel: onCancel,
        onDone: onDone,
      ),
    ),
  );

  Decoration _pickerDecoration(BuildContext context, AuraColorScheme colors) =>
      BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.2),
            blurRadius: AuraDateTimeInput._pickerShadowBlurRadius,
          ),
        ],
      );
}

class const _AuraDateTimeInputHostContent({
  required final AuraDateTimeInput input,
  required final ValueListenable<_PickerEnvironment> environment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isEnabled =
        input.enabled && AuraInteractionScope.of(context).allowsValueChanges;

    return input._buildField(
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
