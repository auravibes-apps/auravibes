import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:path/path.dart' as p;

// Limit JSON to 128 MiB (ponytail: use streaming if archives grow).

final class ConversationArchive {
  const new({
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.modelLabel,
  });

  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modelLabel;
  final List<ConversationArchiveMessage> messages;
}

final class ConversationArchiveMessage {
  const new({
    required this.content,
    required this.messageType,
    required this.isUser,
    required this.status,
    required this.createdAt,
    required this.metadata,
    required this.attachments,
  });

  final String content;
  final MessageType messageType;
  final bool isUser;
  final MessageStatus status;
  final DateTime createdAt;
  final ConversationArchiveMetadata metadata;
  final List<ConversationArchiveAttachment> attachments;
}

final class ConversationArchiveMetadata {
  const new({
    required this.toolCalls,
    required this.a2uiMessages,
    required this.isCompactionSummary,
    required this.compactedMessageIndexes,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.providerError,
    this.a2uiRequiresUserAction,
    this.compactionKind,
    this.compactedFromMessageIndex,
    this.compactedThroughMessageIndex,
    this.compactionCreatedAt,
  });

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final bool? providerError;
  final bool? a2uiRequiresUserAction;
  final List<String> a2uiMessages;
  final bool isCompactionSummary;
  final CompactionKind? compactionKind;
  final int? compactedFromMessageIndex;
  final int? compactedThroughMessageIndex;
  final List<int> compactedMessageIndexes;
  final DateTime? compactionCreatedAt;
  final List<ConversationArchiveToolCall> toolCalls;
}

final class ConversationArchiveToolCall {
  const new({this.displayName, this.resultStatus});

  final String? displayName;
  final ToolCallResultStatus? resultStatus;
}

final class ConversationArchiveAttachment {
  const new({
    required this.fileName,
    required this.displayName,
    required this.mimeType,
    required this.modality,
    required this.bytes,
  });

  final String fileName;
  final String displayName;
  final String mimeType;
  final MessageAttachmentModality modality;
  final Uint8List bytes;
}

abstract final class ConversationArchiveCodec {
  static const format = 'auravibes.conversation';
  static const version = 1;
  static const int maxArchiveBytes = 128 * 1024 * 1024;
  static const int maxAttachmentBytes = 25 * 1024 * 1024;

  static Future<String> exportConversation({
    required ConversationEntity conversation,
    required List<MessageEntity> messages,
    required Future<Uint8List> Function(String localPath) readAttachmentBytes,
    String? modelLabel,
  }) async {
    final messageIndexes = <String, int>{
      for (var index = 0; index < messages.length; index++)
        messages[index].id: index,
    };
    final archivedMessages = <ConversationArchiveMessage>[];

    for (final message in messages) {
      final metadata = message.metadata;
      archivedMessages.add(
        ConversationArchiveMessage(
          content: message.content,
          messageType: message.messageType,
          isUser: message.isUser,
          status: message.status,
          createdAt: message.createdAt,
          metadata: .new(
            toolCalls: [
              for (final toolCall
                  in metadata?.toolCalls ?? const <MessageToolCallEntity>[])
                ConversationArchiveToolCall(
                  displayName: toolCall.userFacingDescription?.trim(),
                  resultStatus: toolCall.resultStatus,
                ),
            ],
            a2uiMessages: metadata?.a2uiMessages ?? const [],
            isCompactionSummary: metadata?.isCompactionSummary ?? false,
            compactedMessageIndexes: [
              for (final id
                  in metadata?.compactedMessageIds ?? const <String>[])
                ?messageIndexes[id],
            ],
            promptTokens: metadata?.promptTokens,
            completionTokens: metadata?.completionTokens,
            totalTokens: metadata?.totalTokens,
            providerError: _nullableBoolean(
              metadata?.modelMetadata['providerError'],
            ),
            a2uiRequiresUserAction: _nullableBoolean(
              metadata?.modelMetadata['a2uiRequiresUserAction'],
            ),
            compactionKind: metadata?.compactionKind,
            compactedFromMessageIndex:
                messageIndexes[metadata?.compactedFromMessageId],
            compactedThroughMessageIndex:
                messageIndexes[metadata?.compactedThroughMessageId],
            compactionCreatedAt: metadata?.compactionCreatedAt,
          ),
          attachments: [
            for (final attachment in message.attachments)
              await _exportAttachment(attachment, readAttachmentBytes),
          ],
        ),
      );
    }

    return encode(
      .new(
        title: conversation.title,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt,
        messages: archivedMessages,
        modelLabel: modelLabel,
      ),
    );
  }

  static String encode(ConversationArchive archive) {
    final json = jsonEncode(_archiveToJson(archive));
    if (utf8.encode(json).length > maxArchiveBytes) {
      throw const MalformedConversationArchiveException();
    }

    return json;
  }

  static ConversationArchive decode(String json) {
    if (utf8.encode(json).length > maxArchiveBytes) {
      throw const MalformedConversationArchiveException();
    }

    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const MalformedConversationArchiveException(),
        stackTrace,
      );
    }

    final root = _jsonMap(decoded);
    if (root['format'] != format) {
      throw const MalformedConversationArchiveException();
    }

    final archiveVersion = _integer(root['version']);
    if (archiveVersion != version) {
      throw UnsupportedArchiveVersionException(archiveVersion);
    }
    _requireKeys(root, const {'format', 'version', 'conversation', 'messages'});

    final conversation = _jsonMap(root['conversation']);
    _requireKeys(conversation, const {
      'title',
      'createdAt',
      'updatedAt',
      'modelLabel',
    });
    final messages = _jsonList(root['messages'])
        .map(_decodeMessage)
        .toList(growable: false);
    final archive = ConversationArchive(
      title: _nonEmptyString(conversation['title']),
      createdAt: _dateTime(conversation['createdAt']),
      updatedAt: _dateTime(conversation['updatedAt']),
      messages: messages,
      modelLabel: _nullableString(conversation['modelLabel']),
    );
    _validateMessageIndexes(archive.messages);

    return archive;
  }
}

Future<ConversationArchiveAttachment> _exportAttachment(
  MessageAttachmentEntity attachment,
  Future<Uint8List> Function(String localPath) readAttachmentBytes,
) async {
  final bytes = await readAttachmentBytes(attachment.localPath);
  if (bytes.length != attachment.sizeBytes ||
      bytes.length > ConversationArchiveCodec.maxAttachmentBytes) {
    throw const MalformedConversationArchiveException();
  }

  final fileName = p.posix.basename(attachment.fileName.replaceAll(r'\', '/'));
  if (fileName.isEmpty) {
    throw const MalformedConversationArchiveException();
  }

  return ConversationArchiveAttachment(
    fileName: fileName,
    displayName: attachment.displayName,
    mimeType: attachment.mimeType,
    modality: attachment.modality,
    bytes: bytes,
  );
}

Map<String, Object?> _archiveToJson(ConversationArchive archive) => {
  'format': ConversationArchiveCodec.format,
  'version': ConversationArchiveCodec.version,
  'conversation': {
    'title': archive.title,
    'createdAt': archive.createdAt.toIso8601String(),
    'updatedAt': archive.updatedAt.toIso8601String(),
    'modelLabel': archive.modelLabel,
  },
  'messages': [
    for (final message in archive.messages)
      {
        'content': message.content,
        'messageType': message.messageType.value,
        'isUser': message.isUser,
        'status': message.status.value,
        'createdAt': message.createdAt.toIso8601String(),
        'metadata': _metadataToJson(message.metadata),
        'attachments': [
          for (final attachment in message.attachments)
            {
              'fileName': attachment.fileName,
              'displayName': attachment.displayName,
              'mimeType': attachment.mimeType,
              'modality': attachment.modality.name,
              'sizeBytes': attachment.bytes.length,
              'dataBase64': base64Encode(attachment.bytes),
            },
        ],
      },
  ],
};

Map<String, Object?> _metadataToJson(ConversationArchiveMetadata metadata) => {
  'promptTokens': metadata.promptTokens,
  'completionTokens': metadata.completionTokens,
  'totalTokens': metadata.totalTokens,
  'providerError': metadata.providerError,
  'a2uiRequiresUserAction': metadata.a2uiRequiresUserAction,
  'a2uiMessages': metadata.a2uiMessages,
  'isCompactionSummary': metadata.isCompactionSummary,
  'compactionKind': metadata.compactionKind?.name,
  'compactedFromMessageIndex': metadata.compactedFromMessageIndex,
  'compactedThroughMessageIndex': metadata.compactedThroughMessageIndex,
  'compactedMessageIndexes': metadata.compactedMessageIndexes,
  'compactionCreatedAt': metadata.compactionCreatedAt?.toIso8601String(),
  'toolCalls': [
    for (final toolCall in metadata.toolCalls)
      {
        'displayName': toolCall.displayName,
        'resultStatus': _toolStatusToJson(toolCall.resultStatus),
      },
  ],
};

ConversationArchiveMessage _decodeMessage(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {
    'content',
    'messageType',
    'isUser',
    'status',
    'createdAt',
    'metadata',
    'attachments',
  });
  final messageType = _enumByName(MessageType.values, json['messageType']);
  final status = _enumByName(MessageStatus.values, json['status']);
  final attachments = _jsonList(json['attachments'])
      .map(_decodeAttachment)
      .toList(growable: false);
  final content = _string(json['content']);
  if (content.trim().isEmpty && attachments.isEmpty) {
    throw const MalformedConversationArchiveException();
  }

  return ConversationArchiveMessage(
    content: content,
    messageType: messageType,
    isUser: _boolean(json['isUser']),
    status: status,
    createdAt: _dateTime(json['createdAt']),
    metadata: _decodeMetadata(json['metadata']),
    attachments: attachments,
  );
}

ConversationArchiveMetadata _decodeMetadata(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {
    'promptTokens',
    'completionTokens',
    'totalTokens',
    'providerError',
    'a2uiRequiresUserAction',
    'a2uiMessages',
    'isCompactionSummary',
    'compactionKind',
    'compactedFromMessageIndex',
    'compactedThroughMessageIndex',
    'compactedMessageIndexes',
    'compactionCreatedAt',
    'toolCalls',
  });

  return ConversationArchiveMetadata(
    toolCalls: _jsonList(json['toolCalls'])
        .map(_decodeToolCall)
        .toList(growable: false),
    a2uiMessages: _jsonList(json['a2uiMessages']).map(_string).toList(),
    isCompactionSummary: _boolean(json['isCompactionSummary']),
    compactedMessageIndexes: _jsonList(json['compactedMessageIndexes'])
        .map(_integer)
        .toList(),
    promptTokens: _nullableInteger(json['promptTokens']),
    completionTokens: _nullableInteger(json['completionTokens']),
    totalTokens: _nullableInteger(json['totalTokens']),
    providerError: _nullableBoolean(json['providerError']),
    a2uiRequiresUserAction: _nullableBoolean(json['a2uiRequiresUserAction']),
    compactionKind: _nullableEnumByName(
      CompactionKind.values,
      json['compactionKind'],
    ),
    compactedFromMessageIndex: _nullableInteger(
      json['compactedFromMessageIndex'],
    ),
    compactedThroughMessageIndex: _nullableInteger(
      json['compactedThroughMessageIndex'],
    ),
    compactionCreatedAt: _nullableDateTime(json['compactionCreatedAt']),
  );
}

ConversationArchiveToolCall _decodeToolCall(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {'displayName', 'resultStatus'});

  return ConversationArchiveToolCall(
    displayName: _nullableString(json['displayName']),
    resultStatus: _nullableToolStatus(json['resultStatus']),
  );
}

ConversationArchiveAttachment _decodeAttachment(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {
    'fileName',
    'displayName',
    'mimeType',
    'modality',
    'sizeBytes',
    'dataBase64',
  });
  final fileName = _nonEmptyString(json['fileName']);
  if (fileName == '.' ||
      fileName == '..' ||
      fileName != p.posix.basename(fileName.replaceAll(r'\', '/'))) {
    throw const MalformedConversationArchiveException();
  }
  final data = _string(json['dataBase64']);
  Uint8List bytes;
  try {
    bytes = Uint8List.fromList(base64Decode(data));
  } on FormatException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      const MalformedConversationArchiveException(),
      stackTrace,
    );
  }
  final sizeBytes = _integer(json['sizeBytes']);
  if (sizeBytes < 0 ||
      sizeBytes > ConversationArchiveCodec.maxAttachmentBytes ||
      bytes.length != sizeBytes) {
    throw const MalformedConversationArchiveException();
  }

  final mimeType = _nonEmptyString(json['mimeType']);
  if (!RegExp(r'^[a-zA-Z0-9.+-]+/[a-zA-Z0-9.+-]+$').hasMatch(mimeType)) {
    throw const MalformedConversationArchiveException();
  }

  return ConversationArchiveAttachment(
    fileName: fileName,
    displayName: _nonEmptyString(json['displayName']),
    mimeType: mimeType,
    modality: _enumByName(MessageAttachmentModality.values, json['modality']),
    bytes: bytes,
  );
}

void _validateMessageIndexes(List<ConversationArchiveMessage> messages) {
  for (final message in messages) {
    final metadata = message.metadata;
    final indexes = [
      ...metadata.compactedMessageIndexes,
      ?metadata.compactedFromMessageIndex,
      ?metadata.compactedThroughMessageIndex,
    ];
    if (indexes.any((index) => index < 0 || index >= messages.length)) {
      throw const MalformedConversationArchiveException();
    }
  }
}

Map<String, Object?> _jsonMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw const MalformedConversationArchiveException();
}

List<Object?> _jsonList(Object? value) {
  if (value is List<Object?>) return value;
  throw const MalformedConversationArchiveException();
}

void _requireKeys(Map<String, Object?> json, Set<String> expected) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const MalformedConversationArchiveException();
  }
}

String _string(Object? value) {
  if (value is String) return value;
  throw const MalformedConversationArchiveException();
}

String _nonEmptyString(Object? value) {
  final result = _string(value);
  if (result.trim().isEmpty) {
    throw const MalformedConversationArchiveException();
  }

  return result;
}

String? _nullableString(Object? value) {
  if (value == null) return null;

  return _string(value);
}

bool _boolean(Object? value) {
  if (value is bool) return value;
  throw const MalformedConversationArchiveException();
}

bool? _nullableBoolean(Object? value) {
  if (value == null) return null;

  return _boolean(value);
}

int _integer(Object? value) {
  if (value is int) return value;
  throw const MalformedConversationArchiveException();
}

int? _nullableInteger(Object? value) {
  if (value == null) return null;

  return _integer(value);
}

DateTime _dateTime(Object? value) {
  final parsed = DateTime.tryParse(_string(value));
  if (parsed != null) return parsed;

  throw const MalformedConversationArchiveException();
}

DateTime? _nullableDateTime(Object? value) {
  if (value == null) return null;

  return _dateTime(value);
}

T _enumByName<T extends Enum>(List<T> values, Object? value) {
  final name = _string(value);
  for (final candidate in values) {
    if (candidate.name == name ||
        candidate is MessageType && candidate.value == name ||
        candidate is MessageStatus && candidate.value == name) {
      return candidate;
    }
  }
  throw const MalformedConversationArchiveException();
}

T? _nullableEnumByName<T extends Enum>(List<T> values, Object? value) {
  if (value == null) return null;

  return _enumByName(values, value);
}

String? _toolStatusToJson(ToolCallResultStatus? value) {
  if (value == null) return null;

  return const ToolCallResultStatusConverter().toJson(value);
}

ToolCallResultStatus? _nullableToolStatus(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const MalformedConversationArchiveException();
  }
  final status = const ToolCallResultStatusConverter().fromJson(value);
  if (status != null) return status;

  throw const MalformedConversationArchiveException();
}

final class MalformedConversationArchiveException implements Exception {
  const new();

  String get localizationKey =>
      'chats.screens.chat_conversation.archive_invalid';
}

final class UnsupportedArchiveVersionException implements Exception {
  const new(this.version);

  final int version;

  String get localizationKey =>
      'chats.screens.chat_conversation.archive_unsupported_version';
}
