import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'conversation_archive.freezed.dart';

// Limit JSON to 128 MiB (ponytail: use streaming if archives grow).

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ConversationArchive with _$ConversationArchive {
  const factory({
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<ConversationArchiveMessage> messages,
    String? modelLabel,
  }) = _ConversationArchive;
}

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ConversationArchiveMessage with _$ConversationArchiveMessage {
  const factory({
    required String content,
    required MessageType messageType,
    required bool isUser,
    required MessageStatus status,
    required DateTime createdAt,
    required ConversationArchiveMetadata metadata,
    required List<ConversationArchiveAttachment> attachments,
  }) = _ConversationArchiveMessage;
}

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ConversationArchiveMetadata with _$ConversationArchiveMetadata {
  const factory({
    @Default(<ConversationArchiveToolCall>[])
    List<ConversationArchiveToolCall> toolCalls,
    @Default(<String>[]) List<String> a2uiMessages,
    @Default(false) bool isCompactionSummary,
    @Default(<int>[]) List<int> compactedMessageIndexes,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    bool? providerError,
    bool? a2uiRequiresUserAction,
    CompactionKind? compactionKind,
    int? compactedFromMessageIndex,
    int? compactedThroughMessageIndex,
    DateTime? compactionCreatedAt,
  }) = _ConversationArchiveMetadata;
}

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ConversationArchiveToolCall with _$ConversationArchiveToolCall {
  const factory({String? displayName, ToolCallResultStatus? resultStatus}) =
      _ConversationArchiveToolCall;
}

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ConversationArchiveAttachment
    with _$ConversationArchiveAttachment {
  const factory({
    required String fileName,
    required String displayName,
    required String mimeType,
    required MessageAttachmentModality modality,
    required Uint8List bytes,
  }) = _ConversationArchiveAttachment;
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
    final archivedMessages = await _archiveMessages(
      messages,
      readAttachmentBytes,
    );

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

    return _decodeArchive(_decodeJson(json));
  }
}

Future<ConversationArchiveAttachment> _exportAttachment(
  MessageAttachmentEntity attachment,
  Future<Uint8List> Function(String localPath) readAttachmentBytes,
) async {
  final bytes = await readAttachmentBytes(attachment.localPath);
  _validateExportAttachmentSize(attachment.sizeBytes, bytes.length);

  return ConversationArchiveAttachment(
    fileName: _archiveFileName(attachment.fileName),
    displayName: attachment.displayName,
    mimeType: attachment.mimeType,
    modality: attachment.modality,
    bytes: bytes,
  );
}

Map<String, Object?> _archiveToJson(ConversationArchive archive) => {
  'format': ConversationArchiveCodec.format,
  'version': ConversationArchiveCodec.version,
  'conversation': _conversationToJson(archive),
  'messages': [for (final message in archive.messages) _messageToJson(message)],
};

Map<String, Object?> _metadataToJson(ConversationArchiveMetadata metadata) => {
  ..._metadataTokenFieldsToJson(metadata),
  'a2uiMessages': metadata.a2uiMessages,
  'isCompactionSummary': metadata.isCompactionSummary,
  ..._metadataCompactionFieldsToJson(metadata),
  'toolCalls': [
    for (final toolCall in metadata.toolCalls) _toolCallToJson(toolCall),
  ],
};

ConversationArchiveMessage _decodeMessage(Object? value) =>
    _decodeArchiveMessage(_messageJson(value));

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

  return _decodeMetadataCompaction(
    _decodeMetadataTokens(_decodeMetadataContent(json), json),
    json,
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

ConversationArchiveAttachment _decodeAttachment(Object? value) =>
    _decodeArchiveAttachment(_attachmentJson(value));

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

Object? _decodeJson(String json) {
  try {
    return jsonDecode(json);
  } on FormatException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      const MalformedConversationArchiveException(),
      stackTrace,
    );
  }
}

ConversationArchive _decodeArchive(Object? value) {
  final root = _jsonMap(value);
  _validateArchiveRoot(root);
  final archive = _decodeArchiveContents(root);
  _validateMessageIndexes(archive.messages);

  return archive;
}

ConversationArchive _decodeArchiveContents(Map<String, Object?> root) {
  final conversation = _decodeConversation(root['conversation']);

  return ConversationArchive(
    title: conversation.title,
    createdAt: conversation.createdAt,
    updatedAt: conversation.updatedAt,
    messages: _decodeMessages(root['messages']),
    modelLabel: conversation.modelLabel,
  );
}

List<ConversationArchiveMessage> _decodeMessages(Object? value) =>
    _jsonList(value).map(_decodeMessage).toList(growable: false);

void _validateArchiveRoot(Map<String, Object?> root) {
  if (root['format'] != ConversationArchiveCodec.format) {
    throw const MalformedConversationArchiveException();
  }
  final version = _integer(root['version']);
  if (version != ConversationArchiveCodec.version) {
    throw UnsupportedArchiveVersionException(version);
  }
  _requireKeys(root, const {'format', 'version', 'conversation', 'messages'});
}

({String title, DateTime createdAt, DateTime updatedAt, String? modelLabel})
_decodeConversation(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {'title', 'createdAt', 'updatedAt', 'modelLabel'});

  return (
    title: _nonEmptyString(json['title']),
    createdAt: _dateTime(json['createdAt']),
    updatedAt: _dateTime(json['updatedAt']),
    modelLabel: _nullableString(json['modelLabel']),
  );
}

Future<List<ConversationArchiveMessage>> _archiveMessages(
  List<MessageEntity> messages,
  Future<Uint8List> Function(String localPath) readAttachmentBytes,
) async {
  final messageIndexes = {
    for (var index = 0; index < messages.length; index++)
      messages[index].id: index,
  };
  final archivedMessages = <ConversationArchiveMessage>[];
  for (final message in messages) {
    archivedMessages.add(
      await _archiveMessage(message, messageIndexes, readAttachmentBytes),
    );
  }

  return archivedMessages;
}

Future<ConversationArchiveMessage> _archiveMessage(
  MessageEntity message,
  Map<String, int> messageIndexes,
  Future<Uint8List> Function(String localPath) readAttachmentBytes,
) async {
  final attachments = await _archiveMessageAttachments(
    message.attachments,
    readAttachmentBytes,
  );

  return _archiveMessageTranscript(message, messageIndexes, attachments);
}

Future<List<ConversationArchiveAttachment>> _archiveMessageAttachments(
  List<MessageAttachmentEntity> attachments,
  Future<Uint8List> Function(String localPath) readAttachmentBytes,
) async {
  final archived = <ConversationArchiveAttachment>[];
  for (final attachment in attachments) {
    archived.add(await _exportAttachment(attachment, readAttachmentBytes));
  }

  return archived;
}

ConversationArchiveMessage _archiveMessageTranscript(
  MessageEntity message,
  Map<String, int> messageIndexes,
  List<ConversationArchiveAttachment> attachments,
) => ConversationArchiveMessage(
  content: message.content,
  messageType: message.messageType,
  isUser: message.isUser,
  status: message.status,
  createdAt: message.createdAt,
  metadata: _archiveMetadata(message.metadata, messageIndexes),
  attachments: attachments,
);

ConversationArchiveMetadata _archiveMetadata(
  MessageMetadataEntity? source,
  Map<String, int> messageIndexes,
) {
  final metadata = source ?? const MessageMetadataEntity();

  return _archiveMetadataCore(metadata).copyWith(
    compactionKind: metadata.compactionKind,
    compactedFromMessageIndex: messageIndexes[metadata.compactedFromMessageId],
    compactedThroughMessageIndex:
        messageIndexes[metadata.compactedThroughMessageId],
    compactedMessageIndexes: [
      for (final id in metadata.compactedMessageIds) ?messageIndexes[id],
    ],
    compactionCreatedAt: metadata.compactionCreatedAt,
  );
}

ConversationArchiveMetadata _archiveMetadataCore(
  MessageMetadataEntity metadata,
) => ConversationArchiveMetadata(
  toolCalls: _archiveToolCalls(metadata.toolCalls),
  a2uiMessages: metadata.a2uiMessages,
  isCompactionSummary: metadata.isCompactionSummary,
  promptTokens: metadata.promptTokens,
  completionTokens: metadata.completionTokens,
  totalTokens: metadata.totalTokens,
  providerError: _nullableBoolean(metadata.modelMetadata['providerError']),
  a2uiRequiresUserAction: _nullableBoolean(
    metadata.modelMetadata['a2uiRequiresUserAction'],
  ),
);

List<ConversationArchiveToolCall> _archiveToolCalls(
  List<MessageToolCallEntity> toolCalls,
) => [
  for (final toolCall in toolCalls)
    ConversationArchiveToolCall(
      displayName: toolCall.userFacingDescription?.trim(),
      resultStatus: toolCall.resultStatus,
    ),
];

Map<String, Object?> _conversationToJson(ConversationArchive archive) => {
  'title': archive.title,
  'createdAt': archive.createdAt.toIso8601String(),
  'updatedAt': archive.updatedAt.toIso8601String(),
  'modelLabel': archive.modelLabel,
};

Map<String, Object?> _messageToJson(ConversationArchiveMessage message) => {
  ..._messageFieldsToJson(message),
  'metadata': _metadataToJson(message.metadata),
  'attachments': [
    for (final attachment in message.attachments) _attachmentToJson(attachment),
  ],
};

Map<String, Object?> _messageFieldsToJson(ConversationArchiveMessage message) =>
    {
      'content': message.content,
      'messageType': message.messageType.value,
      'isUser': message.isUser,
      'status': message.status.value,
      'createdAt': message.createdAt.toIso8601String(),
    };

Map<String, Object?> _attachmentToJson(
  ConversationArchiveAttachment attachment,
) => {
  'fileName': attachment.fileName,
  'displayName': attachment.displayName,
  'mimeType': attachment.mimeType,
  'modality': attachment.modality.name,
  'sizeBytes': attachment.bytes.length,
  'dataBase64': base64Encode(attachment.bytes),
};

Map<String, Object?> _metadataTokenFieldsToJson(
  ConversationArchiveMetadata metadata,
) => {
  'promptTokens': metadata.promptTokens,
  'completionTokens': metadata.completionTokens,
  'totalTokens': metadata.totalTokens,
  'providerError': metadata.providerError,
  'a2uiRequiresUserAction': metadata.a2uiRequiresUserAction,
};

Map<String, Object?> _metadataCompactionFieldsToJson(
  ConversationArchiveMetadata metadata,
) => {
  'compactionKind': metadata.compactionKind?.name,
  'compactedFromMessageIndex': metadata.compactedFromMessageIndex,
  'compactedThroughMessageIndex': metadata.compactedThroughMessageIndex,
  'compactedMessageIndexes': metadata.compactedMessageIndexes,
  'compactionCreatedAt': metadata.compactionCreatedAt?.toIso8601String(),
};

Map<String, Object?> _toolCallToJson(ConversationArchiveToolCall toolCall) => {
  'displayName': toolCall.displayName,
  'resultStatus': _toolStatusToJson(toolCall.resultStatus),
};

Map<String, Object?> _messageJson(Object? value) {
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

  return json;
}

ConversationArchiveMessage _decodeArchiveMessage(Map<String, Object?> json) {
  final attachments = _decodeMessageAttachments(json['attachments']);

  return _decodedArchiveMessage(json, attachments);
}

List<ConversationArchiveAttachment> _decodeMessageAttachments(Object? value) =>
    _jsonList(value).map(_decodeAttachment).toList(growable: false);

ConversationArchiveMessage _decodedArchiveMessage(
  Map<String, Object?> json,
  List<ConversationArchiveAttachment> attachments,
) => ConversationArchiveMessage(
  content: _decodeMessageContent(json['content'], attachments),
  messageType: _enumByName(MessageType.values, json['messageType']),
  isUser: _boolean(json['isUser']),
  status: _enumByName(MessageStatus.values, json['status']),
  createdAt: _dateTime(json['createdAt']),
  metadata: _decodeMetadata(json['metadata']),
  attachments: attachments,
);

String _decodeMessageContent(
  Object? value,
  List<ConversationArchiveAttachment> attachments,
) {
  final content = _string(value);
  if (content.trim().isEmpty && attachments.isEmpty) {
    throw const MalformedConversationArchiveException();
  }

  return content;
}

ConversationArchiveMetadata _decodeMetadataContent(Map<String, Object?> json) =>
    ConversationArchiveMetadata(
      toolCalls: _jsonList(json['toolCalls'])
          .map(_decodeToolCall)
          .toList(growable: false),
      a2uiMessages: _jsonList(json['a2uiMessages']).map(_string).toList(),
      isCompactionSummary: _boolean(json['isCompactionSummary']),
      compactedMessageIndexes: _jsonList(json['compactedMessageIndexes'])
          .map(_integer)
          .toList(),
    );

ConversationArchiveMetadata _decodeMetadataTokens(
  ConversationArchiveMetadata metadata,
  Map<String, Object?> json,
) => metadata.copyWith(
  promptTokens: _nullableInteger(json['promptTokens']),
  completionTokens: _nullableInteger(json['completionTokens']),
  totalTokens: _nullableInteger(json['totalTokens']),
  providerError: _nullableBoolean(json['providerError']),
  a2uiRequiresUserAction: _nullableBoolean(json['a2uiRequiresUserAction']),
);

ConversationArchiveMetadata _decodeMetadataCompaction(
  ConversationArchiveMetadata metadata,
  Map<String, Object?> json,
) => metadata.copyWith(
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

Map<String, Object?> _attachmentJson(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {
    'fileName',
    'displayName',
    'mimeType',
    'modality',
    'sizeBytes',
    'dataBase64',
  });

  return json;
}

ConversationArchiveAttachment _decodeArchiveAttachment(
  Map<String, Object?> json,
) => ConversationArchiveAttachment(
  fileName: _decodeFileName(json['fileName']),
  displayName: _nonEmptyString(json['displayName']),
  mimeType: _decodeMimeType(json['mimeType']),
  modality: _enumByName(MessageAttachmentModality.values, json['modality']),
  bytes: _decodeAttachmentBytes(json['dataBase64'], json['sizeBytes']),
);

String _decodeFileName(Object? value) {
  final fileName = _nonEmptyString(value);
  if (fileName == '.' ||
      fileName == '..' ||
      fileName != p.posix.basename(fileName.replaceAll(r'\', '/'))) {
    throw const MalformedConversationArchiveException();
  }

  return fileName;
}

String _decodeMimeType(Object? value) {
  final mimeType = _nonEmptyString(value);
  if (!RegExp(r'^[a-zA-Z0-9.+-]+/[a-zA-Z0-9.+-]+$').hasMatch(mimeType)) {
    throw const MalformedConversationArchiveException();
  }

  return mimeType;
}

Uint8List _decodeAttachmentBytes(Object? dataValue, Object? sizeValue) {
  final sizeBytes = _validatedAttachmentSize(sizeValue);
  final data = _string(dataValue);
  _validateBase64Length(data, sizeBytes);

  return _decodeBase64Attachment(data, sizeBytes);
}

int _validatedAttachmentSize(Object? value) {
  final sizeBytes = _integer(value);
  if (sizeBytes < 0 ||
      sizeBytes > ConversationArchiveCodec.maxAttachmentBytes) {
    throw const MalformedConversationArchiveException();
  }

  return sizeBytes;
}

void _validateBase64Length(String data, int sizeBytes) {
  final expectedLength = ((sizeBytes + 2) ~/ 3) * 4;
  if (data.length != expectedLength) {
    throw const MalformedConversationArchiveException();
  }
}

Uint8List _decodeBase64Attachment(String data, int sizeBytes) {
  try {
    final bytes = Uint8List.fromList(base64Decode(data));
    if (bytes.length != sizeBytes) {
      throw const MalformedConversationArchiveException();
    }

    return bytes;
  } on FormatException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      const MalformedConversationArchiveException(),
      stackTrace,
    );
  }
}

String _archiveFileName(String value) {
  final fileName = p.posix.basename(value.replaceAll(r'\', '/'));
  if (fileName.isEmpty) throw const MalformedConversationArchiveException();

  return fileName;
}

void _validateExportAttachmentSize(int expected, int actual) {
  if (actual != expected ||
      actual > ConversationArchiveCodec.maxAttachmentBytes) {
    throw const MalformedConversationArchiveException();
  }
}

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const MalformedConversationArchiveException._()
    with _$MalformedConversationArchiveException
    implements Exception {
  const factory() = _MalformedConversationArchiveException;

  String get localizationKey =>
      'chats.screens.chat_conversation.archive_invalid';
}

@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const UnsupportedArchiveVersionException._()
    with _$UnsupportedArchiveVersionException
    implements Exception {
  const factory(int version) = _UnsupportedArchiveVersionException;

  String get localizationKey =>
      'chats.screens.chat_conversation.archive_unsupported_version';
}
