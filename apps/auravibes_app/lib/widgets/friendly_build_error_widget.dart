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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: .ltr,
      child: Material(
        type: .transparency,
        child: Semantics(
          child: ExcludeSemantics(
            child: GestureDetector(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final full =
                      constraints.maxHeight.isFinite &&
                      constraints.maxHeight >= 320 &&
                      constraints.maxWidth.isFinite &&
                      constraints.maxWidth >= 300;

                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(full ? 0 : 28),
                    ),
                    width: constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : null,
                    height: constraints.hasBoundedHeight
                        ? constraints.maxHeight
                        : null,
                    child: full
                        ? _FullView(details: widget.details, copied: _copied)
                        : _CompactView(
                            details: widget.details,
                            copied: _copied,
                          ),
                  );
                },
              ),
              onLongPress: () => unawaited(_copy()),
              behavior: .opaque,
            ),
          ),
          container: true,
          label: _friendlyErrorSemantics(context),
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await HapticFeedback.mediumImpact();
    await Clipboard.setData(
      .new(
        text:
            '${widget.details.exceptionAsString()}\n\n${widget.details.stack}',
      ),
    );

    if (!mounted) return;

    setState(() => _copied = true);
    _timer?.cancel();
    _timer = .new(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _copied = false);
    });
  }
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Widget header = Column(
      mainAxisSize: .min,
      children: [
        _Badge(size: 104, copied: copied),
        const SizedBox(height: 24),
        Text(
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
        ),
        const SizedBox(height: 8),
        Text(
          _friendlyErrorText(
            context,
            LocaleKeys.common_error_message,
            'Restarting the app should fix it.',
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
          ),
          textAlign: .center,
        ),
      ],
    );

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              (MediaQuery.maybePaddingOf(context)?.top ?? 0) + 32,
              32,
              (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + 32,
            ),
            child: Column(
              mainAxisAlignment: .center,
              children: [
                header,
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  _DebugText(
                    '${details.exceptionAsString()}\n\n${details.stack}',
                  ),
                ],
              ],
            ),
          ),
          hasScrollBody: false,
        ),
      ],
    );
  }
}

class const _CompactView({
  required final FlutterErrorDetails details,
  required final bool copied,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: FittedBox(
        fit: .scaleDown,
        child: Column(
          mainAxisSize: .min,
          children: [
            _Badge(size: 48, copied: copied),
            if (kDebugMode) ...[
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
          ],
        ),
      ),
    ),
  );
}

class const _Badge({required final double size, required final bool copied})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: ShapeDecoration(
        color: colorScheme.primary,
        shape: const StarBorder(
          points: 12,
          innerRadiusRatio: 0.8,
          pointRounding: 0.7,
          valleyRounding: 0.3,
        ),
      ),
      width: size,
      height: size,
      child: AnimatedSwitcher(
        child: Icon(
          copied ? Icons.check_rounded : Icons.priority_high_rounded,
          key: ValueKey<bool>(copied),
          size: size * 0.4,
          color: colorScheme.onPrimary,
        ),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class const _DebugText(
  final String text, {
  final int? maxLines,
  final TextAlign? textAlign,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: .new(
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
        fontSize: 12,
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier'],
      ),
      textAlign: textAlign,
      overflow: maxLines == null ? .fade : .ellipsis,
      maxLines: maxLines,
    );
  }
}
