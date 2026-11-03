import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/resolved_chat_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _messageCounts = [100, 1000, 5000];
const _warmupIterations = 2;
const _sampleCount = 15;
const _operationsPerSample = 8;
const _streamUpdateVersions = _sampleCount * _operationsPerSample;

var _resultSink = 0;

void main() {
  final benchmarkEnabled =
      Platform.environment['AURAVIBES_CHAT_TIMELINE_BENCHMARK'] == '1';

  for (final messageCount in _messageCounts) {
    for (final scenario in _TimelineBenchmarkScenario.values) {
      test(
        'chat timeline projection benchmark: $messageCount ${scenario.name}',
        () => _measureProjection(messageCount, scenario),
        skip: benchmarkEnabled
            ? false
            : 'Set AURAVIBES_CHAT_TIMELINE_BENCHMARK=1 to capture timings',
      );
    }
  }
}

void _measureProjection(int messageCount, _TimelineBenchmarkScenario scenario) {
  final stableMessages = _buildMessages(messageCount);
  final updateSnapshots = scenario == .streamingTail
      ? _buildStreamingTailSnapshots(stableMessages)
      : [stableMessages];

  final firstProjectionTimer = Stopwatch()..start();
  final firstProjection = _project(updateSnapshots.first);
  firstProjectionTimer.stop();
  final firstProjectionUs = firstProjectionTimer.elapsedMicroseconds;

  for (var iteration = 0; iteration < _warmupIterations; iteration++) {
    for (var operation = 0; operation < _operationsPerSample; operation++) {
      final snapshot = updateSnapshots[operation % updateSnapshots.length];
      _resultSink += _project(snapshot).length;
    }
  }

  final samplesUs = <int>[];
  var lastProjection = firstProjection;
  for (var sample = 0; sample < _sampleCount; sample++) {
    final timer = Stopwatch()..start();
    for (var operation = 0; operation < _operationsPerSample; operation++) {
      final updateIndex =
          (sample * _operationsPerSample + operation) % updateSnapshots.length;
      lastProjection = _project(updateSnapshots[updateIndex]);
    }
    timer.stop();
    samplesUs.add(timer.elapsedMicroseconds ~/ _operationsPerSample);
    _resultSink += lastProjection.length;
  }

  final expectedIds = stableMessages
      .whereType<ResolvedChatMessage>()
      .map((source) => source.message.id)
      .toSet();
  final projectedIds = _projectedMessageIds(lastProjection);
  expect(projectedIds, expectedIds);

  final sortedSamples = [...samplesUs]..sort();
  final medianUs = sortedSamples[sortedSamples.length ~/ 2];
  final p95Index = (sortedSamples.length * .95).ceil() - 1;
  final benchmarkRecord = {
    'workload': 'chat_timeline_projection',
    'revision':
        Platform.environment['AURAVIBES_CHAT_TIMELINE_BENCHMARK_REVISION'] ??
        'unrecorded',
    'phase':
        Platform.environment['AURAVIBES_CHAT_TIMELINE_BENCHMARK_PHASE'] ??
        'unrecorded',
    'run':
        Platform.environment['AURAVIBES_CHAT_TIMELINE_BENCHMARK_RUN'] ??
        'unrecorded',
    'scenario': scenario.name,
    'messageCount': messageCount,
    'warmupIterations': _warmupIterations,
    'sampleCount': samplesUs.length,
    'operationsPerSample': _operationsPerSample,
    'firstProjectionUs': firstProjectionUs,
    'medianProjectionUs': medianUs,
    'p95ProjectionUs': sortedSamples[p95Index],
    'samplesUs': samplesUs,
    'projectedItemCount': lastProjection.length,
    'projectedMessageCount': projectedIds.length,
    'resultSink': _resultSink,
    'dart': Platform.version.split(' ').first,
    'os': Platform.operatingSystem,
  };
  debugPrint(jsonEncode(benchmarkRecord));
}

List<ResolvedChatMessage?> _buildMessages(int messageCount) {
  final messages = <ResolvedChatMessage?>[
    for (var index = 0; index < messageCount - 1; index++)
      _resolvedMessage(index),
    _streamingTail(0),
  ];

  return messages;
}

List<List<ResolvedChatMessage?>> _buildStreamingTailSnapshots(
  List<ResolvedChatMessage?> messages,
) => [
  for (var version = 0; version < _streamUpdateVersions; version++)
    List<ResolvedChatMessage?>.of(messages)
      ..[messages.length - 1] = _streamingTail(version),
];

ResolvedChatMessage _resolvedMessage(int index) {
  final isCompaction = index % 47 == 0;
  final isToolActivity = !isCompaction && index % 11 == 0;
  final hasA2ui = !isCompaction && !isToolActivity && index % 17 == 0;
  final isUser = !isCompaction && !isToolActivity && !hasA2ui && index % 4 == 0;
  final hasAttachment = !isCompaction && index % 29 == 0;
  final createdAt = DateTime.utc(2026, 1, 1).add(Duration(seconds: index));
  final id = 'message-$index';
  final toolCalls = isToolActivity
      ? [
          MessageToolCallEntity(
            id: 'tool-$index',
            name: 'search',
            argumentsRaw: '{"query":"fixture-$index"}',
          ),
        ]
      : const <MessageToolCallEntity>[];
  final metadata = MessageMetadataEntity(
    toolCalls: toolCalls,
    thinking: isToolActivity ? 'Thinking on fixture $index' : null,
    a2uiMessages: hasA2ui ? const ['fixture-surface'] : const [],
    isCompactionSummary: isCompaction,
  );
  final attachments = hasAttachment
      ? [
          MessageAttachmentEntity(
            id: 'attachment-$index',
            messageId: id,
            localPath: '/benchmark/attachment-$index.png',
            fileName: 'attachment-$index.png',
            displayName: 'Attachment $index',
            mimeType: 'image/png',
            modality: .image,
            sizeBytes: 1024,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ]
      : const <MessageAttachmentEntity>[];
  final message = MessageEntity(
    id: id,
    conversationId: 'benchmark-conversation',
    content: isToolActivity
        ? ''
        : 'Fixture message $index with stable content.',
    messageType: isCompaction ? .system : MessageType.text,
    isUser: isUser,
    status: index % 31 == 0 && !isCompaction ? .error : .sent,
    createdAt: createdAt,
    updatedAt: createdAt,
    metadata: metadata,
    attachments: attachments,
    isForkReference: index % 37 == 0,
  );

  return ResolvedChatMessage(message: message, isStreaming: false);
}

ResolvedChatMessage _streamingTail(int version) {
  final createdAt = DateTime.utc(2026, 1, 1, 0, 1);

  return ResolvedChatMessage(
    message: MessageEntity(
      id: 'streaming-tail',
      conversationId: 'benchmark-conversation',
      content: 'Assistant response chunk $version',
      messageType: .text,
      isUser: false,
      status: .unfinished,
      createdAt: createdAt,
      updatedAt: createdAt.add(Duration(milliseconds: version)),
    ),
    isStreaming: true,
  );
}

List<ChatTimelineItem> _project(List<ResolvedChatMessage?> messages) =>
    ChatTimelineProjection.buildChatTimelineItems(messages, const {});

Set<String> _projectedMessageIds(List<ChatTimelineItem> items) => {
  for (final item in items)
    if (item case MessageTimelineItem(:final source)) source.message.id,
  for (final item in items)
    if (item case ActivityRunTimelineItem(:final run))
      for (final source in run.sources) source.message.id,
};

enum _TimelineBenchmarkScenario { stableRebuild, streamingTail }
