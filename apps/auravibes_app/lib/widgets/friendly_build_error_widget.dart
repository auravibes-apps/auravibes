import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show FlutterErrorDetails, kDebugMode;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Friendly replacement for Flutter's build error view.
///
/// Release builds hide exception details; debug builds show them. Long press
/// anywhere to copy the exception and stack trace for support.
class const FriendlyBuildErrorWidget({
  required final FlutterErrorDetails details,
  super.key,
}) extends StatefulWidget {
  @override
  State<FriendlyBuildErrorWidget> createState() =>
      _FriendlyBuildErrorWidgetState();
}

class _FriendlyBuildErrorWidgetState extends State<FriendlyBuildErrorWidget> {
  Timer? _timer;
  var _copied = false;

  String get _errorDetailsText =>
      '${widget.details.exceptionAsString()}\n\n${widget.details.stack}';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FriendlyErrorFrame(
      details: widget.details,
      copied: _copied,
      onCopy: () => unawaited(_copy()),
    );
  }

  Future<void> _copy() async {
    await _copyErrorDetails();

    if (!mounted) return;

    _showCopiedConfirmation();
  }

  Future<void> _copyErrorDetails() async {
    await HapticFeedback.mediumImpact();
    await Clipboard.setData(.new(text: _errorDetailsText));
  }

  void _showCopiedConfirmation() {
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = .new(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _copied = false);
    });
  }
}

class const _FriendlyErrorFrame({
  required final FlutterErrorDetails details,
  required final bool copied,
  required final VoidCallback onCopy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: .ltr,
    child: _FriendlyErrorMaterial(
      details: details,
      copied: copied,
      onCopy: onCopy,
    ),
  );
}

class const _FriendlyErrorMaterial({
  required final FlutterErrorDetails details,
  required final bool copied,
  required final VoidCallback onCopy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    type: .transparency,
    child: _FriendlyErrorSemantics(
      details: details,
      copied: copied,
      onCopy: onCopy,
    ),
  );
}

class const _FriendlyErrorSemantics({
  required final FlutterErrorDetails details,
  required final bool copied,
  required final VoidCallback onCopy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: ExcludeSemantics(
      child: _FriendlyErrorInteraction(
        details: details,
        copied: copied,
        onCopy: onCopy,
      ),
    ),
    container: true,
    label: _friendlyErrorSemantics(context),
  );
}

class const _FriendlyErrorInteraction({
  required final FlutterErrorDetails details,
  required final bool copied,
  required final VoidCallback onCopy,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: LayoutBuilder(
      builder: (context, constraints) => _FriendlyErrorLayout(
        constraints: constraints,
        details: details,
        copied: copied,
        colorScheme: Theme.of(context).colorScheme,
      ),
    ),
    onLongPress: onCopy,
    behavior: .opaque,
  );
}

class const _FriendlyErrorLayout({
  required final BoxConstraints constraints,
  required final FlutterErrorDetails details,
  required final bool copied,
  required final ColorScheme colorScheme,
}) extends StatelessWidget {
  bool get _fullView => _hasFullViewSpace(constraints);

  @override
  Widget build(BuildContext context) => _FriendlyErrorSurface(
    constraints: constraints,
    details: details,
    copied: copied,
    colorScheme: colorScheme,
    full: _fullView,
  );

  bool _hasFullViewSpace(BoxConstraints constraints) =>
      constraints.maxHeight.isFinite &&
      constraints.maxHeight >= 320 &&
      constraints.maxWidth.isFinite &&
      constraints.maxWidth >= 300;
}

class const _FriendlyErrorSurface({
  required final BoxConstraints constraints,
  required final FlutterErrorDetails details,
  required final bool copied,
  required final ColorScheme colorScheme,
  required final bool full,
}) extends StatelessWidget {
  static const _compactCornerRadius = 28.0;

  double? get _width =>
      constraints.hasBoundedWidth ? constraints.maxWidth : null;
  double? get _height =>
      constraints.hasBoundedHeight ? constraints.maxHeight : null;
  BorderRadius get _borderRadius =>
      BorderRadius.circular(full ? 0 : _compactCornerRadius);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: colorScheme.primaryContainer,
      borderRadius: _borderRadius,
    ),
    width: _width,
    height: _height,
    child: _FriendlyErrorContent(details: details, copied: copied, full: full),
  );
}

class const _FriendlyErrorContent({
  required final FlutterErrorDetails details,
  required final bool copied,
  required final bool full,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => full
      ? _FullView(details: details, copied: copied)
      : _CompactView(details: details, copied: copied);
}

String _friendlyErrorText(
  BuildContext context,
  String localeKey,
  String fallback,
) => EasyLocalization.of(context) == null
    ? fallback
    : localeKey.tr(context: context);

String _friendlyErrorSemantics(BuildContext context) {
  final title = _friendlyErrorText(
    context,
    LocaleKeys.common_error_title,
    'Something went wrong',
  );
  final message = _friendlyErrorText(
    context,
    LocaleKeys.common_error_message,
    'Restarting the app should fix it.',
  );

  return '$title. $message';
}

class const _FullView({
  required final FlutterErrorDetails details,
  required final bool copied,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        child: _FullViewPadding(details: details, copied: copied),
        hasScrollBody: false,
      ),
    ],
  );
}

class const _FullViewPadding({
  required final FlutterErrorDetails details,
  required final bool copied,
}) extends StatelessWidget {
  static const _contentPadding = 32.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      _contentPadding,
      (MediaQuery.maybePaddingOf(context)?.top ?? 0) + _contentPadding,
      _contentPadding,
      (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + _contentPadding,
    ),
    child: _FullViewContent(details: details, copied: copied),
  );
}

class const _FullViewContent({
  required final FlutterErrorDetails details,
  required final bool copied,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: .center,
    children: [
      _FullViewHeader(copied: copied),
      if (kDebugMode) ...[
        const SizedBox(height: 32),
        _DebugText('${details.exceptionAsString()}\n\n${details.stack}'),
      ],
    ],
  );
}

class const _FullViewHeader({required final bool copied})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: .min,
      children: [
        _Badge(size: 104, copied: copied),
        const SizedBox(height: 24),
        _FullViewTitle(colorScheme: colorScheme, textTheme: textTheme),
        const SizedBox(height: 8),
        _FullViewMessage(colorScheme: colorScheme, textTheme: textTheme),
      ],
    );
  }
}

class const _FullViewTitle({
  required final ColorScheme colorScheme,
  required final TextTheme textTheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    _friendlyErrorText(
      context,
      LocaleKeys.common_error_title,
      'Something went wrong',
    ),
    style: textTheme.titleLarge?.copyWith(
      color: colorScheme.onPrimaryContainer,
      fontWeight: .w700,
    ),
    textAlign: .center,
  );
}

class const _FullViewMessage({
  required final ColorScheme colorScheme,
  required final TextTheme textTheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    _friendlyErrorText(
      context,
      LocaleKeys.common_error_message,
      'Restarting the app should fix it.',
    ),
    style: textTheme.bodyMedium?.copyWith(
      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
    ),
    textAlign: .center,
  );
}

class const _CompactView({
  required final FlutterErrorDetails details,
  required final bool copied,
}) extends StatelessWidget {
  static const _contentPadding = 12.0;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(_contentPadding),
      child: FittedBox(
        fit: .scaleDown,
        child: Column(
          mainAxisSize: .min,
          children: [
            _Badge(size: 48, copied: copied),
            if (kDebugMode) _CompactDebugDetails(details: details),
          ],
        ),
      ),
    ),
  );
}

class const _CompactDebugDetails({required final FlutterErrorDetails details})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 8),
      SizedBox(
        width: 240,
        child: _DebugText(
          details.exceptionAsString(),
          maxLines: 2,
          textAlign: .center,
        ),
      ),
    ],
  );
}

class const _Badge({required final double size, required final bool copied})
    extends StatelessWidget {
  static const _starPoints = 12.0;
  static const _innerRadiusRatio = 0.8;
  static const _pointRounding = 0.7;
  static const _valleyRounding = 0.3;
  static const _shape = StarBorder(
    points: _starPoints,
    innerRadiusRatio: _innerRadiusRatio,
    pointRounding: _pointRounding,
    valleyRounding: _valleyRounding,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: ShapeDecoration(color: colorScheme.primary, shape: _shape),
      width: size,
      height: size,
      child: _BadgeIcon(size: size, copied: copied),
    );
  }
}

class const _BadgeIcon({required final double size, required final bool copied})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    child: Icon(
      copied ? Icons.check_rounded : Icons.priority_high_rounded,
      key: ValueKey<bool>(copied),
      size: size * 0.4,
      color: Theme.of(context).colorScheme.onPrimary,
    ),
    duration: const Duration(milliseconds: 200),
  );
}

class const _DebugText(
  final String text, {
  final int? maxLines,
  final TextAlign? textAlign,
}) extends StatelessWidget {
  static const _debugFontSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: .new(
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
        fontSize: _debugFontSize,
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier'],
      ),
      textAlign: textAlign,
      overflow: maxLines == null ? .fade : .ellipsis,
      maxLines: maxLines,
    );
  }
}
