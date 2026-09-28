import 'dart:convert';

import 'package:uuid/v7.dart';

class const WorkspaceConfigurationArchive({
  required final String workspaceName,
  required final List<WorkspaceConfigurationEntry> entries,
});

enum WorkspaceConfigurationKind {
  agent,
  agentSkill,
  agentToolPermission,
  compactionSetting,
  modelConnection,
  skill,
  skillResource,
  skillSetting,
  tool,
}

class const WorkspaceConfigurationEntry({
  required final WorkspaceConfigurationKind kind,
  required final String id,
  required final Map<String, Object?> data,
});

typedef _ArchiveId = ({WorkspaceConfigurationKind kind, String id});
typedef _ArchiveReference = ({String field, WorkspaceConfigurationKind kind});

const _maxWorkspaceNameLength = 200;
const _maxIdentifierLength = 200;
const int _maxFieldLength = 1024 * 1024;
const _maxUrlLength = 2048;
const _minUsagePercentage = 1;
const _maxUsagePercentage = 100;
const _minRemainingTokens = 0;
const _maxRemainingTokens = 1000000;

class const WorkspaceConfigurationArchiveException(final String localizationKey)
    implements Exception;

abstract final class WorkspaceConfigurationArchiveCodec {
  static const String format = 'auravibes.workspace-configuration';
  static const int version = 1;
  static const int maxArchiveBytes = 8 * 1024 * 1024;
  static const int maxEntries = 2000;

  static String? publicUrl(String? raw) {
    if (raw == null) return null;

    return _publicUri(.tryParse(raw));
  }

  static String encode(WorkspaceConfigurationArchive archive) {
    _validate(archive);
    final json = jsonEncode({
      'format': format,
      'version': version,
      'workspaceName': archive.workspaceName,
      'entries': [
        for (final entry in archive.entries)
          {'kind': entry.kind.name, 'id': entry.id, 'data': entry.data},
      ],
    });
    if (utf8.encode(json).length > maxArchiveBytes) {
      throw const WorkspaceConfigurationArchiveException(
        'workspace_archive.invalid',
      );
    }

    return json;
  }

  static WorkspaceConfigurationArchive decode(String json) {
    _validateArchiveSize(json);
    try {
      return _decodeArchive(json);
    } on WorkspaceConfigurationArchiveException {
      rethrow;
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const WorkspaceConfigurationArchiveException(
          'workspace_archive.invalid',
        ),
        stackTrace,
      );
    }
  }

  static WorkspaceConfigurationArchive remapIds(
    WorkspaceConfigurationArchive archive,
  ) {
    _validate(archive);
    final ids = _newIds(archive.entries);

    return WorkspaceConfigurationArchive(
      workspaceName: archive.workspaceName,
      entries: [for (final entry in archive.entries) _remapEntry(entry, ids)],
    );
  }
}

String? _publicUri(Uri? uri) {
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return null;
  }

  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  ).toString();
}

void _validateArchiveSize(String json) {
  if (utf8.encode(json).length >
      WorkspaceConfigurationArchiveCodec.maxArchiveBytes) {
    _invalid();
  }
}

WorkspaceConfigurationArchive _decodeArchive(String json) {
  final value = _archiveMap(json);
  final archive = WorkspaceConfigurationArchive(
    workspaceName: value['workspaceName'] as String,
    entries: _decodeEntries(value['entries']),
  );
  _validate(archive);

  return archive;
}

Map<String, dynamic> _archiveMap(String json) {
  final value = jsonDecode(json);
  if (value is! Map<String, dynamic> ||
      !_hasOnlyKeys(value, const {
        'format',
        'version',
        'workspaceName',
        'entries',
      }) ||
      value['format'] != WorkspaceConfigurationArchiveCodec.format) {
    throw const FormatException();
  }
  if (value['version'] != WorkspaceConfigurationArchiveCodec.version) {
    throw const WorkspaceConfigurationArchiveException(
      'workspace_archive.unsupported_version',
    );
  }

  return value;
}

List<WorkspaceConfigurationEntry> _decodeEntries(Object? rawEntries) {
  if (rawEntries is! List<Object?> ||
      rawEntries.length > WorkspaceConfigurationArchiveCodec.maxEntries) {
    throw const FormatException();
  }

  return [for (final raw in rawEntries) _decodeEntry(raw)];
}

WorkspaceConfigurationEntry _decodeEntry(Object? raw) {
  final fields = _entryMap(raw);

  return .new(
    kind: WorkspaceConfigurationKind.values.byName(fields['kind'] as String),
    id: fields['id'] as String,
    data: fields['data'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _entryMap(Object? raw) {
  if (raw is! Map<String, dynamic> ||
      !_hasOnlyKeys(raw, const {'kind', 'id', 'data'}) ||
      raw['kind'] is! String ||
      raw['id'] is! String ||
      raw['data'] is! Map<String, dynamic>) {
    throw const FormatException();
  }

  return raw;
}

Map<_ArchiveId, String> _newIds(List<WorkspaceConfigurationEntry> entries) => {
  for (final entry in entries)
    (kind: entry.kind, id: entry.id): entry.kind == .compactionSetting
        ? 'workspace'
        : const UuidV7().generate(),
};

WorkspaceConfigurationEntry _remapEntry(
  WorkspaceConfigurationEntry entry,
  Map<_ArchiveId, String> ids,
) => WorkspaceConfigurationEntry(
  kind: entry.kind,
  id: ids[(kind: entry.kind, id: entry.id)]!,
  data: _remapReferences(entry, ids),
);

Map<String, Object?> _remapReferences(
  WorkspaceConfigurationEntry entry,
  Map<_ArchiveId, String> ids,
) {
  final data = Map<String, Object?>.from(entry.data);
  for (final reference in _referencesFor(entry)) {
    data[reference.field] =
        ids[(kind: reference.kind, id: _requiredString(data, reference.field))];
  }

  return data;
}

List<_ArchiveReference> _referencesFor(WorkspaceConfigurationEntry entry) =>
    switch (entry.kind) {
      .agentSkill => [
        (field: 'agentId', kind: .agent),
        if (entry.data['source'] == 'user') (field: 'skillId', kind: .skill),
      ],
      .agentToolPermission => [
        (field: 'agentId', kind: .agent),
        (field: 'toolId', kind: .tool),
      ],
      .skillResource || .skillSetting when entry.data['source'] != 'app' => [
        (field: 'skillId', kind: .skill),
      ],
      _ => const [],
    };

void _validate(WorkspaceConfigurationArchive archive) {
  if (archive.workspaceName.trim().isEmpty ||
      archive.workspaceName.length > _maxWorkspaceNameLength ||
      archive.entries.length > WorkspaceConfigurationArchiveCodec.maxEntries) {
    _invalid();
  }
  final ids = _validateEntries(archive.entries);
  _validateReferences(archive.entries, ids);
}

Set<_ArchiveId> _validateEntries(List<WorkspaceConfigurationEntry> entries) {
  final ids = _validateEntryIdentities(entries);
  _validateToolIds(entries);

  return ids;
}

Set<_ArchiveId> _validateEntryIdentities(
  List<WorkspaceConfigurationEntry> entries,
) {
  final ids = <_ArchiveId>{};
  for (final entry in entries) {
    if (entry.id.isEmpty ||
        entry.id.length > _maxIdentifierLength ||
        !ids.add((kind: entry.kind, id: entry.id))) {
      _invalid();
    }
    _validateEntry(entry);
  }

  return ids;
}

void _validateToolIds(List<WorkspaceConfigurationEntry> entries) {
  final toolIds = <String>{};
  for (final entry in entries.where((entry) => entry.kind == .tool)) {
    if (!toolIds.add(_requiredString(entry.data, 'toolId'))) _invalid();
  }
}

void _validateReferences(
  List<WorkspaceConfigurationEntry> entries,
  Set<_ArchiveId> ids,
) {
  for (final entry in entries) {
    if (_referencesFor(entry)
        .any((reference) => !_hasReference(entry, ids, reference))) {
      _invalid();
    }
  }
}

bool _hasReference(
  WorkspaceConfigurationEntry entry,
  Set<_ArchiveId> ids,
  _ArchiveReference reference,
) => ids.contains((
  kind: reference.kind,
  id: _requiredString(entry.data, reference.field),
));

const _entryFields = <WorkspaceConfigurationKind, Set<String>>{
  .agent: {'name', 'description', 'content', 'isEnabled', 'visibility'},
  .agentSkill: {'agentId', 'skillId', 'source'},
  .agentToolPermission: {'agentId', 'toolId', 'permissionMode'},
  .compactionSetting: {
    'autoCompactionEnabled',
    'usagePercentageThreshold',
    'remainingTokenThreshold',
  },
  .modelConnection: {'name', 'providerId', 'url'},
  .skill: {
    'source',
    'kind',
    'title',
    'slug',
    'description',
    'content',
    'isEnabled',
  },
  .skillResource: {'skillId', 'title', 'slug', 'description', 'content'},
  .skillSetting: {'skillId', 'source', 'isEnabled'},
  .tool: {'toolId', 'isEnabled', 'permissionMode'},
};

void _validateEntry(WorkspaceConfigurationEntry entry) {
  _validateEntryFields(entry);
  _validateEntryValues(entry);
}

void _validateEntryFields(WorkspaceConfigurationEntry entry) {
  if (!_hasOnlyKeys(entry.data, _entryFields[entry.kind]!)) _invalid();
}

void _validateEntryValues(WorkspaceConfigurationEntry entry) {
  final data = entry.data;
  switch (entry.kind) {
    case .agent:
      _validateAgent(data);
    case .agentSkill:
      _validateAgentSkill(data);
    case .agentToolPermission:
      _validatePermissionEntry(data, 'agentId', 'toolId');
    case .compactionSetting:
      _validateCompaction(entry);
    case .modelConnection:
      _validateModelConnection(data);
    case .skill:
      _validateSkill(data);
    case .skillResource:
      _validateSkillResource(data);
    case .skillSetting:
      _validateSkillSetting(data);
    case .tool:
      _validateTool(data);
  }
}

void _validateAgent(Map<String, Object?> data) {
  _strings(data, const ['name', 'description', 'content', 'visibility']);
  _boolean(data, 'isEnabled');
  if (!_oneOf(data['visibility'], const [
    'both',
    'chatSelector',
    'subAgentList',
  ])) {
    _invalid();
  }
}

void _validateAgentSkill(Map<String, Object?> data) {
  _strings(data, const ['agentId', 'skillId', 'source']);
  _validateSource(data['source']);
}

void _validatePermissionEntry(
  Map<String, Object?> data,
  String firstId,
  String secondId,
) {
  _strings(data, [firstId, secondId, 'permissionMode']);
  _permission(data['permissionMode']);
}

void _validateCompaction(WorkspaceConfigurationEntry entry) {
  if (entry.id != 'workspace') _invalid();
  _boolean(entry.data, 'autoCompactionEnabled');
  _integer(
    entry.data,
    'usagePercentageThreshold',
    _minUsagePercentage,
    _maxUsagePercentage,
  );
  _integer(
    entry.data,
    'remainingTokenThreshold',
    _minRemainingTokens,
    _maxRemainingTokens,
  );
}

void _validateModelConnection(Map<String, Object?> data) {
  _strings(data, const ['name', 'providerId']);
  final url = data['url'];
  if (url != null &&
      (url is! String ||
          url.length > _maxUrlLength ||
          WorkspaceConfigurationArchiveCodec.publicUrl(url) != url)) {
    _invalid();
  }
}

void _validateSkill(Map<String, Object?> data) {
  _strings(data, const [
    'source',
    'kind',
    'title',
    'slug',
    'description',
    'content',
  ]);
  _boolean(data, 'isEnabled');
  _validateSource(data['source']);
}

void _validateSkillResource(Map<String, Object?> data) {
  _strings(data, const ['skillId', 'title', 'slug', 'description', 'content']);
}

void _validateSkillSetting(Map<String, Object?> data) {
  _strings(data, const ['skillId', 'source']);
  _boolean(data, 'isEnabled');
  _validateSource(data['source']);
}

void _validateTool(Map<String, Object?> data) {
  _strings(data, const ['toolId', 'permissionMode']);
  _boolean(data, 'isEnabled');
  _permission(data['permissionMode']);
}

void _validateSource(Object? source) {
  if (!_oneOf(source, const ['user', 'app'])) _invalid();
}

bool _oneOf(Object? value, List<Object> allowed) => allowed.contains(value);

bool _hasOnlyKeys(Map<String, Object?> data, Set<String> fields) =>
    data.keys.toSet().containsAll(fields) && fields.containsAll(data.keys);

void _strings(Map<String, Object?> data, List<String> fields) {
  for (final field in fields) {
    final value = data[field];
    if (value is! String || value.length > _maxFieldLength) _invalid();
  }
}

String _requiredString(Map<String, Object?> data, String field) {
  final value = data[field];
  if (value is! String) _invalid();

  return value;
}

void _boolean(Map<String, Object?> data, String field) {
  if (data[field] is! bool) _invalid();
}

void _integer(Map<String, Object?> data, String field, int min, int max) {
  final value = data[field];
  if (value is! int || value < min || value > max) _invalid();
}

void _permission(Object? mode) {
  if (mode != 'alwaysAsk' && mode != 'alwaysAllow' && mode != 'alwaysDeny') {
    _invalid();
  }
}

Never _invalid() => throw const WorkspaceConfigurationArchiveException(
  'workspace_archive.invalid',
);
