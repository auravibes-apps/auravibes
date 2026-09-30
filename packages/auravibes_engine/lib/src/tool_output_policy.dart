import 'dart:convert';

const int defaultToolOutputBytes = 16 * 1024;
const int maxPersistedToolOutputBytes = 256 * 1024;
const _projectionFormat = 'auravibes.tool-output-projection.v1';

final class const AgentToolOutputPolicy({
  final int? maxBytes = defaultToolOutputBytes,
  final String? justification,
}) {
  static AgentToolOutputPolicy full({required String justification}) {
    if (justification.trim().isEmpty) {
      throw ArgumentError.value(
        justification,
        'justification',
        'Full tool output requires a reason.',
      );
    }
    return .new(maxBytes: null, justification: justification);
  }
}

final class const AgentToolOutputProjection({
  required final String text,
  required final String persistedText,
  required final bool truncated,
  required final int originalBytes,
  required final bool fullOutputForContext,
});

final class const AgentToolOutputProjectionMetadata({
  required final int originalBytes,
  required final int limitBytes,
});

AgentToolOutputProjectionMetadata? readToolOutputProjectionMetadata(
  String source,
) {
  final projection = _readExistingProjection(source);
  if (projection == null) return null;

  return AgentToolOutputProjectionMetadata(
    originalBytes: projection.projection.originalBytes,
    limitBytes: projection.limitBytes,
  );
}

AgentToolOutputProjection projectToolOutput(
  String source, {
  AgentToolOutputPolicy policy = const AgentToolOutputPolicy(),
}) {
  final maxBytes = policy.maxBytes;
  _validateToolOutputPolicy(policy);
  final originalBytes = _utf8ByteLength(source);
  final existingProjection = originalBytes <= defaultToolOutputBytes
      ? _readExistingProjection(source)
      : null;
  if (existingProjection != null) {
    if (maxBytes == null || maxBytes >= existingProjection.limitBytes) {
      return existingProjection.projection;
    }
    return AgentToolOutputProjection(
      text: _projectToolOutputText(
        existingProjection.content,
        existingProjection.projection.originalBytes,
        maxBytes,
      ),
      persistedText: source,
      truncated: true,
      originalBytes: existingProjection.projection.originalBytes,
      fullOutputForContext: false,
    );
  }

  final persistTruncated = originalBytes > maxPersistedToolOutputBytes;
  final contextLimit = maxBytes == null && persistTruncated
      ? defaultToolOutputBytes
      : maxBytes;
  final text = _projectToolOutputText(source, originalBytes, contextLimit);

  return AgentToolOutputProjection(
    text: text,
    persistedText: persistTruncated ? text : source,
    truncated:
        persistTruncated ||
        (contextLimit != null && originalBytes > contextLimit),
    originalBytes: originalBytes,
    fullOutputForContext: maxBytes == null && !persistTruncated,
  );
}

void _validateToolOutputPolicy(AgentToolOutputPolicy policy) {
  final maxBytes = policy.maxBytes;
  if (maxBytes == null) {
    if (policy.justification?.trim().isNotEmpty != true) {
      throw ArgumentError.value(
        policy.justification,
        'justification',
        'Full tool output requires a reason.',
      );
    }
  } else if (maxBytes < 256 || maxBytes > defaultToolOutputBytes) {
    throw ArgumentError.value(
      maxBytes,
      'maxBytes',
      'Invalid tool output limit.',
    );
  }
}

int _utf8ByteLength(String value) {
  var length = 0;
  for (final rune in value.runes) {
    length += switch (rune) {
      <= 0x7f => 1,
      <= 0x7ff => 2,
      <= 0xffff => 3,
      _ => 4,
    };
  }

  return length;
}

String _projectToolOutputText(String source, int originalBytes, int? maxBytes) {
  if (maxBytes == null || originalBytes <= maxBytes) return source;
  final metadata = <String, Object>{
    'format': _projectionFormat,
    'notice': '[tool output truncated]',
    'truncated': true,
    'originalBytes': originalBytes,
    'limitBytes': maxBytes,
  };
  final wrapper = <String, Object>{'_toolOutput': metadata, 'content': ''};
  var remaining = maxBytes - utf8.encode(jsonEncode(wrapper)).length;
  if (remaining < 0) {
    throw ArgumentError.value(maxBytes, 'maxBytes', 'Too small for metadata.');
  }
  final prefix = StringBuffer();
  for (final rune in source.runes) {
    final character = String.fromCharCode(rune);
    final encodedBytes = utf8.encode(jsonEncode(character)).length - 2;
    if (encodedBytes > remaining) break;
    prefix.write(character);
    remaining -= encodedBytes;
  }
  wrapper['content'] = prefix.toString();
  return jsonEncode(wrapper);
}

({AgentToolOutputProjection projection, String content, int limitBytes})?
_readExistingProjection(String source) {
  Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return null;
  }
  if (decoded
      case {
        '_toolOutput': {
          'format': _projectionFormat,
          'notice': '[tool output truncated]',
          'truncated': true,
          'originalBytes': final int originalBytes,
          'limitBytes': final int limitBytes,
        },
        'content': final String content,
      }
      when originalBytes > limitBytes) {
    if (limitBytes < 256 ||
        limitBytes > defaultToolOutputBytes ||
        _utf8ByteLength(source) > limitBytes ||
        source !=
            jsonEncode({
              '_toolOutput': {
                'format': _projectionFormat,
                'notice': '[tool output truncated]',
                'truncated': true,
                'originalBytes': originalBytes,
                'limitBytes': limitBytes,
              },
              'content': content,
            })) {
      return null;
    }
    return (
      projection: AgentToolOutputProjection(
        text: source,
        persistedText: source,
        truncated: true,
        originalBytes: originalBytes,
        fullOutputForContext: false,
      ),
      content: content,
      limitBytes: limitBytes,
    );
  }

  return null;
}
