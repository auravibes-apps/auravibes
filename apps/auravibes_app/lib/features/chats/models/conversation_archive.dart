import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'conversation_archive.freezed.dart';

typedef ConversationArchiveCreationInput = ({
  ConversationEntity conversation,
  List<MessageEntity> messages,
  Future<Uint8List> Function(String localPath) readAttachmentBytes,
  String? modelLabel,
  ConversationArchiveAgentContext? agentContext,
});

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
    ConversationArchiveAgentContext? agentContext,
  }) = _ConversationArchive;
}

class ConversationArchiveAgentContext({
  required final bool isComplete,
  required List<ConversationArchiveAgentContextEntry> entriesInput,
  required List<ConversationArchiveToolSelection> toolSelectionsInput,
}) {
  final List<ConversationArchiveAgentContextEntry> entries = .unmodifiable(
    entriesInput,
  );
  final List<ConversationArchiveToolSelection> toolSelections = .unmodifiable(
    toolSelectionsInput,
  );
}

class const ConversationArchiveAgentContextEntry({
  required final int? afterMessageIndex,
  required final DateTime createdAt,
  required final String updateJson,
});

class const ConversationArchiveToolSelection({
  required final String? groupName,
  required final String toolName,
  required final bool isEnabled,
  required final ToolPermissionMode permissionMode,
});

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
  static const bundleFormat = 'auravibes.conversations';
  static const version = 2;
  static const legacyVersion = 1;
  static const bundleVersion = 1;
  static const agentContextVersion = 1;
  static const int maxArchiveBytes = 8 * 1024 * 1024;
  static const int maxAttachmentBytes = 5 * 1024 * 1024;
  static const int maxAttachmentBytesTotal = 6 * 1024 * 1024;
  static const int maxMessages = 10000;
  static const int maxConversations = 100;
  static const int maxAgentContextUpdates = 10000;
  static const int maxAgentContextTools = 500;
  static const int maxAgentContextMessages = 1000;
  static const int maxAttachmentsPerMessage = 25;
  static const int maxToolCallsPerMessage = 100;
  static const int maxA2uiMessagesPerMessage = 100;
  static const int maxJsonDepth = 32;
  static const int maxStringLength = 1024 * 1024;

  static Future<String> exportConversation(
    ConversationArchiveCreationInput input,
  ) async => encode(await createConversationArchive(input));

  static Future<ConversationArchive> createConversationArchive(
    ConversationArchiveCreationInput input,
  ) async {
    final (
      :conversation,
      :messages,
      :readAttachmentBytes,
      :modelLabel,
      :agentContext,
    ) = input;
    final archivedMessages = await _archiveMessages(
      messages,
      readAttachmentBytes,
    );

    return ConversationArchive(
      title: conversation.title,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      messages: archivedMessages,
      modelLabel: modelLabel,
      agentContext: agentContext,
    );
  }

  static String encodeMany(List<ConversationArchive> archives) {
    final archiveJson = _encodeArchives(archives);
    final encoded = _encodeArchiveBundle(archiveJson);
    _validateJsonDepth(encoded);

    return encoded;
  }

  static String encode(ConversationArchive archive) {
    final archiveJson = _archiveToJson(archive);
    final _ = _decodeArchive(archiveJson);
    final json = jsonEncode(archiveJson);
    if (utf8.encode(json).length > maxArchiveBytes) {
      throw const MalformedConversationArchiveException();
    }
    _validateJsonDepth(json);

    return json;
  }

  static ConversationArchive decode(String json) {
    if (!_hasValidUtf8Length(json, maxArchiveBytes)) {
      throw const MalformedConversationArchiveException();
    }
    _validateJsonDepth(json);

    return _decodeArchive(_decodeJson(json));
  }

  static List<ConversationArchive> decodeMany(String json) {
    if (!_hasValidUtf8Length(json, maxArchiveBytes)) {
      throw const MalformedConversationArchiveException();
    }
    _validateJsonDepth(json);
    final root = _jsonMap(_decodeJson(json));
    if (root['format'] == format) return [_decodeArchive(root)];

    return _decodeArchiveBundle(root);
  }
}

List<Map<String, Object?>> _encodeArchives(List<ConversationArchive> archives) {
  if (archives.isEmpty ||
      archives.length > ConversationArchiveCodec.maxConversations) {
    throw const MalformedConversationArchiveException();
  }
  final archiveJson = [for (final archive in archives) _archiveToJson(archive)];
  _validateArchiveBundleTotals(archiveJson);

  return archiveJson;
}

void _validateArchiveBundleTotals(List<Map<String, Object?>> archives) {
  var messageCount = 0;
  var attachmentBytes = 0;
  for (final archiveJson in archives) {
    final decoded = _decodeArchive(archiveJson);
    messageCount += decoded.messages.length;
    attachmentBytes += _archiveAttachmentBytes(decoded);
    if (messageCount > ConversationArchiveCodec.maxMessages ||
        attachmentBytes > ConversationArchiveCodec.maxAttachmentBytesTotal) {
      throw const MalformedConversationArchiveException();
    }
  }
}

String _encodeArchiveBundle(List<Map<String, Object?>> archives) {
  final encoded = jsonEncode({
    'format': ConversationArchiveCodec.bundleFormat,
    'version': ConversationArchiveCodec.bundleVersion,
    'conversations': archives,
  });
  if (!_hasValidUtf8Length(encoded, ConversationArchiveCodec.maxArchiveBytes)) {
    throw const MalformedConversationArchiveException();
  }

  return encoded;
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
  'agentContext': _agentContextToJson(archive.agentContext),
};

Map<String, Object?>? _agentContextToJson(
  ConversationArchiveAgentContext? context,
) {
  if (context == null) return null;
  _validateAgentContextForEncoding(context);

  return {
    'version': ConversationArchiveCodec.agentContextVersion,
    'complete': context.isComplete,
    'entries': _agentContextEntriesToJson(context.entries),
    'toolSelections': _agentContextSelectionsToJson(context.toolSelections),
  };
}

void _validateAgentContextForEncoding(ConversationArchiveAgentContext context) {
  if (context.entries.length >
          ConversationArchiveCodec.maxAgentContextUpdates ||
      context.toolSelections.length >
          ConversationArchiveCodec.maxAgentContextTools ||
      !context.isComplete && context.entries.isNotEmpty) {
    throw const MalformedConversationArchiveException();
  }
}

List<Map<String, Object?>> _agentContextEntriesToJson(
  List<ConversationArchiveAgentContextEntry> entries,
) => [
  for (final entry in entries)
    {
      'afterMessageIndex': entry.afterMessageIndex,
      'createdAt': entry.createdAt.toIso8601String(),
      'update': _agentContextUpdateToJson(entry.updateJson),
    },
];

List<Map<String, Object?>> _agentContextSelectionsToJson(
  List<ConversationArchiveToolSelection> selections,
) => [
  for (final selection in selections)
    {
      'groupName': selection.groupName,
      'toolName': selection.toolName,
      'isEnabled': selection.isEnabled,
      'permissionMode': selection.permissionMode.name,
    },
];

Map<String, Object?> _agentContextUpdateToJson(String updateJson) {
  final update = _jsonMap(_decodeJson(updateJson));
  _validateAgentContextUpdate(update);

  return update;
}

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

void _validateAgentContextMessageIndexes(ConversationArchive archive) {
  final context = archive.agentContext;
  if (context == null) return;
  var state = (lastAnchor: -1, sawVisibleAnchor: false);
  for (final entry in context.entries) {
    state = _nextAgentContextAnchorState(
      entry.afterMessageIndex,
      state,
      archive.messages.length,
    );
  }
}

({int lastAnchor, bool sawVisibleAnchor}) _nextAgentContextAnchorState(
  int? anchor,
  ({int lastAnchor, bool sawVisibleAnchor}) state,
  int messageCount,
) {
  if (anchor == null) {
    if (state.sawVisibleAnchor) {
      throw const MalformedConversationArchiveException();
    }

    return state;
  }
  if (anchor < state.lastAnchor || anchor >= messageCount) {
    throw const MalformedConversationArchiveException();
  }

  return (lastAnchor: anchor, sawVisibleAnchor: true);
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

void _requireAllowedKeys(
  Map<String, Object?> json,
  Set<String> allowed,
  Set<String> required,
) {
  if (json.keys.toSet().difference(allowed).isNotEmpty ||
      required.difference(json.keys.toSet()).isNotEmpty) {
    throw const MalformedConversationArchiveException();
  }
}

String _string(Object? value) {
  if (value is String &&
      value.length <= ConversationArchiveCodec.maxStringLength) {
    return value;
  }
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

bool _hasValidUtf8Length(String value, int maximumBytes) {
  var byteCount = 0;
  for (var index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    final length = _utf8CodeUnitLength(value, codeUnit, index);
    if (length == null) return false;
    if (length == _utf8SurrogatePairLength) index++;
    byteCount += length;
    if (byteCount > maximumBytes) return false;
  }

  return true;
}

const _utf8AsciiLimit = 0x7F;
const _utf8TwoByteLimit = 0x7FF;
const _utf8LeadingSurrogateStart = 0xD800;
const _utf8LeadingSurrogateEnd = 0xDBFF;
const _utf8TrailingSurrogateStart = 0xDC00;
const _utf8TrailingSurrogateEnd = 0xDFFF;
const _utf8AsciiLength = 1;
const _utf8TwoByteLength = 2;
const _utf8ThreeByteLength = 3;
const _utf8SurrogatePairLength = 4;

int? _utf8CodeUnitLength(String value, int codeUnit, int index) {
  if (codeUnit <= _utf8AsciiLimit) return _utf8AsciiLength;
  if (codeUnit <= _utf8TwoByteLimit) return _utf8TwoByteLength;
  if (codeUnit < _utf8LeadingSurrogateStart) return _utf8ThreeByteLength;
  if (codeUnit > _utf8TrailingSurrogateEnd) return _utf8ThreeByteLength;

  return _utf8SurrogateLength(value, codeUnit, index);
}

int? _utf8SurrogateLength(String value, int codeUnit, int index) {
  if (codeUnit > _utf8LeadingSurrogateEnd) return null;
  if (index + 1 >= value.length) return null;
  final trailing = value.codeUnitAt(index + 1);
  if (trailing < _utf8TrailingSurrogateStart ||
      trailing > _utf8TrailingSurrogateEnd) {
    return null;
  }

  return _utf8SurrogatePairLength;
}

const _jsonBackslash = 0x5C;
const _jsonDoubleQuote = 0x22;
const _jsonOpenBrace = 0x7B;
const _jsonOpenBracket = 0x5B;
const _jsonCloseBrace = 0x7D;
const _jsonCloseBracket = 0x5D;

void _validateJsonDepth(String json) {
  var state = (depth: 0, insideString: false, escaped: false);
  for (final codeUnit in json.codeUnits) {
    state = _nextJsonScanState(state, codeUnit);
    if (state.depth > ConversationArchiveCodec.maxJsonDepth) {
      throw const MalformedConversationArchiveException();
    }
  }
}

({int depth, bool insideString, bool escaped}) _nextJsonScanState(
  ({int depth, bool insideString, bool escaped}) state,
  int codeUnit,
) {
  if (state.insideString) return _scanInsideJsonString(state, codeUnit);

  return _scanOutsideJsonString(state, codeUnit);
}

({int depth, bool insideString, bool escaped}) _scanInsideJsonString(
  ({int depth, bool insideString, bool escaped}) state,
  int codeUnit,
) {
  if (state.escaped) {
    return (depth: state.depth, insideString: true, escaped: false);
  }
  if (codeUnit == _jsonBackslash) {
    return (depth: state.depth, insideString: true, escaped: true);
  }
  if (codeUnit == _jsonDoubleQuote) {
    return (depth: state.depth, insideString: false, escaped: false);
  }

  return state;
}

({int depth, bool insideString, bool escaped}) _scanOutsideJsonString(
  ({int depth, bool insideString, bool escaped}) state,
  int codeUnit,
) {
  if (codeUnit == _jsonDoubleQuote) {
    return (depth: state.depth, insideString: true, escaped: false);
  }
  if (codeUnit == _jsonOpenBrace || codeUnit == _jsonOpenBracket) {
    return (depth: state.depth + 1, insideString: false, escaped: false);
  }
  if (codeUnit == _jsonCloseBrace || codeUnit == _jsonCloseBracket) {
    return (depth: state.depth - 1, insideString: false, escaped: false);
  }

  return state;
}

ConversationArchive _decodeArchive(Object? value) {
  final root = _jsonMap(value);
  _validateArchiveRoot(root);
  final _ = _validateArchiveResourceLimits(root);
  final archive = _decodeArchiveContents(root);
  _validateMessageIndexes(archive.messages);
  _validateAgentContextMessageIndexes(archive);

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
    agentContext: root['version'] == ConversationArchiveCodec.version
        ? _decodeAgentContext(root['agentContext'])
        : null,
  );
}

ConversationArchiveAgentContext? _decodeAgentContext(Object? value) {
  if (value == null) return null;
  final json = _jsonMap(value);
  _validateAgentContextHeader(json);
  final isComplete = _boolean(json['complete']);

  return ConversationArchiveAgentContext(
    isComplete: isComplete,
    entriesInput: _decodeAgentContextEntries(json['entries'], isComplete),
    toolSelectionsInput: _decodeAgentContextSelections(json['toolSelections']),
  );
}

void _validateAgentContextHeader(Map<String, Object?> json) {
  final version = _integer(json['version']);
  if (version != ConversationArchiveCodec.agentContextVersion) {
    throw UnsupportedArchiveVersionException(version);
  }
  _requireKeys(json, const {
    'version',
    'complete',
    'entries',
    'toolSelections',
  });
}

List<ConversationArchiveAgentContextEntry> _decodeAgentContextEntries(
  Object? value,
  bool isComplete,
) {
  final entries = _limitedList(
    value,
    ConversationArchiveCodec.maxAgentContextUpdates,
  ).map(_decodeAgentContextEntry).toList(growable: false);
  if (!isComplete && entries.isNotEmpty) {
    throw const MalformedConversationArchiveException();
  }

  return entries;
}

List<ConversationArchiveToolSelection> _decodeAgentContextSelections(
  Object? value,
) => _limitedList(
  value,
  ConversationArchiveCodec.maxAgentContextTools,
).map(_decodeToolSelection).toList(growable: false);

ConversationArchiveAgentContextEntry _decodeAgentContextEntry(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {'afterMessageIndex', 'createdAt', 'update'});
  final update = _jsonMap(json['update']);
  _validateAgentContextUpdate(update);

  return ConversationArchiveAgentContextEntry(
    afterMessageIndex: _nullableInteger(json['afterMessageIndex']),
    createdAt: _dateTime(json['createdAt']),
    updateJson: jsonEncode(update),
  );
}

ConversationArchiveToolSelection _decodeToolSelection(Object? value) {
  final json = _jsonMap(value);
  _requireKeys(json, const {
    'groupName',
    'toolName',
    'isEnabled',
    'permissionMode',
  });

  return ConversationArchiveToolSelection(
    groupName: _nullableString(json['groupName']),
    toolName: _nonEmptyString(json['toolName']),
    isEnabled: _boolean(json['isEnabled']),
    permissionMode: _enumByName(
      ToolPermissionMode.values,
      json['permissionMode'],
    ),
  );
}

void _validateAgentContextResourceLimits(Object? value) {
  if (value == null) return;
  final json = _jsonMap(value);
  _validateAgentContextHeader(json);
  final isComplete = _boolean(json['complete']);
  final entries = _limitedList(
    json['entries'],
    ConversationArchiveCodec.maxAgentContextUpdates,
  );
  if (!isComplete && entries.isNotEmpty) {
    throw const MalformedConversationArchiveException();
  }
  entries.forEach(_validateAgentContextEntryResources);
  _limitedList(
    json['toolSelections'],
    ConversationArchiveCodec.maxAgentContextTools,
  ).forEach(_validateAgentContextSelectionResources);
}

void _validateAgentContextEntryResources(Object? value) {
  final item = _jsonMap(value);
  _requireKeys(item, const {'afterMessageIndex', 'createdAt', 'update'});
  final anchor = _nullableInteger(item['afterMessageIndex']);
  if (anchor != null && anchor < 0) {
    throw const MalformedConversationArchiveException();
  }
  final _ = _dateTime(item['createdAt']);
  _validateAgentContextUpdate(_jsonMap(item['update']));
}

void _validateAgentContextSelectionResources(Object? value) {
  final item = _jsonMap(value);
  _requireKeys(item, const {
    'groupName',
    'toolName',
    'isEnabled',
    'permissionMode',
  });
  final _ = _nullableString(item['groupName']);
  final _ = _nonEmptyString(item['toolName']);
  final _ = _boolean(item['isEnabled']);
  final _ = _enumByName(ToolPermissionMode.values, item['permissionMode']);
}

void _validateAgentContextUpdate(Map<String, Object?> json) {
  _requireAllowedKeys(
    json,
    const {
      'version',
      'toolsAdded',
      'toolsRemoved',
      'contextMessages',
      'toolOrder',
      'approvalStates',
    },
    const {'version', 'toolsAdded', 'toolsRemoved'},
  );
  final version = _integer(json['version']);
  if (version != ConversationArchiveCodec.agentContextVersion) {
    throw UnsupportedArchiveVersionException(version);
  }
  _limitedList(
    json['toolsAdded'],
    ConversationArchiveCodec.maxAgentContextTools,
  ).forEach(_validateAgentContextAddedTool);
  _limitedList(
    json['toolsRemoved'],
    ConversationArchiveCodec.maxAgentContextTools,
  ).forEach(_nonEmptyString);
  _validateOptionalAgentContextLists(json);
  _validateAgentContextApprovals(json['approvalStates']);
}

void _validateAgentContextAddedTool(Object? value) {
  final item = _jsonMap(value);
  _requireKeys(item, const {
    'name',
    'description',
    'inputJsonSchema',
    'requiresCredential',
  });
  final _ = _nonEmptyString(item['name']);
  final _ = _string(item['description']);
  final _ = _jsonMap(item['inputJsonSchema']);
  final _ = _boolean(item['requiresCredential']);
}

void _validateOptionalAgentContextLists(Map<String, Object?> json) {
  if (json['contextMessages'] case final contextMessages?) {
    _limitedList(
      contextMessages,
      ConversationArchiveCodec.maxAgentContextMessages,
    ).forEach(_validateAgentContextMessage);
  }
  if (json['toolOrder'] case final order?) {
    _limitedList(
      order,
      ConversationArchiveCodec.maxAgentContextTools,
    ).forEach(_nonEmptyString);
  }
}

void _validateAgentContextApprovals(Object? value) {
  if (value == null) return;
  final map = _jsonMap(value);
  if (map.length > ConversationArchiveCodec.maxAgentContextTools) {
    throw const MalformedConversationArchiveException();
  }
  map.entries.forEach(_validateAgentContextApproval);
}

void _validateAgentContextMessage(Object? value) {
  final item = _jsonMap(value);
  _requireAllowedKeys(
    item,
    const {'role', 'content', 'kind'},
    const {'role', 'content'},
  );
  final role = _string(item['role']);
  if (role != 'system' && role != 'skill') {
    throw const MalformedConversationArchiveException();
  }
  final _ = _string(item['content']);
  final _ = _nullableString(item['kind']);
}

void _validateAgentContextApproval(MapEntry<String, Object?> entry) {
  final _ = _nonEmptyString(entry.key);
  final _ = _string(entry.value);
}

List<ConversationArchive> _decodeArchiveBundle(Map<String, Object?> root) {
  _validateArchiveBundleHeader(root);
  final items = _limitedList(
    root['conversations'],
    ConversationArchiveCodec.maxConversations,
  );
  if (items.isEmpty) throw const MalformedConversationArchiveException();

  return _validatedArchiveBundleRoots(items)
      .map(_decodeArchive)
      .toList(growable: false);
}

void _validateArchiveBundleHeader(Map<String, Object?> root) {
  if (root['format'] != ConversationArchiveCodec.bundleFormat) {
    throw const MalformedConversationArchiveException();
  }
  final version = _integer(root['version']);
  if (version != ConversationArchiveCodec.bundleVersion) {
    throw UnsupportedArchiveVersionException(version);
  }
  _requireKeys(root, const {'format', 'version', 'conversations'});
}

List<Map<String, Object?>> _validatedArchiveBundleRoots(List<Object?> items) {
  final archiveRoots = <Map<String, Object?>>[];
  var totals = (messages: 0, attachmentBytes: 0);
  for (final item in items) {
    final validated = _validateArchiveBundleItem(item);
    totals = _addArchiveBundleItem(totals, validated);
    archiveRoots.add(validated.root);
  }

  return archiveRoots;
}

typedef _ValidatedArchiveBundleItem = ({
  Map<String, Object?> root,
  int messages,
  int attachmentBytes,
});

_ValidatedArchiveBundleItem _validateArchiveBundleItem(Object? value) {
  final root = _jsonMap(value);
  _validateArchiveRoot(root);

  return (
    root: root,
    messages: _limitedList(
      root['messages'],
      ConversationArchiveCodec.maxMessages,
    ).length,
    attachmentBytes: _validateArchiveResourceLimits(root),
  );
}

({int messages, int attachmentBytes}) _addArchiveBundleItem(
  ({int messages, int attachmentBytes}) totals,
  _ValidatedArchiveBundleItem item,
) {
  final messages = totals.messages + item.messages;
  final attachmentBytes = totals.attachmentBytes + item.attachmentBytes;
  if (messages > ConversationArchiveCodec.maxMessages ||
      attachmentBytes > ConversationArchiveCodec.maxAttachmentBytesTotal) {
    throw const MalformedConversationArchiveException();
  }

  return (messages: messages, attachmentBytes: attachmentBytes);
}

int _archiveAttachmentBytes(ConversationArchive archive) =>
    archive.messages.fold<int>(
      0,
      (total, message) =>
          total +
          message.attachments.fold(0, (sum, item) => sum + item.bytes.length),
    );

List<ConversationArchiveMessage> _decodeMessages(Object? value) =>
    _jsonList(value).map(_decodeMessage).toList(growable: false);

int _validateArchiveResourceLimits(Map<String, Object?> root) {
  final messages = _limitedList(
    root['messages'],
    ConversationArchiveCodec.maxMessages,
  );
  var attachmentBytes = 0;
  for (final messageValue in messages) {
    attachmentBytes += _validateMessageResourceLimits(messageValue);
    if (attachmentBytes > ConversationArchiveCodec.maxAttachmentBytesTotal) {
      throw const MalformedConversationArchiveException();
    }
  }
  final agentContext = root['agentContext'];
  if (root['version'] == ConversationArchiveCodec.version) {
    _validateAgentContextResourceLimits(agentContext);
  }

  return attachmentBytes;
}

int _validateMessageResourceLimits(Object? value) {
  final message = _jsonMap(value);
  final attachments = _limitedList(
    message['attachments'],
    ConversationArchiveCodec.maxAttachmentsPerMessage,
  );
  final metadata = _jsonMap(message['metadata']);
  _validateListLength(
    metadata['toolCalls'],
    ConversationArchiveCodec.maxToolCallsPerMessage,
  );
  _validateListLength(
    metadata['a2uiMessages'],
    ConversationArchiveCodec.maxA2uiMessagesPerMessage,
  );
  var attachmentBytes = 0;
  for (final attachmentValue in attachments) {
    final attachment = _jsonMap(attachmentValue);
    attachmentBytes += _validatedAttachmentSize(attachment['sizeBytes']);
  }

  return attachmentBytes;
}

List<Object?> _limitedList(Object? value, int maximumLength) {
  final list = _jsonList(value);
  _validateListLength(list, maximumLength);

  return list;
}

void _validateListLength(Object? value, int maximumLength) {
  if (_jsonList(value).length > maximumLength) {
    throw const MalformedConversationArchiveException();
  }
}

void _validateArchiveRoot(Map<String, Object?> root) {
  if (root['format'] != ConversationArchiveCodec.format) {
    throw const MalformedConversationArchiveException();
  }
  final version = _integer(root['version']);
  if (version != ConversationArchiveCodec.legacyVersion &&
      version != ConversationArchiveCodec.version) {
    throw UnsupportedArchiveVersionException(version);
  }
  _requireKeys(
    root,
    version == ConversationArchiveCodec.legacyVersion
        ? const {'format', 'version', 'conversation', 'messages'}
        : const {
            'format',
            'version',
            'conversation',
            'messages',
            'agentContext',
          },
  );
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
  final data = _base64String(dataValue);
  _validateBase64Length(data, sizeBytes);

  return _decodeBase64Attachment(data, sizeBytes);
}

String _base64String(Object? value) {
  if (value is String) return value;
  throw const MalformedConversationArchiveException();
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
