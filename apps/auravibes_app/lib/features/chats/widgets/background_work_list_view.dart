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
const int _backgroundWorkTitleLines = 1;
const int _backgroundWorkPreviewLines = 3;
const int _backgroundWorkMaxPreviewCharacters = 180;
const int _minimumElapsedSeconds = 0;
const int _maximumElapsedSeconds = 999999;
const int _secondsPerMinute = 60;
const int _minutesPerHour = 60;
const int _ellipsisCodePoint = 0x2026;
const Duration _elapsedTimeRefreshInterval = .new(seconds: 1);

class const BackgroundWorkListView({
  required final List<AgentBackgroundWork> works,
  required final Future<void> Function(AgentBackgroundWork work) onStop,
  required final Future<void> Function(AgentBackgroundWork work) onOpenResult,
  final Future<void> Function(AgentBackgroundWork work)? onOpenChild,
  final DateTime? now,
  @visibleForTesting final DateTime Function()? clock,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final readNow = clock ?? DateTime.now;

    return _BackgroundWorkListMode(
      now: now,
      readNow: readNow,
      works: works,
      onStop: onStop,
      onOpenResult: onOpenResult,
      onOpenChild: onOpenChild,
    );
  }
}

class const _BackgroundWorkListMode({
  required final DateTime? now,
  required final DateTime Function() readNow,
  required final List<AgentBackgroundWork> works,
  required final Future<void> Function(AgentBackgroundWork work) onStop,
  required final Future<void> Function(AgentBackgroundWork work) onOpenResult,
  final Future<void> Function(AgentBackgroundWork work)? onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final initialNow = now ?? readNow();
    if (now != null || !_hasActiveBackgroundWork(works)) {
      return _BackgroundWorkScrollableList(
        works: works,
        now: initialNow,
        onStop: onStop,
        onOpenResult: onOpenResult,
        onOpenChild: onOpenChild,
      );
    }

    return _BackgroundWorkElapsedList(
      initialNow: initialNow,
      readNow: readNow,
      works: works,
      onStop: onStop,
      onOpenResult: onOpenResult,
      onOpenChild: onOpenChild,
    );
  }
}

class const _BackgroundWorkElapsedList({
  required final DateTime initialNow,
  required final DateTime Function() readNow,
  required final List<AgentBackgroundWork> works,
  required final Future<void> Function(AgentBackgroundWork work) onStop,
  required final Future<void> Function(AgentBackgroundWork work) onOpenResult,
  final Future<void> Function(AgentBackgroundWork work)? onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<DateTime>(
    initialData: initialNow,
    stream: _elapsedTimes(),
    builder: _buildList,
  );

  Stream<DateTime> _elapsedTimes() =>
      Stream<DateTime>.periodic(_elapsedTimeRefreshInterval, (_) => readNow());

  Widget _buildList(BuildContext _, AsyncSnapshot<DateTime> snapshot) =>
      _BackgroundWorkScrollableList(
        works: works,
        now: snapshot.data ?? readNow(),
        onStop: onStop,
        onOpenResult: onOpenResult,
        onOpenChild: onOpenChild,
      );
}

class const _BackgroundWorkScrollableList({
  required final List<AgentBackgroundWork> works,
  required final DateTime now,
  required final Future<void> Function(AgentBackgroundWork work) onStop,
  required final Future<void> Function(AgentBackgroundWork work) onOpenResult,
  final Future<void> Function(AgentBackgroundWork work)? onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    key: const ValueKey('background_work_list'),
    padding: const EdgeInsets.all(_backgroundWorkListPadding),
    itemBuilder: _buildListItem,
    separatorBuilder: _buildSeparator,
    itemCount: works.length,
  );

  Widget _buildListItem(BuildContext _, int index) => _BackgroundWorkListItem(
    work: works[index],
    now: now,
    onStop: onStop,
    onOpenResult: onOpenResult,
    onOpenChild: onOpenChild,
  );

  Widget _buildSeparator(BuildContext _, int _) =>
      const SizedBox(height: _backgroundWorkListSeparator);
}

class const _BackgroundWorkListItem({
  required final AgentBackgroundWork work,
  required final DateTime now,
  required final Future<void> Function(AgentBackgroundWork) onStop,
  required final Future<void> Function(AgentBackgroundWork) onOpenResult,
  final Future<void> Function(AgentBackgroundWork)? onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final openChild = onOpenChild;

    return _BackgroundWorkTile(
      work: work,
      now: now,
      onStop: () => onStop(work),
      onOpenResult: () => onOpenResult(work),
      onOpenChild: openChild == null ? null : () => openChild(work),
      key: ValueKey('background_work_item_${work.identity.id}'),
    );
  }
}

class const _BackgroundWorkTile({
  required final AgentBackgroundWork work,
  required final DateTime now,
  required final Future<void> Function() onStop,
  required final Future<void> Function() onOpenResult,
  final Future<void> Function()? onOpenChild,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = _backgroundWorkTileData(work);

    return AuraContainer(
      child: _BackgroundWorkTileContent(
        data: data,
        now: now,
        onStop: onStop,
        onOpenResult: onOpenResult,
        onOpenChild: onOpenChild,
      ),
      padding: .small,
      variant: .surfaceVariant,
      borderRadius: _backgroundWorkTileRadius,
    );
  }
}

typedef _BackgroundWorkTileData = ({
  AgentBackgroundWorkIdentity identity,
  DateTime createdAt,
  DateTime updatedAt,
  AgentBackgroundWorkStatus status,
  bool hasResult,
  String? preview,
});

_BackgroundWorkTileData _backgroundWorkTileData(AgentBackgroundWork work) {
  final state = work.state;
  final result = state.resultContent;

  return (
    identity: work.identity,
    createdAt: state.createdAt,
    updatedAt: state.updatedAt,
    status: state.status,
    hasResult: result?.isNotEmpty ?? false,
    preview: _backgroundWorkTilePreview(result, state.statusPreview),
  );
}

String? _backgroundWorkTilePreview(String? result, String? statusPreview) {
  final previewSource = result ?? statusPreview;
  if (previewSource == null) return null;

  return _boundedPreview(previewSource);
}

class const _BackgroundWorkTileContent({
  required final _BackgroundWorkTileData data,
  required final DateTime now,
  required final Future<void> Function() onStop,
  required final Future<void> Function() onOpenResult,
  final Future<void> Function()? onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _BackgroundWorkTileInformation(data: data, now: now),
        const AuraSizedBox(height: .xs),
        _BackgroundWorkTileActions(
          data: data,
          onStop: onStop,
          onOpenResult: onOpenResult,
          onOpenChild: onOpenChild,
        ),
      ],
    );
  }
}

class const _BackgroundWorkTileInformation({
  required final _BackgroundWorkTileData data,
  required final DateTime now,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      _BackgroundWorkTileHeadingSection(data: data),
      _BackgroundWorkTileDetailsSection(data: data, now: now),
    ],
  );
}

class const _BackgroundWorkTileHeadingSection({
  required final _BackgroundWorkTileData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      _BackgroundWorkTileHeading(identity: data.identity, status: data.status),
      const AuraSizedBox(height: .xs),
    ],
  );
}

class const _BackgroundWorkTileDetailsSection({
  required final _BackgroundWorkTileData data,
  required final DateTime now,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workId = data.identity.id;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _BackgroundWorkTileElapsed(
          workId: workId,
          createdAt: data.createdAt,
          endAt: _isActiveBackgroundWork(data.status) ? now : data.updatedAt,
        ),
        _BackgroundWorkTilePreviewSection(
          workId: workId,
          preview: data.preview,
        ),
      ],
    );
  }
}

class const _BackgroundWorkTilePreviewSection({
  required final String workId,
  required final String? preview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (preview case final value? when value.trim().isNotEmpty) ...[
        const AuraSizedBox(height: .xs),
        _BackgroundWorkTilePreview(workId: workId, preview: value),
      ],
    ],
  );
}

class const _BackgroundWorkTileHeading({
  required final AgentBackgroundWorkIdentity identity,
  required final AgentBackgroundWorkStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _BackgroundWorkTileTitle(identity: identity)),
      const AuraSizedBox(width: .xs),
      _BackgroundWorkTileStatus(workId: identity.id, status: status),
    ],
  );
}

class const _BackgroundWorkTileTitle({
  required final AgentBackgroundWorkIdentity identity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    identity.toolKind,
    key: ValueKey('background_work_title_${identity.id}'),
    style: .new(color: context.auraColors.onSurface, fontWeight: .w600),
    overflow: .ellipsis,
    maxLines: _backgroundWorkTitleLines,
  );
}

class const _BackgroundWorkTileStatus({
  required final String workId,
  required final AgentBackgroundWorkStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    _backgroundWorkStatusLocaleKey(status),
    key: ValueKey('background_work_status_$workId'),
  );
}

class const _BackgroundWorkTileElapsed({
  required final String workId,
  required final DateTime createdAt,
  required final DateTime endAt,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    LocaleKeys.chats_screens_chat_conversation_background_work_elapsed,
    key: ValueKey('background_work_elapsed_$workId'),
    args: [_elapsedLabel(createdAt, endAt)],
  );
}

class const _BackgroundWorkTilePreview({
  required final String workId,
  required final String preview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    preview,
    key: ValueKey('background_work_preview_$workId'),
    overflow: .ellipsis,
    maxLines: _backgroundWorkPreviewLines,
  );
}

class const _BackgroundWorkTileActions({
  required final _BackgroundWorkTileData data,
  required final Future<void> Function() onStop,
  required final Future<void> Function() onOpenResult,
  final Future<void> Function()? onOpenChild,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workId = data.identity.id;
    final openChild = onOpenChild;
    final childConversationId = data.identity.childConversationId;

    return Wrap(
      spacing: _backgroundWorkActionSpacing,
      runSpacing: _backgroundWorkActionRunSpacing,
      children: [
        if (data.status == .running)
          _BackgroundWorkStopButton(workId: workId, action: onStop),
        if (childConversationId != null && openChild != null)
          _BackgroundWorkOpenChildButton(workId: workId, action: openChild),
        if (data.hasResult)
          _BackgroundWorkOpenResultButton(workId: workId, action: onOpenResult),
      ],
    );
  }
}

class const _BackgroundWorkStopButton({
  required final String workId,
  required final Future<void> Function() action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _BackgroundWorkActionButton(
    workId: workId,
    keyPrefix: 'background_work_stop',
    localeKey: LocaleKeys.chats_screens_chat_conversation_background_work_stop,
    errorKey: _backgroundWorkStopErrorKey,
    action: action,
  );
}

class const _BackgroundWorkOpenResultButton({
  required final String workId,
  required final Future<void> Function() action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _BackgroundWorkActionButton(
    workId: workId,
    keyPrefix: 'background_work_open_result',
    localeKey: _backgroundWorkOpenResultKey,
    errorKey: _backgroundWorkOpenErrorKey,
    action: action,
  );
}

class const _BackgroundWorkOpenChildButton({
  required final String workId,
  required final Future<void> Function() action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _BackgroundWorkActionButton(
    workId: workId,
    keyPrefix: 'background_work_open_child',
    localeKey:
        LocaleKeys.chats_screens_chat_conversation_activity_open_sub_agent,
    errorKey: _backgroundWorkOpenErrorKey,
    action: action,
  );
}

class const _BackgroundWorkActionButton({
  required final String workId,
  required final String keyPrefix,
  required final String localeKey,
  required final String errorKey,
  required final Future<void> Function() action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => _runAction(context, action, errorKey),
    child: TextLocale(localeKey),
    key: ValueKey('${keyPrefix}_$workId'),
    variant: .ghost,
    size: .small,
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

bool _hasActiveBackgroundWork(List<AgentBackgroundWork> works) =>
    works.any((work) => _isActiveBackgroundWork(work.state.status));

bool _isActiveBackgroundWork(AgentBackgroundWorkStatus status) =>
    status == .running || status == .stopRequested;

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
          .clamp(_minimumElapsedSeconds, _maximumElapsedSeconds),
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
    if (!context.mounted) return;
    _showActionError(context, errorKey);
  }
}

void _showActionError(BuildContext context, String errorKey) {
  if (!context.mounted) return;
  final _ = ScaffoldMessenger.of(context)
      .showSnackBar(.new(content: TextLocale(errorKey)));
}
