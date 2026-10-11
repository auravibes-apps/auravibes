import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

const double _backgroundWorkListPadding = 12;
const double _backgroundWorkListSeparator = 8;
const double _backgroundWorkActionSpacing = 8;
const double _backgroundWorkActionRunSpacing = 4;
const double _backgroundWorkTileRadius = 10;
const double _backgroundWorkMessagePadding = 24;
const int _backgroundWorkTitleLines = 1;
const int _backgroundWorkPreviewLines = 3;
const int _backgroundWorkMaxPreviewCharacters = 180;
const int _minimumElapsedSeconds = 0;
const int _maximumElapsedSeconds = 999999;
const int _secondsPerMinute = 60;
const int _minutesPerHour = 60;
const int _ellipsisCodePoint = 0x2026;

typedef _BackgroundWorkListItemRequest = ({
  AgentBackgroundWork work,
  DateTime now,
  Future<void> Function(AgentBackgroundWork) onStop,
  Future<void> Function(AgentBackgroundWork) onOpenResult,
});

class const BackgroundWorkListView({
  required final List<AgentBackgroundWork> works,
  required final Future<void> Function(AgentBackgroundWork work) onStop,
  required final Future<void> Function(AgentBackgroundWork work) onOpenResult,
  final DateTime? now,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentTime = now ?? DateTime.now();

    return ListView.separated(
      key: const ValueKey('background_work_list'),
      padding: const EdgeInsets.all(_backgroundWorkListPadding),
      itemBuilder: (_, index) => _buildBackgroundWorkListItem((
        work: works[index],
        now: currentTime,
        onStop: onStop,
        onOpenResult: onOpenResult,
      )),
      separatorBuilder: (_, _) =>
          const SizedBox(height: _backgroundWorkListSeparator),
      itemCount: works.length,
    );
  }
}

Widget _buildBackgroundWorkListItem(_BackgroundWorkListItemRequest request) {
  final work = request.work;
  final identity = work.identity;

  return _BackgroundWorkTile(
    work: work,
    now: request.now,
    onStop: () => request.onStop(work),
    onOpenResult: () => request.onOpenResult(work),
    key: ValueKey('background_work_item_${identity.id}'),
  );
}

class const _BackgroundWorkTile({
  required this.work,
  required this.now,
  required this.onStop,
  required this.onOpenResult,
  super.key,
}) extends StatelessWidget {
  final AgentBackgroundWork work;
  final DateTime now;
  final Future<void> Function() onStop;
  final Future<void> Function() onOpenResult;

  @override
  Widget build(BuildContext context) {
    final identity = work.identity;
    final state = work.state;
    final result = state.resultContent;
    final previewSource = result ?? state.statusPreview;
    final preview = previewSource == null
        ? null
        : _boundedPreview(previewSource);

    return AuraContainer(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _BackgroundWorkTileHeading(
            identity: identity,
            status: state.status,
          ),
          const AuraSizedBox(height: .xs),
          _BackgroundWorkTileElapsed(
            workId: identity.id,
            createdAt: state.createdAt,
            now: now,
          ),
          if (preview case final value? when value.trim().isNotEmpty) ...[
            const AuraSizedBox(height: .xs),
            _BackgroundWorkTilePreview(
              workId: identity.id,
              preview: value,
            ),
          ],
          const AuraSizedBox(height: .xs),
          _BackgroundWorkTileActions(
            workId: identity.id,
            status: state.status,
            hasResult: result?.isNotEmpty ?? false,
            onStop: onStop,
            onOpenResult: onOpenResult,
          ),
        ],
      ),
      padding: .small,
      variant: .surfaceVariant,
      borderRadius: _backgroundWorkTileRadius,
    );
  }
}

class const _BackgroundWorkTileHeading({
  required this.identity,
  required this.status,
}) extends StatelessWidget {
  final AgentBackgroundWorkIdentity identity;
  final AgentBackgroundWorkStatus status;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          identity.toolKind,
          key: ValueKey('background_work_title_${identity.id}'),
          style: .new(
            color: context.auraColors.onSurface,
            fontWeight: .w600,
          ),
          overflow: .ellipsis,
          maxLines: _backgroundWorkTitleLines,
        ),
      ),
      const AuraSizedBox(width: .xs),
      TextLocale(
        _backgroundWorkStatusLocaleKey(status),
        key: ValueKey('background_work_status_${identity.id}'),
      ),
    ],
  );
}

class const _BackgroundWorkTileElapsed({
  required this.workId,
  required this.createdAt,
  required this.now,
}) extends StatelessWidget {
  final String workId;
  final DateTime createdAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) => TextLocale(
    LocaleKeys.chats_screens_chat_conversation_background_work_elapsed,
    key: ValueKey('background_work_elapsed_$workId'),
    args: [_elapsedLabel(createdAt, now)],
  );
}

class const _BackgroundWorkTilePreview({
  required this.workId,
  required this.preview,
}) extends StatelessWidget {
  final String workId;
  final String preview;

  @override
  Widget build(BuildContext context) => Text(
    preview,
    key: ValueKey('background_work_preview_$workId'),
    overflow: .ellipsis,
    maxLines: _backgroundWorkPreviewLines,
  );
}

class const _BackgroundWorkTileActions({
  required this.workId,
  required this.status,
  required this.hasResult,
  required this.onStop,
  required this.onOpenResult,
}) extends StatelessWidget {
  final String workId;
  final AgentBackgroundWorkStatus status;
  final bool hasResult;
  final Future<void> Function() onStop;
  final Future<void> Function() onOpenResult;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _backgroundWorkActionSpacing,
    runSpacing: _backgroundWorkActionRunSpacing,
    children: [
      if (status == .running)
        AuraButton(
          onPressed: () =>
              _runAction(context, onStop, _backgroundWorkStopErrorKey),
          child: const TextLocale(
            LocaleKeys.chats_screens_chat_conversation_background_work_stop,
          ),
          key: ValueKey('background_work_stop_$workId'),
          variant: .ghost,
          size: .small,
        ),
      if (hasResult)
        AuraButton(
          onPressed: () => _runAction(
            context,
            onOpenResult,
            _backgroundWorkOpenErrorKey,
          ),
          child: const TextLocale(_backgroundWorkOpenResultKey),
          key: ValueKey('background_work_open_result_$workId'),
          variant: .ghost,
          size: .small,
        ),
    ],
  );
}

const String _backgroundWorkStopErrorKey =
    LocaleKeys.chats_screens_chat_conversation_background_work_stop_error;
const String _backgroundWorkOpenErrorKey =
    LocaleKeys.chats_screens_chat_conversation_background_work_open_error;
const String _backgroundWorkOpenResultKey =
    LocaleKeys.chats_screens_chat_conversation_background_work_open_result;

String _backgroundWorkStatusLocaleKey(
  AgentBackgroundWorkStatus status,
) => switch (status) {
  .running =>
    LocaleKeys.chats_screens_chat_conversation_background_work_status_running,
  .stopRequested =>
    LocaleKeys
        .chats_screens_chat_conversation_background_work_status_stop_requested,
  .completed =>
    LocaleKeys.chats_screens_chat_conversation_background_work_status_completed,
  .failed =>
    LocaleKeys.chats_screens_chat_conversation_background_work_status_failed,
  .cancelled =>
    LocaleKeys.chats_screens_chat_conversation_background_work_status_stopped,
};

String _boundedPreview(String value) {
  final characters = value.characters;
  if (characters.length <= _backgroundWorkMaxPreviewCharacters) return value;

  return '${characters.take(_backgroundWorkMaxPreviewCharacters)}'
      '${String.fromCharCode(_ellipsisCodePoint)}';
}

String _elapsedLabel(DateTime createdAt, DateTime now) =>
    _elapsedLabelForSeconds(
      now
          .difference(createdAt)
          .inSeconds
          .clamp(_minimumElapsedSeconds, _maximumElapsedSeconds)
          .toInt(),
    );

String _elapsedLabelForSeconds(int seconds) {
  if (seconds < _secondsPerMinute) return _elapsedSecondsLabel(seconds);

  final minutes = seconds ~/ _secondsPerMinute;
  return _elapsedLabelForMinutes(minutes, seconds % _secondsPerMinute);
}

String _elapsedLabelForMinutes(int minutes, int seconds) {
  if (minutes < _minutesPerHour) {
    return _elapsedMinutesLabel(minutes, seconds);
  }

  final hours = minutes ~/ _minutesPerHour;
  return _elapsedHoursLabel(hours, minutes % _minutesPerHour);
}

String _elapsedSecondsLabel(int seconds) => LocaleKeys
    .chats_screens_chat_conversation_background_work_elapsed_seconds
    .tr(args: [seconds.toString()]);

String _elapsedMinutesLabel(int minutes, int seconds) => LocaleKeys
    .chats_screens_chat_conversation_background_work_elapsed_minutes
    .tr(args: [minutes.toString(), seconds.toString()]);

String _elapsedHoursLabel(int hours, int minutes) => LocaleKeys
    .chats_screens_chat_conversation_background_work_elapsed_hours
    .tr(args: [hours.toString(), minutes.toString()]);

void _runAction(
  BuildContext context,
  Future<void> Function() action,
  String errorKey,
) {
  unawaited(_runActionAndReportError(context, action, errorKey));
}

Future<void> _runActionAndReportError(
  BuildContext context,
  Future<void> Function() action,
  String errorKey,
) async {
  try {
    await action();
  } on Object {
    _showActionError(context, errorKey);
  }
}

void _showActionError(BuildContext context, String errorKey) {
  if (!context.mounted) return;
  final _ = ScaffoldMessenger.of(context)
      .showSnackBar(.new(content: TextLocale(errorKey)));
}
