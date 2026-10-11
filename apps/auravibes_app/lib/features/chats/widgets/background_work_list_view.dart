import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

class const BackgroundWorkListView({
  required final List<AgentBackgroundWork> works,
  required final Future<void> Function(AgentBackgroundWork work) onStop,
  required final Future<void> Function(AgentBackgroundWork work) onOpenResult,
  final DateTime? now,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    key: const ValueKey('background_work_list'),
    padding: const EdgeInsets.all(12),
    itemBuilder: (context, index) {
      final work = works[index];

      return _BackgroundWorkTile(
        work: work,
        now: now ?? DateTime.now(),
        onStop: () => onStop(work),
        onOpenResult: () => onOpenResult(work),
        key: ValueKey('background_work_item_${work.identity.id}'),
      );
    },
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemCount: works.length,
  );
}

class const _BackgroundWorkTile({
  required final AgentBackgroundWork work,
  required final DateTime now,
  required final Future<void> Function() onStop,
  required final Future<void> Function() onOpenResult,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = work.state;
    final statusKey = _backgroundWorkStatusLocaleKey(state.status);
    final result = state.resultContent;
    final previewSource = result ?? state.statusPreview;
    final preview = previewSource == null
        ? null
        : _boundedPreview(previewSource);

    return AuraContainer(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  work.identity.toolKind,
                  key: ValueKey('background_work_title_${work.identity.id}'),
                  style: .new(
                    color: context.auraColors.onSurface,
                    fontWeight: .w600,
                  ),
                  overflow: .ellipsis,
                  maxLines: 1,
                ),
              ),
              const AuraSizedBox(width: .xs),
              TextLocale(
                statusKey,
                key: ValueKey('background_work_status_${work.identity.id}'),
              ),
            ],
          ),
          const AuraSizedBox(height: .xs),
          TextLocale(
            LocaleKeys.chats_screens_chat_conversation_background_work_elapsed,
            key: ValueKey('background_work_elapsed_${work.identity.id}'),
            args: [_elapsedLabel(work.state.createdAt, now)],
          ),
          if (preview case final value? when value.trim().isNotEmpty) ...[
            const AuraSizedBox(height: .xs),
            Text(
              value,
              key: ValueKey('background_work_preview_${work.identity.id}'),
              overflow: .ellipsis,
              maxLines: 3,
            ),
          ],
          const AuraSizedBox(height: .xs),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (state.status == .running)
                AuraButton(
                  onPressed: () =>
                      _runAction(context, onStop, _backgroundWorkStopErrorKey),
                  child: const TextLocale(
                    LocaleKeys
                        .chats_screens_chat_conversation_background_work_stop,
                  ),
                  key: ValueKey('background_work_stop_${work.identity.id}'),
                  variant: .ghost,
                  size: .small,
                ),
              if (result case final content? when content.isNotEmpty)
                AuraButton(
                  onPressed: () => _runAction(
                    context,
                    onOpenResult,
                    _backgroundWorkOpenErrorKey,
                  ),
                  child: const TextLocale(_backgroundWorkOpenResultKey),
                  key: ValueKey(
                    'background_work_open_result_${work.identity.id}',
                  ),
                  variant: .ghost,
                  size: .small,
                ),
            ],
          ),
        ],
      ),
      padding: .small,
      variant: .surfaceVariant,
      borderRadius: 10,
    );
  }
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
  const maxCharacters = 180;
  final characters = value.characters;
  if (characters.length <= maxCharacters) return value;

  return '${characters.take(maxCharacters)}${String.fromCharCode(0x2026)}';
}

String _elapsedLabel(DateTime createdAt, DateTime now) {
  final elapsed = now.difference(createdAt);
  final seconds = elapsed.inSeconds.clamp(0, 999999);
  if (seconds < 60) {
    return LocaleKeys
        .chats_screens_chat_conversation_background_work_elapsed_seconds
        .tr(args: [seconds.toString()]);
  }
  final minutes = seconds ~/ 60;
  if (minutes < 60) {
    return LocaleKeys
        .chats_screens_chat_conversation_background_work_elapsed_minutes
        .tr(args: [minutes.toString(), (seconds % 60).toString()]);
  }
  final hours = minutes ~/ 60;

  return LocaleKeys
      .chats_screens_chat_conversation_background_work_elapsed_hours
      .tr(args: [hours.toString(), (minutes % 60).toString()]);
}

void _runAction(
  BuildContext context,
  Future<void> Function() action,
  String errorKey,
) {
  unawaited(() async {
    try {
      await action();
    } on Object catch (_) {
      if (!context.mounted) return;
      final _ = ScaffoldMessenger.of(context)
          .showSnackBar(.new(content: TextLocale(errorKey)));
    }
  }());
}
