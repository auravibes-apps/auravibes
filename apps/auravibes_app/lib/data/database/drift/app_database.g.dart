// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, WorkspacesTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WorkspaceType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WorkspaceType>($WorkspacesTable.$convertertype);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    type,
    url,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspacesTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  WorkspacesTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspacesTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $WorkspacesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WorkspaceType, String, String> $convertertype =
      const EnumNameConverter<WorkspaceType>(WorkspaceType.values);
}

class WorkspacesTable extends DataClass implements Insertable<WorkspacesTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// Human-readable name of the workspace
  final String name;

  /// Type of workspace (local or remote)
  /// Stored as string to handle enum conversion
  final WorkspaceType type;

  /// URL for remote workspaces, null for local workspaces
  final String? url;
  const WorkspacesTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.type,
    this.url,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $WorkspacesTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      type: Value(type),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
    );
  }

  factory WorkspacesTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspacesTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      type: $WorkspacesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      url: serializer.fromJson<String?>(json['url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $WorkspacesTable.$convertertype.toJson(type),
      ),
      'url': serializer.toJson<String?>(url),
    };
  }

  WorkspacesTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    WorkspaceType? type,
    Value<String?> url = const Value.absent(),
  }) => WorkspacesTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    type: type ?? this.type,
    url: url.present ? url.value : this.url,
  );
  WorkspacesTable copyWithCompanion(WorkspacesCompanion data) {
    return WorkspacesTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, name, type, url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspacesTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.type == this.type &&
          other.url == this.url);
}

class WorkspacesCompanion extends UpdateCompanion<WorkspacesTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<WorkspaceType> type;
  final Value<String?> url;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.url = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    required WorkspaceType type,
    this.url = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<WorkspacesTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? url,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<WorkspaceType>? type,
    Value<String?>? url,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $WorkspacesTable.$convertertype.toSql(type.value),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServiceConnectionsTable extends ServiceConnections
    with TableInfo<$ServiceConnectionsTable, ServiceConnectionTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
    'service_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    ServiceConnectionKindTable,
    String
  >
  kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ServiceConnectionKindTable>(
        $ServiceConnectionsTable.$converterkind,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    ServiceAuthenticationTypeTable,
    String
  >
  authenticationType =
      GeneratedColumn<String>(
        'authentication_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ServiceAuthenticationTypeTable>(
        $ServiceConnectionsTable.$converterauthenticationType,
      );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _encryptedAuthValueMeta =
      const VerificationMeta('encryptedAuthValue');
  @override
  late final GeneratedColumn<String> encryptedAuthValue =
      GeneratedColumn<String>(
        'encrypted_auth_value',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keySuffixMeta = const VerificationMeta(
    'keySuffix',
  );
  @override
  late final GeneratedColumn<String> keySuffix = GeneratedColumn<String>(
    'key_suffix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    serviceId,
    kind,
    authenticationType,
    url,
    encryptedAuthValue,
    keySuffix,
    metadataJson,
    workspaceId,
    isEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceConnectionTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('encrypted_auth_value')) {
      context.handle(
        _encryptedAuthValueMeta,
        encryptedAuthValue.isAcceptableOrUnknown(
          data['encrypted_auth_value']!,
          _encryptedAuthValueMeta,
        ),
      );
    }
    if (data.containsKey('key_suffix')) {
      context.handle(
        _keySuffixMeta,
        keySuffix.isAcceptableOrUnknown(data['key_suffix']!, _keySuffixMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ServiceConnectionTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceConnectionTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_id'],
      )!,
      kind: $ServiceConnectionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      authenticationType: $ServiceConnectionsTable.$converterauthenticationType
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}authentication_type'],
            )!,
          ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      encryptedAuthValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_auth_value'],
      ),
      keySuffix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_suffix'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
    );
  }

  @override
  $ServiceConnectionsTable createAlias(String alias) {
    return $ServiceConnectionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ServiceConnectionKindTable, String, String>
  $converterkind = const EnumNameConverter<ServiceConnectionKindTable>(
    ServiceConnectionKindTable.values,
  );
  static JsonTypeConverter2<ServiceAuthenticationTypeTable, String, String>
  $converterauthenticationType =
      const EnumNameConverter<ServiceAuthenticationTypeTable>(
        ServiceAuthenticationTypeTable.values,
      );
}

class ServiceConnectionTable extends DataClass
    implements Insertable<ServiceConnectionTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// Human-readable name of the external service connection.
  final String name;

  /// Service-specific ID, such as openai, anthropic, gmail, or custom slug.
  final String serviceId;
  final ServiceConnectionKindTable kind;
  final ServiceAuthenticationTypeTable authenticationType;

  /// Base URL for services that support custom endpoints.
  final String? url;

  /// Encrypted auth payload. Shape depends on [authenticationType].
  final String? encryptedAuthValue;

  /// Last visible secret characters, stored in plain text for display only.
  final String? keySuffix;

  /// Non-secret service-specific JSON config.
  final String? metadataJson;
  final String workspaceId;
  final bool isEnabled;
  const ServiceConnectionTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.serviceId,
    required this.kind,
    required this.authenticationType,
    this.url,
    this.encryptedAuthValue,
    this.keySuffix,
    this.metadataJson,
    required this.workspaceId,
    required this.isEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['service_id'] = Variable<String>(serviceId);
    {
      map['kind'] = Variable<String>(
        $ServiceConnectionsTable.$converterkind.toSql(kind),
      );
    }
    {
      map['authentication_type'] = Variable<String>(
        $ServiceConnectionsTable.$converterauthenticationType.toSql(
          authenticationType,
        ),
      );
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || encryptedAuthValue != null) {
      map['encrypted_auth_value'] = Variable<String>(encryptedAuthValue);
    }
    if (!nullToAbsent || keySuffix != null) {
      map['key_suffix'] = Variable<String>(keySuffix);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    map['workspace_id'] = Variable<String>(workspaceId);
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  ServiceConnectionsCompanion toCompanion(bool nullToAbsent) {
    return ServiceConnectionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      serviceId: Value(serviceId),
      kind: Value(kind),
      authenticationType: Value(authenticationType),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      encryptedAuthValue: encryptedAuthValue == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptedAuthValue),
      keySuffix: keySuffix == null && nullToAbsent
          ? const Value.absent()
          : Value(keySuffix),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      workspaceId: Value(workspaceId),
      isEnabled: Value(isEnabled),
    );
  }

  factory ServiceConnectionTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceConnectionTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      kind: $ServiceConnectionsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      authenticationType: $ServiceConnectionsTable.$converterauthenticationType
          .fromJson(serializer.fromJson<String>(json['authenticationType'])),
      url: serializer.fromJson<String?>(json['url']),
      encryptedAuthValue: serializer.fromJson<String?>(
        json['encryptedAuthValue'],
      ),
      keySuffix: serializer.fromJson<String?>(json['keySuffix']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'serviceId': serializer.toJson<String>(serviceId),
      'kind': serializer.toJson<String>(
        $ServiceConnectionsTable.$converterkind.toJson(kind),
      ),
      'authenticationType': serializer.toJson<String>(
        $ServiceConnectionsTable.$converterauthenticationType.toJson(
          authenticationType,
        ),
      ),
      'url': serializer.toJson<String?>(url),
      'encryptedAuthValue': serializer.toJson<String?>(encryptedAuthValue),
      'keySuffix': serializer.toJson<String?>(keySuffix),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  ServiceConnectionTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? serviceId,
    ServiceConnectionKindTable? kind,
    ServiceAuthenticationTypeTable? authenticationType,
    Value<String?> url = const Value.absent(),
    Value<String?> encryptedAuthValue = const Value.absent(),
    Value<String?> keySuffix = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
    String? workspaceId,
    bool? isEnabled,
  }) => ServiceConnectionTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    serviceId: serviceId ?? this.serviceId,
    kind: kind ?? this.kind,
    authenticationType: authenticationType ?? this.authenticationType,
    url: url.present ? url.value : this.url,
    encryptedAuthValue: encryptedAuthValue.present
        ? encryptedAuthValue.value
        : this.encryptedAuthValue,
    keySuffix: keySuffix.present ? keySuffix.value : this.keySuffix,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    workspaceId: workspaceId ?? this.workspaceId,
    isEnabled: isEnabled ?? this.isEnabled,
  );
  ServiceConnectionTable copyWithCompanion(ServiceConnectionsCompanion data) {
    return ServiceConnectionTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      authenticationType: data.authenticationType.present
          ? data.authenticationType.value
          : this.authenticationType,
      url: data.url.present ? data.url.value : this.url,
      encryptedAuthValue: data.encryptedAuthValue.present
          ? data.encryptedAuthValue.value
          : this.encryptedAuthValue,
      keySuffix: data.keySuffix.present ? data.keySuffix.value : this.keySuffix,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceConnectionTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('serviceId: $serviceId, ')
          ..write('kind: $kind, ')
          ..write('authenticationType: $authenticationType, ')
          ..write('url: $url, ')
          ..write('encryptedAuthValue: $encryptedAuthValue, ')
          ..write('keySuffix: $keySuffix, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    serviceId,
    kind,
    authenticationType,
    url,
    encryptedAuthValue,
    keySuffix,
    metadataJson,
    workspaceId,
    isEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceConnectionTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.serviceId == this.serviceId &&
          other.kind == this.kind &&
          other.authenticationType == this.authenticationType &&
          other.url == this.url &&
          other.encryptedAuthValue == this.encryptedAuthValue &&
          other.keySuffix == this.keySuffix &&
          other.metadataJson == this.metadataJson &&
          other.workspaceId == this.workspaceId &&
          other.isEnabled == this.isEnabled);
}

class ServiceConnectionsCompanion
    extends UpdateCompanion<ServiceConnectionTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String> serviceId;
  final Value<ServiceConnectionKindTable> kind;
  final Value<ServiceAuthenticationTypeTable> authenticationType;
  final Value<String?> url;
  final Value<String?> encryptedAuthValue;
  final Value<String?> keySuffix;
  final Value<String?> metadataJson;
  final Value<String> workspaceId;
  final Value<bool> isEnabled;
  final Value<int> rowid;
  const ServiceConnectionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.authenticationType = const Value.absent(),
    this.url = const Value.absent(),
    this.encryptedAuthValue = const Value.absent(),
    this.keySuffix = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServiceConnectionsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    required String serviceId,
    required ServiceConnectionKindTable kind,
    required ServiceAuthenticationTypeTable authenticationType,
    this.url = const Value.absent(),
    this.encryptedAuthValue = const Value.absent(),
    this.keySuffix = const Value.absent(),
    this.metadataJson = const Value.absent(),
    required String workspaceId,
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       serviceId = Value(serviceId),
       kind = Value(kind),
       authenticationType = Value(authenticationType),
       workspaceId = Value(workspaceId);
  static Insertable<ServiceConnectionTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? serviceId,
    Expression<String>? kind,
    Expression<String>? authenticationType,
    Expression<String>? url,
    Expression<String>? encryptedAuthValue,
    Expression<String>? keySuffix,
    Expression<String>? metadataJson,
    Expression<String>? workspaceId,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (serviceId != null) 'service_id': serviceId,
      if (kind != null) 'kind': kind,
      if (authenticationType != null) 'authentication_type': authenticationType,
      if (url != null) 'url': url,
      if (encryptedAuthValue != null)
        'encrypted_auth_value': encryptedAuthValue,
      if (keySuffix != null) 'key_suffix': keySuffix,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServiceConnectionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String>? serviceId,
    Value<ServiceConnectionKindTable>? kind,
    Value<ServiceAuthenticationTypeTable>? authenticationType,
    Value<String?>? url,
    Value<String?>? encryptedAuthValue,
    Value<String?>? keySuffix,
    Value<String?>? metadataJson,
    Value<String>? workspaceId,
    Value<bool>? isEnabled,
    Value<int>? rowid,
  }) {
    return ServiceConnectionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      serviceId: serviceId ?? this.serviceId,
      kind: kind ?? this.kind,
      authenticationType: authenticationType ?? this.authenticationType,
      url: url ?? this.url,
      encryptedAuthValue: encryptedAuthValue ?? this.encryptedAuthValue,
      keySuffix: keySuffix ?? this.keySuffix,
      metadataJson: metadataJson ?? this.metadataJson,
      workspaceId: workspaceId ?? this.workspaceId,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ServiceConnectionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (authenticationType.present) {
      map['authentication_type'] = Variable<String>(
        $ServiceConnectionsTable.$converterauthenticationType.toSql(
          authenticationType.value,
        ),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (encryptedAuthValue.present) {
      map['encrypted_auth_value'] = Variable<String>(encryptedAuthValue.value);
    }
    if (keySuffix.present) {
      map['key_suffix'] = Variable<String>(keySuffix.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('serviceId: $serviceId, ')
          ..write('kind: $kind, ')
          ..write('authenticationType: $authenticationType, ')
          ..write('url: $url, ')
          ..write('encryptedAuthValue: $encryptedAuthValue, ')
          ..write('keySuffix: $keySuffix, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiModelProvidersTable extends ApiModelProviders
    with TableInfo<$ApiModelProvidersTable, ApiModelProvidersTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiModelProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ModelProvidersTableType?, String>
  type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ModelProvidersTableType?>(
        $ApiModelProvidersTable.$convertertypen,
      );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _docMeta = const VerificationMeta('doc');
  @override
  late final GeneratedColumn<String> doc = GeneratedColumn<String>(
    'doc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type, url, doc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_model_providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiModelProvidersTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('doc')) {
      context.handle(
        _docMeta,
        doc.isAcceptableOrUnknown(data['doc']!, _docMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiModelProvidersTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiModelProvidersTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $ApiModelProvidersTable.$convertertypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        ),
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      doc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc'],
      ),
    );
  }

  @override
  $ApiModelProvidersTable createAlias(String alias) {
    return $ApiModelProvidersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ModelProvidersTableType, String, String>
  $convertertype = const EnumNameConverter<ModelProvidersTableType>(
    ModelProvidersTableType.values,
  );
  static JsonTypeConverter2<ModelProvidersTableType?, String?, String?>
  $convertertypen = JsonTypeConverter2.asNullable($convertertype);
}

class ApiModelProvidersTable extends DataClass
    implements Insertable<ApiModelProvidersTable> {
  final String id;

  /// Human-readable name of the model
  final String name;

  /// Type of chat model (local or remote)
  /// Stored as string to handle enum conversion
  final ModelProvidersTableType? type;
  final String? url;
  final String? doc;
  const ApiModelProvidersTable({
    required this.id,
    required this.name,
    this.type,
    this.url,
    this.doc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(
        $ApiModelProvidersTable.$convertertypen.toSql(type),
      );
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || doc != null) {
      map['doc'] = Variable<String>(doc);
    }
    return map;
  }

  ApiModelProvidersCompanion toCompanion(bool nullToAbsent) {
    return ApiModelProvidersCompanion(
      id: Value(id),
      name: Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      doc: doc == null && nullToAbsent ? const Value.absent() : Value(doc),
    );
  }

  factory ApiModelProvidersTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiModelProvidersTable(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $ApiModelProvidersTable.$convertertypen.fromJson(
        serializer.fromJson<String?>(json['type']),
      ),
      url: serializer.fromJson<String?>(json['url']),
      doc: serializer.fromJson<String?>(json['doc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String?>(
        $ApiModelProvidersTable.$convertertypen.toJson(type),
      ),
      'url': serializer.toJson<String?>(url),
      'doc': serializer.toJson<String?>(doc),
    };
  }

  ApiModelProvidersTable copyWith({
    String? id,
    String? name,
    Value<ModelProvidersTableType?> type = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> doc = const Value.absent(),
  }) => ApiModelProvidersTable(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type.present ? type.value : this.type,
    url: url.present ? url.value : this.url,
    doc: doc.present ? doc.value : this.doc,
  );
  ApiModelProvidersTable copyWithCompanion(ApiModelProvidersCompanion data) {
    return ApiModelProvidersTable(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      url: data.url.present ? data.url.value : this.url,
      doc: data.doc.present ? data.doc.value : this.doc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiModelProvidersTable(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('doc: $doc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, url, doc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiModelProvidersTable &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.url == this.url &&
          other.doc == this.doc);
}

class ApiModelProvidersCompanion
    extends UpdateCompanion<ApiModelProvidersTable> {
  final Value<String> id;
  final Value<String> name;
  final Value<ModelProvidersTableType?> type;
  final Value<String?> url;
  final Value<String?> doc;
  final Value<int> rowid;
  const ApiModelProvidersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.url = const Value.absent(),
    this.doc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiModelProvidersCompanion.insert({
    required String id,
    required String name,
    this.type = const Value.absent(),
    this.url = const Value.absent(),
    this.doc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ApiModelProvidersTable> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? url,
    Expression<String>? doc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (doc != null) 'doc': doc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiModelProvidersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<ModelProvidersTableType?>? type,
    Value<String?>? url,
    Value<String?>? doc,
    Value<int>? rowid,
  }) {
    return ApiModelProvidersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      doc: doc ?? this.doc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ApiModelProvidersTable.$convertertypen.toSql(type.value),
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (doc.present) {
      map['doc'] = Variable<String>(doc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiModelProvidersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('doc: $doc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspaceModelSelectionsTable extends WorkspaceModelSelections
    with
        TableInfo<
          $WorkspaceModelSelectionsTable,
          WorkspaceModelSelectionTable
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspaceModelSelectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES api_model_providers (id)',
    ),
  );
  static const VerificationMeta _modelConnectionIdMeta = const VerificationMeta(
    'modelConnectionId',
  );
  @override
  late final GeneratedColumn<String> modelConnectionId =
      GeneratedColumn<String>(
        'model_connection_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES service_connections (id) ON DELETE CASCADE',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    modelId,
    modelConnectionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_model_selections';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceModelSelectionTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('model_connection_id')) {
      context.handle(
        _modelConnectionIdMeta,
        modelConnectionId.isAcceptableOrUnknown(
          data['model_connection_id']!,
          _modelConnectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelConnectionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  WorkspaceModelSelectionTable map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceModelSelectionTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      modelConnectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_connection_id'],
      )!,
    );
  }

  @override
  $WorkspaceModelSelectionsTable createAlias(String alias) {
    return $WorkspaceModelSelectionsTable(attachedDatabase, alias);
  }
}

class WorkspaceModelSelectionTable extends DataClass
    implements Insertable<WorkspaceModelSelectionTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// model unique identifier
  final String modelId;
  final String modelConnectionId;
  const WorkspaceModelSelectionTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.modelId,
    required this.modelConnectionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['model_id'] = Variable<String>(modelId);
    map['model_connection_id'] = Variable<String>(modelConnectionId);
    return map;
  }

  WorkspaceModelSelectionsCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceModelSelectionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      modelId: Value(modelId),
      modelConnectionId: Value(modelConnectionId),
    );
  }

  factory WorkspaceModelSelectionTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceModelSelectionTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      modelId: serializer.fromJson<String>(json['modelId']),
      modelConnectionId: serializer.fromJson<String>(json['modelConnectionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'modelId': serializer.toJson<String>(modelId),
      'modelConnectionId': serializer.toJson<String>(modelConnectionId),
    };
  }

  WorkspaceModelSelectionTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? modelId,
    String? modelConnectionId,
  }) => WorkspaceModelSelectionTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    modelId: modelId ?? this.modelId,
    modelConnectionId: modelConnectionId ?? this.modelConnectionId,
  );
  WorkspaceModelSelectionTable copyWithCompanion(
    WorkspaceModelSelectionsCompanion data,
  ) {
    return WorkspaceModelSelectionTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      modelConnectionId: data.modelConnectionId.present
          ? data.modelConnectionId.value
          : this.modelConnectionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceModelSelectionTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('modelId: $modelId, ')
          ..write('modelConnectionId: $modelConnectionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, modelId, modelConnectionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceModelSelectionTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.modelId == this.modelId &&
          other.modelConnectionId == this.modelConnectionId);
}

class WorkspaceModelSelectionsCompanion
    extends UpdateCompanion<WorkspaceModelSelectionTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> modelId;
  final Value<String> modelConnectionId;
  final Value<int> rowid;
  const WorkspaceModelSelectionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modelConnectionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceModelSelectionsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String modelId,
    required String modelConnectionId,
    this.rowid = const Value.absent(),
  }) : modelId = Value(modelId),
       modelConnectionId = Value(modelConnectionId);
  static Insertable<WorkspaceModelSelectionTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? modelId,
    Expression<String>? modelConnectionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (modelId != null) 'model_id': modelId,
      if (modelConnectionId != null) 'model_connection_id': modelConnectionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceModelSelectionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? modelId,
    Value<String>? modelConnectionId,
    Value<int>? rowid,
  }) {
    return WorkspaceModelSelectionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modelId: modelId ?? this.modelId,
      modelConnectionId: modelConnectionId ?? this.modelConnectionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (modelConnectionId.present) {
      map['model_connection_id'] = Variable<String>(modelConnectionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceModelSelectionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('modelId: $modelId, ')
          ..write('modelConnectionId: $modelConnectionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiModelsTable extends ApiModels
    with TableInfo<$ApiModelsTable, ApiModelsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _modelProviderMeta = const VerificationMeta(
    'modelProvider',
  );
  @override
  late final GeneratedColumn<String> modelProvider = GeneratedColumn<String>(
    'model_provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES api_model_providers (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
  modalitiesInput = GeneratedColumn<String>(
    'modalities_input',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<String>?>($ApiModelsTable.$convertermodalitiesInputn);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
  modalitiesOuput = GeneratedColumn<String>(
    'modalities_ouput',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<String>?>($ApiModelsTable.$convertermodalitiesOuputn);
  static const VerificationMeta _openWeightsMeta = const VerificationMeta(
    'openWeights',
  );
  @override
  late final GeneratedColumn<bool> openWeights = GeneratedColumn<bool>(
    'open_weights',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("open_weights" IN (0, 1))',
    ),
  );
  static const VerificationMeta _supportsReasoningMeta = const VerificationMeta(
    'supportsReasoning',
  );
  @override
  late final GeneratedColumn<bool> supportsReasoning = GeneratedColumn<bool>(
    'supports_reasoning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("supports_reasoning" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _costInputMeta = const VerificationMeta(
    'costInput',
  );
  @override
  late final GeneratedColumn<double> costInput = GeneratedColumn<double>(
    'cost_input',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costOutputMeta = const VerificationMeta(
    'costOutput',
  );
  @override
  late final GeneratedColumn<double> costOutput = GeneratedColumn<double>(
    'cost_output',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costCacheReadMeta = const VerificationMeta(
    'costCacheRead',
  );
  @override
  late final GeneratedColumn<double> costCacheRead = GeneratedColumn<double>(
    'cost_cache_read',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitContextMeta = const VerificationMeta(
    'limitContext',
  );
  @override
  late final GeneratedColumn<int> limitContext = GeneratedColumn<int>(
    'limit_context',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitOutputMeta = const VerificationMeta(
    'limitOutput',
  );
  @override
  late final GeneratedColumn<int> limitOutput = GeneratedColumn<int>(
    'limit_output',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    modelProvider,
    id,
    name,
    modalitiesInput,
    modalitiesOuput,
    openWeights,
    supportsReasoning,
    costInput,
    costOutput,
    costCacheRead,
    limitContext,
    limitOutput,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiModelsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('model_provider')) {
      context.handle(
        _modelProviderMeta,
        modelProvider.isAcceptableOrUnknown(
          data['model_provider']!,
          _modelProviderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelProviderMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('open_weights')) {
      context.handle(
        _openWeightsMeta,
        openWeights.isAcceptableOrUnknown(
          data['open_weights']!,
          _openWeightsMeta,
        ),
      );
    }
    if (data.containsKey('supports_reasoning')) {
      context.handle(
        _supportsReasoningMeta,
        supportsReasoning.isAcceptableOrUnknown(
          data['supports_reasoning']!,
          _supportsReasoningMeta,
        ),
      );
    }
    if (data.containsKey('cost_input')) {
      context.handle(
        _costInputMeta,
        costInput.isAcceptableOrUnknown(data['cost_input']!, _costInputMeta),
      );
    }
    if (data.containsKey('cost_output')) {
      context.handle(
        _costOutputMeta,
        costOutput.isAcceptableOrUnknown(data['cost_output']!, _costOutputMeta),
      );
    }
    if (data.containsKey('cost_cache_read')) {
      context.handle(
        _costCacheReadMeta,
        costCacheRead.isAcceptableOrUnknown(
          data['cost_cache_read']!,
          _costCacheReadMeta,
        ),
      );
    }
    if (data.containsKey('limit_context')) {
      context.handle(
        _limitContextMeta,
        limitContext.isAcceptableOrUnknown(
          data['limit_context']!,
          _limitContextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitContextMeta);
    }
    if (data.containsKey('limit_output')) {
      context.handle(
        _limitOutputMeta,
        limitOutput.isAcceptableOrUnknown(
          data['limit_output']!,
          _limitOutputMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitOutputMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, modelProvider};
  @override
  ApiModelsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiModelsTable(
      modelProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_provider'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      modalitiesInput: $ApiModelsTable.$convertermodalitiesInputn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}modalities_input'],
        ),
      ),
      modalitiesOuput: $ApiModelsTable.$convertermodalitiesOuputn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}modalities_ouput'],
        ),
      ),
      openWeights: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}open_weights'],
      ),
      supportsReasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}supports_reasoning'],
      )!,
      costInput: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_input'],
      ),
      costOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_output'],
      ),
      costCacheRead: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_cache_read'],
      ),
      limitContext: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_context'],
      )!,
      limitOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_output'],
      )!,
    );
  }

  @override
  $ApiModelsTable createAlias(String alias) {
    return $ApiModelsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<List<String>, String, Object?>
  $convertermodalitiesInput = stringListConverter;
  static JsonTypeConverter2<List<String>?, String?, Object?>
  $convertermodalitiesInputn = JsonTypeConverter2.asNullable(
    $convertermodalitiesInput,
  );
  static JsonTypeConverter2<List<String>, String, Object?>
  $convertermodalitiesOuput = stringListConverter;
  static JsonTypeConverter2<List<String>?, String?, Object?>
  $convertermodalitiesOuputn = JsonTypeConverter2.asNullable(
    $convertermodalitiesOuput,
  );
}

class ApiModelsTable extends DataClass implements Insertable<ApiModelsTable> {
  final String modelProvider;
  final String id;

  /// Human-readable name of the model
  final String name;

  /// Type of chat model (local or remote)
  /// Stored as string to handle enum conversion
  final List<String>? modalitiesInput;
  final List<String>? modalitiesOuput;
  final bool? openWeights;
  final bool supportsReasoning;
  final double? costInput;
  final double? costOutput;
  final double? costCacheRead;
  final int limitContext;
  final int limitOutput;
  const ApiModelsTable({
    required this.modelProvider,
    required this.id,
    required this.name,
    this.modalitiesInput,
    this.modalitiesOuput,
    this.openWeights,
    required this.supportsReasoning,
    this.costInput,
    this.costOutput,
    this.costCacheRead,
    required this.limitContext,
    required this.limitOutput,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['model_provider'] = Variable<String>(modelProvider);
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || modalitiesInput != null) {
      map['modalities_input'] = Variable<String>(
        $ApiModelsTable.$convertermodalitiesInputn.toSql(modalitiesInput),
      );
    }
    if (!nullToAbsent || modalitiesOuput != null) {
      map['modalities_ouput'] = Variable<String>(
        $ApiModelsTable.$convertermodalitiesOuputn.toSql(modalitiesOuput),
      );
    }
    if (!nullToAbsent || openWeights != null) {
      map['open_weights'] = Variable<bool>(openWeights);
    }
    map['supports_reasoning'] = Variable<bool>(supportsReasoning);
    if (!nullToAbsent || costInput != null) {
      map['cost_input'] = Variable<double>(costInput);
    }
    if (!nullToAbsent || costOutput != null) {
      map['cost_output'] = Variable<double>(costOutput);
    }
    if (!nullToAbsent || costCacheRead != null) {
      map['cost_cache_read'] = Variable<double>(costCacheRead);
    }
    map['limit_context'] = Variable<int>(limitContext);
    map['limit_output'] = Variable<int>(limitOutput);
    return map;
  }

  ApiModelsCompanion toCompanion(bool nullToAbsent) {
    return ApiModelsCompanion(
      modelProvider: Value(modelProvider),
      id: Value(id),
      name: Value(name),
      modalitiesInput: modalitiesInput == null && nullToAbsent
          ? const Value.absent()
          : Value(modalitiesInput),
      modalitiesOuput: modalitiesOuput == null && nullToAbsent
          ? const Value.absent()
          : Value(modalitiesOuput),
      openWeights: openWeights == null && nullToAbsent
          ? const Value.absent()
          : Value(openWeights),
      supportsReasoning: Value(supportsReasoning),
      costInput: costInput == null && nullToAbsent
          ? const Value.absent()
          : Value(costInput),
      costOutput: costOutput == null && nullToAbsent
          ? const Value.absent()
          : Value(costOutput),
      costCacheRead: costCacheRead == null && nullToAbsent
          ? const Value.absent()
          : Value(costCacheRead),
      limitContext: Value(limitContext),
      limitOutput: Value(limitOutput),
    );
  }

  factory ApiModelsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiModelsTable(
      modelProvider: serializer.fromJson<String>(json['modelProvider']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      modalitiesInput: $ApiModelsTable.$convertermodalitiesInputn.fromJson(
        serializer.fromJson<Object?>(json['modalitiesInput']),
      ),
      modalitiesOuput: $ApiModelsTable.$convertermodalitiesOuputn.fromJson(
        serializer.fromJson<Object?>(json['modalitiesOuput']),
      ),
      openWeights: serializer.fromJson<bool?>(json['openWeights']),
      supportsReasoning: serializer.fromJson<bool>(json['supportsReasoning']),
      costInput: serializer.fromJson<double?>(json['costInput']),
      costOutput: serializer.fromJson<double?>(json['costOutput']),
      costCacheRead: serializer.fromJson<double?>(json['costCacheRead']),
      limitContext: serializer.fromJson<int>(json['limitContext']),
      limitOutput: serializer.fromJson<int>(json['limitOutput']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modelProvider': serializer.toJson<String>(modelProvider),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'modalitiesInput': serializer.toJson<Object?>(
        $ApiModelsTable.$convertermodalitiesInputn.toJson(modalitiesInput),
      ),
      'modalitiesOuput': serializer.toJson<Object?>(
        $ApiModelsTable.$convertermodalitiesOuputn.toJson(modalitiesOuput),
      ),
      'openWeights': serializer.toJson<bool?>(openWeights),
      'supportsReasoning': serializer.toJson<bool>(supportsReasoning),
      'costInput': serializer.toJson<double?>(costInput),
      'costOutput': serializer.toJson<double?>(costOutput),
      'costCacheRead': serializer.toJson<double?>(costCacheRead),
      'limitContext': serializer.toJson<int>(limitContext),
      'limitOutput': serializer.toJson<int>(limitOutput),
    };
  }

  ApiModelsTable copyWith({
    String? modelProvider,
    String? id,
    String? name,
    Value<List<String>?> modalitiesInput = const Value.absent(),
    Value<List<String>?> modalitiesOuput = const Value.absent(),
    Value<bool?> openWeights = const Value.absent(),
    bool? supportsReasoning,
    Value<double?> costInput = const Value.absent(),
    Value<double?> costOutput = const Value.absent(),
    Value<double?> costCacheRead = const Value.absent(),
    int? limitContext,
    int? limitOutput,
  }) => ApiModelsTable(
    modelProvider: modelProvider ?? this.modelProvider,
    id: id ?? this.id,
    name: name ?? this.name,
    modalitiesInput: modalitiesInput.present
        ? modalitiesInput.value
        : this.modalitiesInput,
    modalitiesOuput: modalitiesOuput.present
        ? modalitiesOuput.value
        : this.modalitiesOuput,
    openWeights: openWeights.present ? openWeights.value : this.openWeights,
    supportsReasoning: supportsReasoning ?? this.supportsReasoning,
    costInput: costInput.present ? costInput.value : this.costInput,
    costOutput: costOutput.present ? costOutput.value : this.costOutput,
    costCacheRead: costCacheRead.present
        ? costCacheRead.value
        : this.costCacheRead,
    limitContext: limitContext ?? this.limitContext,
    limitOutput: limitOutput ?? this.limitOutput,
  );
  ApiModelsTable copyWithCompanion(ApiModelsCompanion data) {
    return ApiModelsTable(
      modelProvider: data.modelProvider.present
          ? data.modelProvider.value
          : this.modelProvider,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      modalitiesInput: data.modalitiesInput.present
          ? data.modalitiesInput.value
          : this.modalitiesInput,
      modalitiesOuput: data.modalitiesOuput.present
          ? data.modalitiesOuput.value
          : this.modalitiesOuput,
      openWeights: data.openWeights.present
          ? data.openWeights.value
          : this.openWeights,
      supportsReasoning: data.supportsReasoning.present
          ? data.supportsReasoning.value
          : this.supportsReasoning,
      costInput: data.costInput.present ? data.costInput.value : this.costInput,
      costOutput: data.costOutput.present
          ? data.costOutput.value
          : this.costOutput,
      costCacheRead: data.costCacheRead.present
          ? data.costCacheRead.value
          : this.costCacheRead,
      limitContext: data.limitContext.present
          ? data.limitContext.value
          : this.limitContext,
      limitOutput: data.limitOutput.present
          ? data.limitOutput.value
          : this.limitOutput,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiModelsTable(')
          ..write('modelProvider: $modelProvider, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('modalitiesInput: $modalitiesInput, ')
          ..write('modalitiesOuput: $modalitiesOuput, ')
          ..write('openWeights: $openWeights, ')
          ..write('supportsReasoning: $supportsReasoning, ')
          ..write('costInput: $costInput, ')
          ..write('costOutput: $costOutput, ')
          ..write('costCacheRead: $costCacheRead, ')
          ..write('limitContext: $limitContext, ')
          ..write('limitOutput: $limitOutput')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    modelProvider,
    id,
    name,
    modalitiesInput,
    modalitiesOuput,
    openWeights,
    supportsReasoning,
    costInput,
    costOutput,
    costCacheRead,
    limitContext,
    limitOutput,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiModelsTable &&
          other.modelProvider == this.modelProvider &&
          other.id == this.id &&
          other.name == this.name &&
          other.modalitiesInput == this.modalitiesInput &&
          other.modalitiesOuput == this.modalitiesOuput &&
          other.openWeights == this.openWeights &&
          other.supportsReasoning == this.supportsReasoning &&
          other.costInput == this.costInput &&
          other.costOutput == this.costOutput &&
          other.costCacheRead == this.costCacheRead &&
          other.limitContext == this.limitContext &&
          other.limitOutput == this.limitOutput);
}

class ApiModelsCompanion extends UpdateCompanion<ApiModelsTable> {
  final Value<String> modelProvider;
  final Value<String> id;
  final Value<String> name;
  final Value<List<String>?> modalitiesInput;
  final Value<List<String>?> modalitiesOuput;
  final Value<bool?> openWeights;
  final Value<bool> supportsReasoning;
  final Value<double?> costInput;
  final Value<double?> costOutput;
  final Value<double?> costCacheRead;
  final Value<int> limitContext;
  final Value<int> limitOutput;
  final Value<int> rowid;
  const ApiModelsCompanion({
    this.modelProvider = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.modalitiesInput = const Value.absent(),
    this.modalitiesOuput = const Value.absent(),
    this.openWeights = const Value.absent(),
    this.supportsReasoning = const Value.absent(),
    this.costInput = const Value.absent(),
    this.costOutput = const Value.absent(),
    this.costCacheRead = const Value.absent(),
    this.limitContext = const Value.absent(),
    this.limitOutput = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiModelsCompanion.insert({
    required String modelProvider,
    required String id,
    required String name,
    this.modalitiesInput = const Value.absent(),
    this.modalitiesOuput = const Value.absent(),
    this.openWeights = const Value.absent(),
    this.supportsReasoning = const Value.absent(),
    this.costInput = const Value.absent(),
    this.costOutput = const Value.absent(),
    this.costCacheRead = const Value.absent(),
    required int limitContext,
    required int limitOutput,
    this.rowid = const Value.absent(),
  }) : modelProvider = Value(modelProvider),
       id = Value(id),
       name = Value(name),
       limitContext = Value(limitContext),
       limitOutput = Value(limitOutput);
  static Insertable<ApiModelsTable> custom({
    Expression<String>? modelProvider,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? modalitiesInput,
    Expression<String>? modalitiesOuput,
    Expression<bool>? openWeights,
    Expression<bool>? supportsReasoning,
    Expression<double>? costInput,
    Expression<double>? costOutput,
    Expression<double>? costCacheRead,
    Expression<int>? limitContext,
    Expression<int>? limitOutput,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modelProvider != null) 'model_provider': modelProvider,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (modalitiesInput != null) 'modalities_input': modalitiesInput,
      if (modalitiesOuput != null) 'modalities_ouput': modalitiesOuput,
      if (openWeights != null) 'open_weights': openWeights,
      if (supportsReasoning != null) 'supports_reasoning': supportsReasoning,
      if (costInput != null) 'cost_input': costInput,
      if (costOutput != null) 'cost_output': costOutput,
      if (costCacheRead != null) 'cost_cache_read': costCacheRead,
      if (limitContext != null) 'limit_context': limitContext,
      if (limitOutput != null) 'limit_output': limitOutput,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiModelsCompanion copyWith({
    Value<String>? modelProvider,
    Value<String>? id,
    Value<String>? name,
    Value<List<String>?>? modalitiesInput,
    Value<List<String>?>? modalitiesOuput,
    Value<bool?>? openWeights,
    Value<bool>? supportsReasoning,
    Value<double?>? costInput,
    Value<double?>? costOutput,
    Value<double?>? costCacheRead,
    Value<int>? limitContext,
    Value<int>? limitOutput,
    Value<int>? rowid,
  }) {
    return ApiModelsCompanion(
      modelProvider: modelProvider ?? this.modelProvider,
      id: id ?? this.id,
      name: name ?? this.name,
      modalitiesInput: modalitiesInput ?? this.modalitiesInput,
      modalitiesOuput: modalitiesOuput ?? this.modalitiesOuput,
      openWeights: openWeights ?? this.openWeights,
      supportsReasoning: supportsReasoning ?? this.supportsReasoning,
      costInput: costInput ?? this.costInput,
      costOutput: costOutput ?? this.costOutput,
      costCacheRead: costCacheRead ?? this.costCacheRead,
      limitContext: limitContext ?? this.limitContext,
      limitOutput: limitOutput ?? this.limitOutput,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modelProvider.present) {
      map['model_provider'] = Variable<String>(modelProvider.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (modalitiesInput.present) {
      map['modalities_input'] = Variable<String>(
        $ApiModelsTable.$convertermodalitiesInputn.toSql(modalitiesInput.value),
      );
    }
    if (modalitiesOuput.present) {
      map['modalities_ouput'] = Variable<String>(
        $ApiModelsTable.$convertermodalitiesOuputn.toSql(modalitiesOuput.value),
      );
    }
    if (openWeights.present) {
      map['open_weights'] = Variable<bool>(openWeights.value);
    }
    if (supportsReasoning.present) {
      map['supports_reasoning'] = Variable<bool>(supportsReasoning.value);
    }
    if (costInput.present) {
      map['cost_input'] = Variable<double>(costInput.value);
    }
    if (costOutput.present) {
      map['cost_output'] = Variable<double>(costOutput.value);
    }
    if (costCacheRead.present) {
      map['cost_cache_read'] = Variable<double>(costCacheRead.value);
    }
    if (limitContext.present) {
      map['limit_context'] = Variable<int>(limitContext.value);
    }
    if (limitOutput.present) {
      map['limit_output'] = Variable<int>(limitOutput.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiModelsCompanion(')
          ..write('modelProvider: $modelProvider, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('modalitiesInput: $modalitiesInput, ')
          ..write('modalitiesOuput: $modalitiesOuput, ')
          ..write('openWeights: $openWeights, ')
          ..write('supportsReasoning: $supportsReasoning, ')
          ..write('costInput: $costInput, ')
          ..write('costOutput: $costOutput, ')
          ..write('costCacheRead: $costCacheRead, ')
          ..write('limitContext: $limitContext, ')
          ..write('limitOutput: $limitOutput, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspace_model_selections (id)',
    ),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    title,
    modelId,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ConversationsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationsTable extends DataClass
    implements Insertable<ConversationsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String workspaceId;
  final String title;
  final String? modelId;
  final bool isPinned;
  const ConversationsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    required this.title,
    this.modelId,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      title: Value(title),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      isPinned: Value(isPinned),
    );
  }

  factory ConversationsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      title: serializer.fromJson<String>(json['title']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'modelId': serializer.toJson<String?>(modelId),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  ConversationsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    String? title,
    Value<String?> modelId = const Value.absent(),
    bool? isPinned,
  }) => ConversationsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    modelId: modelId.present ? modelId.value : this.modelId,
    isPinned: isPinned ?? this.isPinned,
  );
  ConversationsTable copyWithCompanion(ConversationsCompanion data) {
    return ConversationsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('modelId: $modelId, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    title,
    modelId,
    isPinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.modelId == this.modelId &&
          other.isPinned == this.isPinned);
}

class ConversationsCompanion extends UpdateCompanion<ConversationsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String?> modelId;
  final Value<bool> isPinned;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.modelId = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    required String title,
    this.modelId = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       title = Value(title);
  static Insertable<ConversationsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? modelId,
    Expression<bool>? isPinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (modelId != null) 'model_id': modelId,
      if (isPinned != null) 'is_pinned': isPinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String?>? modelId,
    Value<bool>? isPinned,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      modelId: modelId ?? this.modelId,
      isPinned: isPinned ?? this.isPinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('modelId: $modelId, ')
          ..write('isPinned: $isPinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessagesTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MessagesTableType, String>
  messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MessagesTableType>($MessagesTable.$convertermessageType);
  static const VerificationMeta _isUserMeta = const VerificationMeta('isUser');
  @override
  late final GeneratedColumn<bool> isUser = GeneratedColumn<bool>(
    'is_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MessageTableStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MessageTableStatus>($MessagesTable.$converterstatus);
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    conversationId,
    content,
    messageType,
    isUser,
    status,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessagesTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_user')) {
      context.handle(
        _isUserMeta,
        isUser.isAcceptableOrUnknown(data['is_user']!, _isUserMeta),
      );
    } else if (isInserting) {
      context.missing(_isUserMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MessagesTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      messageType: $MessagesTable.$convertermessageType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}message_type'],
        )!,
      ),
      isUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user'],
      )!,
      status: $MessagesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MessagesTableType, String, String>
  $convertermessageType = const EnumNameConverter<MessagesTableType>(
    MessagesTableType.values,
  );
  static JsonTypeConverter2<MessageTableStatus, String, String>
  $converterstatus = const EnumNameConverter<MessageTableStatus>(
    MessageTableStatus.values,
  );
}

class MessagesTable extends DataClass implements Insertable<MessagesTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String conversationId;
  final String content;
  final MessagesTableType messageType;
  final bool isUser;
  final MessageTableStatus status;
  final String? metadata;
  const MessagesTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.conversationId,
    required this.content,
    required this.messageType,
    required this.isUser,
    required this.status,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['conversation_id'] = Variable<String>(conversationId);
    map['content'] = Variable<String>(content);
    {
      map['message_type'] = Variable<String>(
        $MessagesTable.$convertermessageType.toSql(messageType),
      );
    }
    map['is_user'] = Variable<bool>(isUser);
    {
      map['status'] = Variable<String>(
        $MessagesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      conversationId: Value(conversationId),
      content: Value(content),
      messageType: Value(messageType),
      isUser: Value(isUser),
      status: Value(status),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory MessagesTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      content: serializer.fromJson<String>(json['content']),
      messageType: $MessagesTable.$convertermessageType.fromJson(
        serializer.fromJson<String>(json['messageType']),
      ),
      isUser: serializer.fromJson<bool>(json['isUser']),
      status: $MessagesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'conversationId': serializer.toJson<String>(conversationId),
      'content': serializer.toJson<String>(content),
      'messageType': serializer.toJson<String>(
        $MessagesTable.$convertermessageType.toJson(messageType),
      ),
      'isUser': serializer.toJson<bool>(isUser),
      'status': serializer.toJson<String>(
        $MessagesTable.$converterstatus.toJson(status),
      ),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  MessagesTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? conversationId,
    String? content,
    MessagesTableType? messageType,
    bool? isUser,
    MessageTableStatus? status,
    Value<String?> metadata = const Value.absent(),
  }) => MessagesTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    conversationId: conversationId ?? this.conversationId,
    content: content ?? this.content,
    messageType: messageType ?? this.messageType,
    isUser: isUser ?? this.isUser,
    status: status ?? this.status,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  MessagesTable copyWithCompanion(MessagesCompanion data) {
    return MessagesTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      content: data.content.present ? data.content.value : this.content,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      isUser: data.isUser.present ? data.isUser.value : this.isUser,
      status: data.status.present ? data.status.value : this.status,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('isUser: $isUser, ')
          ..write('status: $status, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    conversationId,
    content,
    messageType,
    isUser,
    status,
    metadata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.conversationId == this.conversationId &&
          other.content == this.content &&
          other.messageType == this.messageType &&
          other.isUser == this.isUser &&
          other.status == this.status &&
          other.metadata == this.metadata);
}

class MessagesCompanion extends UpdateCompanion<MessagesTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> conversationId;
  final Value<String> content;
  final Value<MessagesTableType> messageType;
  final Value<bool> isUser;
  final Value<MessageTableStatus> status;
  final Value<String?> metadata;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.content = const Value.absent(),
    this.messageType = const Value.absent(),
    this.isUser = const Value.absent(),
    this.status = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String conversationId,
    required String content,
    required MessagesTableType messageType,
    required bool isUser,
    required MessageTableStatus status,
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       content = Value(content),
       messageType = Value(messageType),
       isUser = Value(isUser),
       status = Value(status);
  static Insertable<MessagesTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? conversationId,
    Expression<String>? content,
    Expression<String>? messageType,
    Expression<bool>? isUser,
    Expression<String>? status,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (conversationId != null) 'conversation_id': conversationId,
      if (content != null) 'content': content,
      if (messageType != null) 'message_type': messageType,
      if (isUser != null) 'is_user': isUser,
      if (status != null) 'status': status,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? conversationId,
    Value<String>? content,
    Value<MessagesTableType>? messageType,
    Value<bool>? isUser,
    Value<MessageTableStatus>? status,
    Value<String?>? metadata,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      isUser: isUser ?? this.isUser,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(
        $MessagesTable.$convertermessageType.toSql(messageType.value),
      );
    }
    if (isUser.present) {
      map['is_user'] = Variable<bool>(isUser.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $MessagesTable.$converterstatus.toSql(status.value),
      );
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('isUser: $isUser, ')
          ..write('status: $status, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $McpServersTable extends McpServers
    with TableInfo<$McpServersTable, McpServersTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $McpServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<McpTransportType, String>
  transport = GeneratedColumn<String>(
    'transport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<McpTransportType>($McpServersTable.$convertertransport);
  @override
  late final GeneratedColumnWithTypeConverter<McpAuthenticationType, String>
  authenticationType =
      GeneratedColumn<String>(
        'authentication_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<McpAuthenticationType>(
        $McpServersTable.$converterauthenticationType,
      );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    name,
    url,
    transport,
    authenticationType,
    description,
    isEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mcp_servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<McpServersTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  McpServersTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return McpServersTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      transport: $McpServersTable.$convertertransport.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}transport'],
        )!,
      ),
      authenticationType: $McpServersTable.$converterauthenticationType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}authentication_type'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
    );
  }

  @override
  $McpServersTable createAlias(String alias) {
    return $McpServersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<McpTransportType, String, Object?>
  $convertertransport = transportTypeConverter;
  static JsonTypeConverter2<McpAuthenticationType, String, Object?>
  $converterauthenticationType = authenticationTypeConverter;
}

class McpServersTable extends DataClass implements Insertable<McpServersTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// Reference to the workspace this MCP server belongs to
  final String workspaceId;

  /// User-friendly name for the MCP server
  final String name;

  /// URL endpoint for the MCP server
  final String url;

  /// Transport type: 'sse' or 'streamable_http'
  final McpTransportType transport;

  /// Authentication type: 'none', 'oauth', or 'bearer_token'
  final McpAuthenticationType authenticationType;

  /// Optional description of what this MCP server provides
  final String? description;

  /// Whether the MCP server is enabled for connections
  final bool isEnabled;
  const McpServersTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    required this.name,
    required this.url,
    required this.transport,
    required this.authenticationType,
    this.description,
    required this.isEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    {
      map['transport'] = Variable<String>(
        $McpServersTable.$convertertransport.toSql(transport),
      );
    }
    {
      map['authentication_type'] = Variable<String>(
        $McpServersTable.$converterauthenticationType.toSql(authenticationType),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  McpServersCompanion toCompanion(bool nullToAbsent) {
    return McpServersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      name: Value(name),
      url: Value(url),
      transport: Value(transport),
      authenticationType: Value(authenticationType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isEnabled: Value(isEnabled),
    );
  }

  factory McpServersTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return McpServersTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      transport: $McpServersTable.$convertertransport.fromJson(
        serializer.fromJson<Object?>(json['transport']),
      ),
      authenticationType: $McpServersTable.$converterauthenticationType
          .fromJson(serializer.fromJson<Object?>(json['authenticationType'])),
      description: serializer.fromJson<String?>(json['description']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'transport': serializer.toJson<Object?>(
        $McpServersTable.$convertertransport.toJson(transport),
      ),
      'authenticationType': serializer.toJson<Object?>(
        $McpServersTable.$converterauthenticationType.toJson(
          authenticationType,
        ),
      ),
      'description': serializer.toJson<String?>(description),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  McpServersTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    String? name,
    String? url,
    McpTransportType? transport,
    McpAuthenticationType? authenticationType,
    Value<String?> description = const Value.absent(),
    bool? isEnabled,
  }) => McpServersTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    url: url ?? this.url,
    transport: transport ?? this.transport,
    authenticationType: authenticationType ?? this.authenticationType,
    description: description.present ? description.value : this.description,
    isEnabled: isEnabled ?? this.isEnabled,
  );
  McpServersTable copyWithCompanion(McpServersCompanion data) {
    return McpServersTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      transport: data.transport.present ? data.transport.value : this.transport,
      authenticationType: data.authenticationType.present
          ? data.authenticationType.value
          : this.authenticationType,
      description: data.description.present
          ? data.description.value
          : this.description,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('McpServersTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('transport: $transport, ')
          ..write('authenticationType: $authenticationType, ')
          ..write('description: $description, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    name,
    url,
    transport,
    authenticationType,
    description,
    isEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpServersTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.url == this.url &&
          other.transport == this.transport &&
          other.authenticationType == this.authenticationType &&
          other.description == this.description &&
          other.isEnabled == this.isEnabled);
}

class McpServersCompanion extends UpdateCompanion<McpServersTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String> url;
  final Value<McpTransportType> transport;
  final Value<McpAuthenticationType> authenticationType;
  final Value<String?> description;
  final Value<bool> isEnabled;
  final Value<int> rowid;
  const McpServersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.transport = const Value.absent(),
    this.authenticationType = const Value.absent(),
    this.description = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  McpServersCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    required String name,
    required String url,
    required McpTransportType transport,
    required McpAuthenticationType authenticationType,
    this.description = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       name = Value(name),
       url = Value(url),
       transport = Value(transport),
       authenticationType = Value(authenticationType);
  static Insertable<McpServersTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? transport,
    Expression<String>? authenticationType,
    Expression<String>? description,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (transport != null) 'transport': transport,
      if (authenticationType != null) 'authentication_type': authenticationType,
      if (description != null) 'description': description,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  McpServersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String>? url,
    Value<McpTransportType>? transport,
    Value<McpAuthenticationType>? authenticationType,
    Value<String?>? description,
    Value<bool>? isEnabled,
    Value<int>? rowid,
  }) {
    return McpServersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      url: url ?? this.url,
      transport: transport ?? this.transport,
      authenticationType: authenticationType ?? this.authenticationType,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (transport.present) {
      map['transport'] = Variable<String>(
        $McpServersTable.$convertertransport.toSql(transport.value),
      );
    }
    if (authenticationType.present) {
      map['authentication_type'] = Variable<String>(
        $McpServersTable.$converterauthenticationType.toSql(
          authenticationType.value,
        ),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('McpServersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('transport: $transport, ')
          ..write('authenticationType: $authenticationType, ')
          ..write('description: $description, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ToolsGroupsTable extends ToolsGroups
    with TableInfo<$ToolsGroupsTable, ToolsGroupsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToolsGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _mcpServerIdMeta = const VerificationMeta(
    'mcpServerId',
  );
  @override
  late final GeneratedColumn<String> mcpServerId = GeneratedColumn<String>(
    'mcp_server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mcp_servers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PermissionAccess, String>
  permissions = GeneratedColumn<String>(
    'permissions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PermissionAccess>($ToolsGroupsTable.$converterpermissions);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    mcpServerId,
    name,
    isEnabled,
    permissions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tools_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ToolsGroupsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('mcp_server_id')) {
      context.handle(
        _mcpServerIdMeta,
        mcpServerId.isAcceptableOrUnknown(
          data['mcp_server_id']!,
          _mcpServerIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId, id};
  @override
  ToolsGroupsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToolsGroupsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      mcpServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mcp_server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      permissions: $ToolsGroupsTable.$converterpermissions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}permissions'],
        )!,
      ),
    );
  }

  @override
  $ToolsGroupsTable createAlias(String alias) {
    return $ToolsGroupsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PermissionAccess, String, String>
  $converterpermissions = const EnumNameConverter<PermissionAccess>(
    PermissionAccess.values,
  );
}

class ToolsGroupsTable extends DataClass
    implements Insertable<ToolsGroupsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// Reference to the workspace this tools group belongs to
  final String workspaceId;

  /// Optional reference to the MCP server this group belongs to.
  /// When the MCP server is deleted, this group and its tools are also deleted.
  final String? mcpServerId;
  final String name;

  /// Whether the tool is enabled for this workspace
  final bool isEnabled;
  final PermissionAccess permissions;
  const ToolsGroupsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    this.mcpServerId,
    required this.name,
    required this.isEnabled,
    required this.permissions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || mcpServerId != null) {
      map['mcp_server_id'] = Variable<String>(mcpServerId);
    }
    map['name'] = Variable<String>(name);
    map['is_enabled'] = Variable<bool>(isEnabled);
    {
      map['permissions'] = Variable<String>(
        $ToolsGroupsTable.$converterpermissions.toSql(permissions),
      );
    }
    return map;
  }

  ToolsGroupsCompanion toCompanion(bool nullToAbsent) {
    return ToolsGroupsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      mcpServerId: mcpServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(mcpServerId),
      name: Value(name),
      isEnabled: Value(isEnabled),
      permissions: Value(permissions),
    );
  }

  factory ToolsGroupsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToolsGroupsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      mcpServerId: serializer.fromJson<String?>(json['mcpServerId']),
      name: serializer.fromJson<String>(json['name']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      permissions: $ToolsGroupsTable.$converterpermissions.fromJson(
        serializer.fromJson<String>(json['permissions']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'mcpServerId': serializer.toJson<String?>(mcpServerId),
      'name': serializer.toJson<String>(name),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'permissions': serializer.toJson<String>(
        $ToolsGroupsTable.$converterpermissions.toJson(permissions),
      ),
    };
  }

  ToolsGroupsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    Value<String?> mcpServerId = const Value.absent(),
    String? name,
    bool? isEnabled,
    PermissionAccess? permissions,
  }) => ToolsGroupsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    mcpServerId: mcpServerId.present ? mcpServerId.value : this.mcpServerId,
    name: name ?? this.name,
    isEnabled: isEnabled ?? this.isEnabled,
    permissions: permissions ?? this.permissions,
  );
  ToolsGroupsTable copyWithCompanion(ToolsGroupsCompanion data) {
    return ToolsGroupsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      mcpServerId: data.mcpServerId.present
          ? data.mcpServerId.value
          : this.mcpServerId,
      name: data.name.present ? data.name.value : this.name,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToolsGroupsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('mcpServerId: $mcpServerId, ')
          ..write('name: $name, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('permissions: $permissions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    mcpServerId,
    name,
    isEnabled,
    permissions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolsGroupsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.mcpServerId == this.mcpServerId &&
          other.name == this.name &&
          other.isEnabled == this.isEnabled &&
          other.permissions == this.permissions);
}

class ToolsGroupsCompanion extends UpdateCompanion<ToolsGroupsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<String?> mcpServerId;
  final Value<String> name;
  final Value<bool> isEnabled;
  final Value<PermissionAccess> permissions;
  final Value<int> rowid;
  const ToolsGroupsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.mcpServerId = const Value.absent(),
    this.name = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.permissions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ToolsGroupsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    this.mcpServerId = const Value.absent(),
    required String name,
    this.isEnabled = const Value.absent(),
    required PermissionAccess permissions,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       name = Value(name),
       permissions = Value(permissions);
  static Insertable<ToolsGroupsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<String>? mcpServerId,
    Expression<String>? name,
    Expression<bool>? isEnabled,
    Expression<String>? permissions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (mcpServerId != null) 'mcp_server_id': mcpServerId,
      if (name != null) 'name': name,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (permissions != null) 'permissions': permissions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ToolsGroupsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<String?>? mcpServerId,
    Value<String>? name,
    Value<bool>? isEnabled,
    Value<PermissionAccess>? permissions,
    Value<int>? rowid,
  }) {
    return ToolsGroupsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      mcpServerId: mcpServerId ?? this.mcpServerId,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      permissions: permissions ?? this.permissions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (mcpServerId.present) {
      map['mcp_server_id'] = Variable<String>(mcpServerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(
        $ToolsGroupsTable.$converterpermissions.toSql(permissions.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToolsGroupsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('mcpServerId: $mcpServerId, ')
          ..write('name: $name, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('permissions: $permissions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ToolsTable extends Tools with TableInfo<$ToolsTable, ToolsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _workspaceToolsGroupIdMeta =
      const VerificationMeta('workspaceToolsGroupId');
  @override
  late final GeneratedColumn<String> workspaceToolsGroupId =
      GeneratedColumn<String>(
        'workspace_tools_group_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tools_groups (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _toolIdMeta = const VerificationMeta('toolId');
  @override
  late final GeneratedColumn<String> toolId = GeneratedColumn<String>(
    'tool_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _additionalPromptMeta = const VerificationMeta(
    'additionalPrompt',
  );
  @override
  late final GeneratedColumn<String> additionalPrompt = GeneratedColumn<String>(
    'additional_prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputSchemaMeta = const VerificationMeta(
    'inputSchema',
  );
  @override
  late final GeneratedColumn<String> inputSchema = GeneratedColumn<String>(
    'input_schema',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PermissionAccess, String>
  permissions = GeneratedColumn<String>(
    'permissions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(PermissionAccess.ask.name),
  ).withConverter<PermissionAccess>($ToolsTable.$converterpermissions);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    workspaceToolsGroupId,
    toolId,
    customName,
    description,
    additionalPrompt,
    config,
    inputSchema,
    isEnabled,
    permissions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tools';
  @override
  VerificationContext validateIntegrity(
    Insertable<ToolsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('workspace_tools_group_id')) {
      context.handle(
        _workspaceToolsGroupIdMeta,
        workspaceToolsGroupId.isAcceptableOrUnknown(
          data['workspace_tools_group_id']!,
          _workspaceToolsGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('tool_id')) {
      context.handle(
        _toolIdMeta,
        toolId.isAcceptableOrUnknown(data['tool_id']!, _toolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toolIdMeta);
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('additional_prompt')) {
      context.handle(
        _additionalPromptMeta,
        additionalPrompt.isAcceptableOrUnknown(
          data['additional_prompt']!,
          _additionalPromptMeta,
        ),
      );
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    }
    if (data.containsKey('input_schema')) {
      context.handle(
        _inputSchemaMeta,
        inputSchema.isAcceptableOrUnknown(
          data['input_schema']!,
          _inputSchemaMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId, id};
  @override
  ToolsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ToolsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      workspaceToolsGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_tools_group_id'],
      ),
      toolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_id'],
      )!,
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      additionalPrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}additional_prompt'],
      ),
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      ),
      inputSchema: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_schema'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      permissions: $ToolsTable.$converterpermissions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}permissions'],
        )!,
      ),
    );
  }

  @override
  $ToolsTable createAlias(String alias) {
    return $ToolsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PermissionAccess, String, String>
  $converterpermissions = const EnumNameConverter<PermissionAccess>(
    PermissionAccess.values,
  );
}

class ToolsTable extends DataClass implements Insertable<ToolsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// Reference to the workspace this tool belongs to
  final String workspaceId;
  final String? workspaceToolsGroupId;

  /// Type of tool (e.g., 'web_search', 'calculator', etc.)
  final String toolId;
  final String? customName;

  /// Optional description of the tool (from MCP or user-defined)
  final String? description;
  final String? additionalPrompt;

  /// Tool configuration as JSON (optional)
  final String? config;

  /// JSON Schema for the tool's input parameters (for MCP tools)
  final String? inputSchema;

  /// Whether the tool is enabled for this workspace
  final bool isEnabled;
  final PermissionAccess permissions;
  const ToolsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    this.workspaceToolsGroupId,
    required this.toolId,
    this.customName,
    this.description,
    this.additionalPrompt,
    this.config,
    this.inputSchema,
    required this.isEnabled,
    required this.permissions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || workspaceToolsGroupId != null) {
      map['workspace_tools_group_id'] = Variable<String>(workspaceToolsGroupId);
    }
    map['tool_id'] = Variable<String>(toolId);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || additionalPrompt != null) {
      map['additional_prompt'] = Variable<String>(additionalPrompt);
    }
    if (!nullToAbsent || config != null) {
      map['config'] = Variable<String>(config);
    }
    if (!nullToAbsent || inputSchema != null) {
      map['input_schema'] = Variable<String>(inputSchema);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    {
      map['permissions'] = Variable<String>(
        $ToolsTable.$converterpermissions.toSql(permissions),
      );
    }
    return map;
  }

  ToolsCompanion toCompanion(bool nullToAbsent) {
    return ToolsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      workspaceToolsGroupId: workspaceToolsGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(workspaceToolsGroupId),
      toolId: Value(toolId),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      additionalPrompt: additionalPrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(additionalPrompt),
      config: config == null && nullToAbsent
          ? const Value.absent()
          : Value(config),
      inputSchema: inputSchema == null && nullToAbsent
          ? const Value.absent()
          : Value(inputSchema),
      isEnabled: Value(isEnabled),
      permissions: Value(permissions),
    );
  }

  factory ToolsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ToolsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      workspaceToolsGroupId: serializer.fromJson<String?>(
        json['workspaceToolsGroupId'],
      ),
      toolId: serializer.fromJson<String>(json['toolId']),
      customName: serializer.fromJson<String?>(json['customName']),
      description: serializer.fromJson<String?>(json['description']),
      additionalPrompt: serializer.fromJson<String?>(json['additionalPrompt']),
      config: serializer.fromJson<String?>(json['config']),
      inputSchema: serializer.fromJson<String?>(json['inputSchema']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      permissions: $ToolsTable.$converterpermissions.fromJson(
        serializer.fromJson<String>(json['permissions']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'workspaceToolsGroupId': serializer.toJson<String?>(
        workspaceToolsGroupId,
      ),
      'toolId': serializer.toJson<String>(toolId),
      'customName': serializer.toJson<String?>(customName),
      'description': serializer.toJson<String?>(description),
      'additionalPrompt': serializer.toJson<String?>(additionalPrompt),
      'config': serializer.toJson<String?>(config),
      'inputSchema': serializer.toJson<String?>(inputSchema),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'permissions': serializer.toJson<String>(
        $ToolsTable.$converterpermissions.toJson(permissions),
      ),
    };
  }

  ToolsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    Value<String?> workspaceToolsGroupId = const Value.absent(),
    String? toolId,
    Value<String?> customName = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> additionalPrompt = const Value.absent(),
    Value<String?> config = const Value.absent(),
    Value<String?> inputSchema = const Value.absent(),
    bool? isEnabled,
    PermissionAccess? permissions,
  }) => ToolsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    workspaceToolsGroupId: workspaceToolsGroupId.present
        ? workspaceToolsGroupId.value
        : this.workspaceToolsGroupId,
    toolId: toolId ?? this.toolId,
    customName: customName.present ? customName.value : this.customName,
    description: description.present ? description.value : this.description,
    additionalPrompt: additionalPrompt.present
        ? additionalPrompt.value
        : this.additionalPrompt,
    config: config.present ? config.value : this.config,
    inputSchema: inputSchema.present ? inputSchema.value : this.inputSchema,
    isEnabled: isEnabled ?? this.isEnabled,
    permissions: permissions ?? this.permissions,
  );
  ToolsTable copyWithCompanion(ToolsCompanion data) {
    return ToolsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      workspaceToolsGroupId: data.workspaceToolsGroupId.present
          ? data.workspaceToolsGroupId.value
          : this.workspaceToolsGroupId,
      toolId: data.toolId.present ? data.toolId.value : this.toolId,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      description: data.description.present
          ? data.description.value
          : this.description,
      additionalPrompt: data.additionalPrompt.present
          ? data.additionalPrompt.value
          : this.additionalPrompt,
      config: data.config.present ? data.config.value : this.config,
      inputSchema: data.inputSchema.present
          ? data.inputSchema.value
          : this.inputSchema,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ToolsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('workspaceToolsGroupId: $workspaceToolsGroupId, ')
          ..write('toolId: $toolId, ')
          ..write('customName: $customName, ')
          ..write('description: $description, ')
          ..write('additionalPrompt: $additionalPrompt, ')
          ..write('config: $config, ')
          ..write('inputSchema: $inputSchema, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('permissions: $permissions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    workspaceToolsGroupId,
    toolId,
    customName,
    description,
    additionalPrompt,
    config,
    inputSchema,
    isEnabled,
    permissions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.workspaceToolsGroupId == this.workspaceToolsGroupId &&
          other.toolId == this.toolId &&
          other.customName == this.customName &&
          other.description == this.description &&
          other.additionalPrompt == this.additionalPrompt &&
          other.config == this.config &&
          other.inputSchema == this.inputSchema &&
          other.isEnabled == this.isEnabled &&
          other.permissions == this.permissions);
}

class ToolsCompanion extends UpdateCompanion<ToolsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<String?> workspaceToolsGroupId;
  final Value<String> toolId;
  final Value<String?> customName;
  final Value<String?> description;
  final Value<String?> additionalPrompt;
  final Value<String?> config;
  final Value<String?> inputSchema;
  final Value<bool> isEnabled;
  final Value<PermissionAccess> permissions;
  final Value<int> rowid;
  const ToolsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.workspaceToolsGroupId = const Value.absent(),
    this.toolId = const Value.absent(),
    this.customName = const Value.absent(),
    this.description = const Value.absent(),
    this.additionalPrompt = const Value.absent(),
    this.config = const Value.absent(),
    this.inputSchema = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.permissions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ToolsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    this.workspaceToolsGroupId = const Value.absent(),
    required String toolId,
    this.customName = const Value.absent(),
    this.description = const Value.absent(),
    this.additionalPrompt = const Value.absent(),
    this.config = const Value.absent(),
    this.inputSchema = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.permissions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       toolId = Value(toolId);
  static Insertable<ToolsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<String>? workspaceToolsGroupId,
    Expression<String>? toolId,
    Expression<String>? customName,
    Expression<String>? description,
    Expression<String>? additionalPrompt,
    Expression<String>? config,
    Expression<String>? inputSchema,
    Expression<bool>? isEnabled,
    Expression<String>? permissions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (workspaceToolsGroupId != null)
        'workspace_tools_group_id': workspaceToolsGroupId,
      if (toolId != null) 'tool_id': toolId,
      if (customName != null) 'custom_name': customName,
      if (description != null) 'description': description,
      if (additionalPrompt != null) 'additional_prompt': additionalPrompt,
      if (config != null) 'config': config,
      if (inputSchema != null) 'input_schema': inputSchema,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (permissions != null) 'permissions': permissions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ToolsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<String?>? workspaceToolsGroupId,
    Value<String>? toolId,
    Value<String?>? customName,
    Value<String?>? description,
    Value<String?>? additionalPrompt,
    Value<String?>? config,
    Value<String?>? inputSchema,
    Value<bool>? isEnabled,
    Value<PermissionAccess>? permissions,
    Value<int>? rowid,
  }) {
    return ToolsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceToolsGroupId:
          workspaceToolsGroupId ?? this.workspaceToolsGroupId,
      toolId: toolId ?? this.toolId,
      customName: customName ?? this.customName,
      description: description ?? this.description,
      additionalPrompt: additionalPrompt ?? this.additionalPrompt,
      config: config ?? this.config,
      inputSchema: inputSchema ?? this.inputSchema,
      isEnabled: isEnabled ?? this.isEnabled,
      permissions: permissions ?? this.permissions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (workspaceToolsGroupId.present) {
      map['workspace_tools_group_id'] = Variable<String>(
        workspaceToolsGroupId.value,
      );
    }
    if (toolId.present) {
      map['tool_id'] = Variable<String>(toolId.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (additionalPrompt.present) {
      map['additional_prompt'] = Variable<String>(additionalPrompt.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (inputSchema.present) {
      map['input_schema'] = Variable<String>(inputSchema.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(
        $ToolsTable.$converterpermissions.toSql(permissions.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToolsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('workspaceToolsGroupId: $workspaceToolsGroupId, ')
          ..write('toolId: $toolId, ')
          ..write('customName: $customName, ')
          ..write('description: $description, ')
          ..write('additionalPrompt: $additionalPrompt, ')
          ..write('config: $config, ')
          ..write('inputSchema: $inputSchema, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('permissions: $permissions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationToolsTable extends ConversationTools
    with TableInfo<$ConversationToolsTable, ConversationToolsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationToolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _toolIdMeta = const VerificationMeta('toolId');
  @override
  late final GeneratedColumn<String> toolId = GeneratedColumn<String>(
    'tool_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tools (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PermissionAccess, String>
  permissions =
      GeneratedColumn<String>(
        'permissions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(PermissionAccess.ask.name),
      ).withConverter<PermissionAccess>(
        $ConversationToolsTable.$converterpermissions,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    conversationId,
    toolId,
    isEnabled,
    permissions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_tools';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationToolsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('tool_id')) {
      context.handle(
        _toolIdMeta,
        toolId.isAcceptableOrUnknown(data['tool_id']!, _toolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toolIdMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, toolId};
  @override
  ConversationToolsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationToolsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      toolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_id'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      permissions: $ConversationToolsTable.$converterpermissions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}permissions'],
        )!,
      ),
    );
  }

  @override
  $ConversationToolsTable createAlias(String alias) {
    return $ConversationToolsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PermissionAccess, String, String>
  $converterpermissions = const EnumNameConverter<PermissionAccess>(
    PermissionAccess.values,
  );
}

class ConversationToolsTable extends DataClass
    implements Insertable<ConversationToolsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// Reference to the conversation this tool setting belongs to
  final String conversationId;
  final String toolId;

  /// Whether the tool is enabled for this workspace
  final bool isEnabled;
  final PermissionAccess permissions;
  const ConversationToolsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.conversationId,
    required this.toolId,
    required this.isEnabled,
    required this.permissions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['conversation_id'] = Variable<String>(conversationId);
    map['tool_id'] = Variable<String>(toolId);
    map['is_enabled'] = Variable<bool>(isEnabled);
    {
      map['permissions'] = Variable<String>(
        $ConversationToolsTable.$converterpermissions.toSql(permissions),
      );
    }
    return map;
  }

  ConversationToolsCompanion toCompanion(bool nullToAbsent) {
    return ConversationToolsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      conversationId: Value(conversationId),
      toolId: Value(toolId),
      isEnabled: Value(isEnabled),
      permissions: Value(permissions),
    );
  }

  factory ConversationToolsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationToolsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      toolId: serializer.fromJson<String>(json['toolId']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      permissions: $ConversationToolsTable.$converterpermissions.fromJson(
        serializer.fromJson<String>(json['permissions']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'conversationId': serializer.toJson<String>(conversationId),
      'toolId': serializer.toJson<String>(toolId),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'permissions': serializer.toJson<String>(
        $ConversationToolsTable.$converterpermissions.toJson(permissions),
      ),
    };
  }

  ConversationToolsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? conversationId,
    String? toolId,
    bool? isEnabled,
    PermissionAccess? permissions,
  }) => ConversationToolsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    conversationId: conversationId ?? this.conversationId,
    toolId: toolId ?? this.toolId,
    isEnabled: isEnabled ?? this.isEnabled,
    permissions: permissions ?? this.permissions,
  );
  ConversationToolsTable copyWithCompanion(ConversationToolsCompanion data) {
    return ConversationToolsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      toolId: data.toolId.present ? data.toolId.value : this.toolId,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationToolsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('toolId: $toolId, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('permissions: $permissions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    conversationId,
    toolId,
    isEnabled,
    permissions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationToolsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.conversationId == this.conversationId &&
          other.toolId == this.toolId &&
          other.isEnabled == this.isEnabled &&
          other.permissions == this.permissions);
}

class ConversationToolsCompanion
    extends UpdateCompanion<ConversationToolsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> conversationId;
  final Value<String> toolId;
  final Value<bool> isEnabled;
  final Value<PermissionAccess> permissions;
  final Value<int> rowid;
  const ConversationToolsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.toolId = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.permissions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationToolsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String conversationId,
    required String toolId,
    this.isEnabled = const Value.absent(),
    this.permissions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       toolId = Value(toolId);
  static Insertable<ConversationToolsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? conversationId,
    Expression<String>? toolId,
    Expression<bool>? isEnabled,
    Expression<String>? permissions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (conversationId != null) 'conversation_id': conversationId,
      if (toolId != null) 'tool_id': toolId,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (permissions != null) 'permissions': permissions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationToolsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? conversationId,
    Value<String>? toolId,
    Value<bool>? isEnabled,
    Value<PermissionAccess>? permissions,
    Value<int>? rowid,
  }) {
    return ConversationToolsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      conversationId: conversationId ?? this.conversationId,
      toolId: toolId ?? this.toolId,
      isEnabled: isEnabled ?? this.isEnabled,
      permissions: permissions ?? this.permissions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (toolId.present) {
      map['tool_id'] = Variable<String>(toolId.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(
        $ConversationToolsTable.$converterpermissions.toSql(permissions.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationToolsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('toolId: $toolId, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('permissions: $permissions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspaceCompactionSettingsTable extends WorkspaceCompactionSettings
    with
        TableInfo<
          $WorkspaceCompactionSettingsTable,
          WorkspaceCompactionSettingsTable
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspaceCompactionSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _autoCompactEnabledMeta =
      const VerificationMeta('autoCompactEnabled');
  @override
  late final GeneratedColumn<bool> autoCompactEnabled = GeneratedColumn<bool>(
    'auto_compact_enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_compact_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _usagePercentageThresholdMeta =
      const VerificationMeta('usagePercentageThreshold');
  @override
  late final GeneratedColumn<int> usagePercentageThreshold =
      GeneratedColumn<int>(
        'usage_percentage_threshold',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remainingTokenThresholdMeta =
      const VerificationMeta('remainingTokenThreshold');
  @override
  late final GeneratedColumn<int> remainingTokenThreshold =
      GeneratedColumn<int>(
        'remaining_token_threshold',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    autoCompactEnabled,
    usagePercentageThreshold,
    remainingTokenThreshold,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_compaction_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceCompactionSettingsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('auto_compact_enabled')) {
      context.handle(
        _autoCompactEnabledMeta,
        autoCompactEnabled.isAcceptableOrUnknown(
          data['auto_compact_enabled']!,
          _autoCompactEnabledMeta,
        ),
      );
    }
    if (data.containsKey('usage_percentage_threshold')) {
      context.handle(
        _usagePercentageThresholdMeta,
        usagePercentageThreshold.isAcceptableOrUnknown(
          data['usage_percentage_threshold']!,
          _usagePercentageThresholdMeta,
        ),
      );
    }
    if (data.containsKey('remaining_token_threshold')) {
      context.handle(
        _remainingTokenThresholdMeta,
        remainingTokenThreshold.isAcceptableOrUnknown(
          data['remaining_token_threshold']!,
          _remainingTokenThresholdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workspaceId};
  @override
  WorkspaceCompactionSettingsTable map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceCompactionSettingsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      autoCompactEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_compact_enabled'],
      ),
      usagePercentageThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_percentage_threshold'],
      ),
      remainingTokenThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remaining_token_threshold'],
      ),
    );
  }

  @override
  $WorkspaceCompactionSettingsTable createAlias(String alias) {
    return $WorkspaceCompactionSettingsTable(attachedDatabase, alias);
  }
}

class WorkspaceCompactionSettingsTable extends DataClass
    implements Insertable<WorkspaceCompactionSettingsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String workspaceId;
  final bool? autoCompactEnabled;
  final int? usagePercentageThreshold;
  final int? remainingTokenThreshold;
  const WorkspaceCompactionSettingsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    this.autoCompactEnabled,
    this.usagePercentageThreshold,
    this.remainingTokenThreshold,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || autoCompactEnabled != null) {
      map['auto_compact_enabled'] = Variable<bool>(autoCompactEnabled);
    }
    if (!nullToAbsent || usagePercentageThreshold != null) {
      map['usage_percentage_threshold'] = Variable<int>(
        usagePercentageThreshold,
      );
    }
    if (!nullToAbsent || remainingTokenThreshold != null) {
      map['remaining_token_threshold'] = Variable<int>(remainingTokenThreshold);
    }
    return map;
  }

  WorkspaceCompactionSettingsCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceCompactionSettingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      autoCompactEnabled: autoCompactEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(autoCompactEnabled),
      usagePercentageThreshold: usagePercentageThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(usagePercentageThreshold),
      remainingTokenThreshold: remainingTokenThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(remainingTokenThreshold),
    );
  }

  factory WorkspaceCompactionSettingsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceCompactionSettingsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      autoCompactEnabled: serializer.fromJson<bool?>(
        json['autoCompactEnabled'],
      ),
      usagePercentageThreshold: serializer.fromJson<int?>(
        json['usagePercentageThreshold'],
      ),
      remainingTokenThreshold: serializer.fromJson<int?>(
        json['remainingTokenThreshold'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'autoCompactEnabled': serializer.toJson<bool?>(autoCompactEnabled),
      'usagePercentageThreshold': serializer.toJson<int?>(
        usagePercentageThreshold,
      ),
      'remainingTokenThreshold': serializer.toJson<int?>(
        remainingTokenThreshold,
      ),
    };
  }

  WorkspaceCompactionSettingsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    Value<bool?> autoCompactEnabled = const Value.absent(),
    Value<int?> usagePercentageThreshold = const Value.absent(),
    Value<int?> remainingTokenThreshold = const Value.absent(),
  }) => WorkspaceCompactionSettingsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    autoCompactEnabled: autoCompactEnabled.present
        ? autoCompactEnabled.value
        : this.autoCompactEnabled,
    usagePercentageThreshold: usagePercentageThreshold.present
        ? usagePercentageThreshold.value
        : this.usagePercentageThreshold,
    remainingTokenThreshold: remainingTokenThreshold.present
        ? remainingTokenThreshold.value
        : this.remainingTokenThreshold,
  );
  WorkspaceCompactionSettingsTable copyWithCompanion(
    WorkspaceCompactionSettingsCompanion data,
  ) {
    return WorkspaceCompactionSettingsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      autoCompactEnabled: data.autoCompactEnabled.present
          ? data.autoCompactEnabled.value
          : this.autoCompactEnabled,
      usagePercentageThreshold: data.usagePercentageThreshold.present
          ? data.usagePercentageThreshold.value
          : this.usagePercentageThreshold,
      remainingTokenThreshold: data.remainingTokenThreshold.present
          ? data.remainingTokenThreshold.value
          : this.remainingTokenThreshold,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceCompactionSettingsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('autoCompactEnabled: $autoCompactEnabled, ')
          ..write('usagePercentageThreshold: $usagePercentageThreshold, ')
          ..write('remainingTokenThreshold: $remainingTokenThreshold')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    autoCompactEnabled,
    usagePercentageThreshold,
    remainingTokenThreshold,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceCompactionSettingsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.autoCompactEnabled == this.autoCompactEnabled &&
          other.usagePercentageThreshold == this.usagePercentageThreshold &&
          other.remainingTokenThreshold == this.remainingTokenThreshold);
}

class WorkspaceCompactionSettingsCompanion
    extends UpdateCompanion<WorkspaceCompactionSettingsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<bool?> autoCompactEnabled;
  final Value<int?> usagePercentageThreshold;
  final Value<int?> remainingTokenThreshold;
  final Value<int> rowid;
  const WorkspaceCompactionSettingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.autoCompactEnabled = const Value.absent(),
    this.usagePercentageThreshold = const Value.absent(),
    this.remainingTokenThreshold = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceCompactionSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    this.autoCompactEnabled = const Value.absent(),
    this.usagePercentageThreshold = const Value.absent(),
    this.remainingTokenThreshold = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId);
  static Insertable<WorkspaceCompactionSettingsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<bool>? autoCompactEnabled,
    Expression<int>? usagePercentageThreshold,
    Expression<int>? remainingTokenThreshold,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (autoCompactEnabled != null)
        'auto_compact_enabled': autoCompactEnabled,
      if (usagePercentageThreshold != null)
        'usage_percentage_threshold': usagePercentageThreshold,
      if (remainingTokenThreshold != null)
        'remaining_token_threshold': remainingTokenThreshold,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceCompactionSettingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<bool?>? autoCompactEnabled,
    Value<int?>? usagePercentageThreshold,
    Value<int?>? remainingTokenThreshold,
    Value<int>? rowid,
  }) {
    return WorkspaceCompactionSettingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      autoCompactEnabled: autoCompactEnabled ?? this.autoCompactEnabled,
      usagePercentageThreshold:
          usagePercentageThreshold ?? this.usagePercentageThreshold,
      remainingTokenThreshold:
          remainingTokenThreshold ?? this.remainingTokenThreshold,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (autoCompactEnabled.present) {
      map['auto_compact_enabled'] = Variable<bool>(autoCompactEnabled.value);
    }
    if (usagePercentageThreshold.present) {
      map['usage_percentage_threshold'] = Variable<int>(
        usagePercentageThreshold.value,
      );
    }
    if (remainingTokenThreshold.present) {
      map['remaining_token_threshold'] = Variable<int>(
        remainingTokenThreshold.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceCompactionSettingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('autoCompactEnabled: $autoCompactEnabled, ')
          ..write('usagePercentageThreshold: $usagePercentageThreshold, ')
          ..write('remainingTokenThreshold: $remainingTokenThreshold, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SkillCredentialDefinitionsTable extends SkillCredentialDefinitions
    with
        TableInfo<
          $SkillCredentialDefinitionsTable,
          SkillCredentialDefinitionsTable
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillCredentialDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attributesJsonMeta = const VerificationMeta(
    'attributesJson',
  );
  @override
  late final GeneratedColumn<String> attributesJson = GeneratedColumn<String>(
    'attributes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    title,
    slug,
    attributesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skill_credential_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkillCredentialDefinitionsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('attributes_json')) {
      context.handle(
        _attributesJsonMeta,
        attributesJson.isAcceptableOrUnknown(
          data['attributes_json']!,
          _attributesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attributesJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, title},
    {workspaceId, slug},
  ];
  @override
  SkillCredentialDefinitionsTable map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkillCredentialDefinitionsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      attributesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attributes_json'],
      )!,
    );
  }

  @override
  $SkillCredentialDefinitionsTable createAlias(String alias) {
    return $SkillCredentialDefinitionsTable(attachedDatabase, alias);
  }
}

class SkillCredentialDefinitionsTable extends DataClass
    implements Insertable<SkillCredentialDefinitionsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String workspaceId;
  final String title;
  final String slug;
  final String attributesJson;
  const SkillCredentialDefinitionsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    required this.title,
    required this.slug,
    required this.attributesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    map['slug'] = Variable<String>(slug);
    map['attributes_json'] = Variable<String>(attributesJson);
    return map;
  }

  SkillCredentialDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return SkillCredentialDefinitionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      title: Value(title),
      slug: Value(slug),
      attributesJson: Value(attributesJson),
    );
  }

  factory SkillCredentialDefinitionsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkillCredentialDefinitionsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      title: serializer.fromJson<String>(json['title']),
      slug: serializer.fromJson<String>(json['slug']),
      attributesJson: serializer.fromJson<String>(json['attributesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'slug': serializer.toJson<String>(slug),
      'attributesJson': serializer.toJson<String>(attributesJson),
    };
  }

  SkillCredentialDefinitionsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    String? title,
    String? slug,
    String? attributesJson,
  }) => SkillCredentialDefinitionsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    slug: slug ?? this.slug,
    attributesJson: attributesJson ?? this.attributesJson,
  );
  SkillCredentialDefinitionsTable copyWithCompanion(
    SkillCredentialDefinitionsCompanion data,
  ) {
    return SkillCredentialDefinitionsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      slug: data.slug.present ? data.slug.value : this.slug,
      attributesJson: data.attributesJson.present
          ? data.attributesJson.value
          : this.attributesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkillCredentialDefinitionsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('attributesJson: $attributesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    title,
    slug,
    attributesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkillCredentialDefinitionsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.slug == this.slug &&
          other.attributesJson == this.attributesJson);
}

class SkillCredentialDefinitionsCompanion
    extends UpdateCompanion<SkillCredentialDefinitionsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String> slug;
  final Value<String> attributesJson;
  final Value<int> rowid;
  const SkillCredentialDefinitionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.slug = const Value.absent(),
    this.attributesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkillCredentialDefinitionsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    required String title,
    required String slug,
    required String attributesJson,
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       title = Value(title),
       slug = Value(slug),
       attributesJson = Value(attributesJson);
  static Insertable<SkillCredentialDefinitionsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? slug,
    Expression<String>? attributesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (slug != null) 'slug': slug,
      if (attributesJson != null) 'attributes_json': attributesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkillCredentialDefinitionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String>? slug,
    Value<String>? attributesJson,
    Value<int>? rowid,
  }) {
    return SkillCredentialDefinitionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      attributesJson: attributesJson ?? this.attributesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (attributesJson.present) {
      map['attributes_json'] = Variable<String>(attributesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkillCredentialDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SkillsTable extends Skills with TableInfo<$SkillsTable, SkillsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkillSourceTable, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillSourceTable>($SkillsTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<SkillKindTable, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillKindTable>($SkillsTable.$converterkind);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialDefinitionIdMeta =
      const VerificationMeta('credentialDefinitionId');
  @override
  late final GeneratedColumn<String> credentialDefinitionId =
      GeneratedColumn<String>(
        'credential_definition_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES skill_credential_definitions (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _isCredentialOptionalMeta =
      const VerificationMeta('isCredentialOptional');
  @override
  late final GeneratedColumn<bool> isCredentialOptional = GeneratedColumn<bool>(
    'is_credential_optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_credential_optional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    source,
    kind,
    title,
    slug,
    description,
    content,
    credentialDefinitionId,
    isCredentialOptional,
    isEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skills';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkillsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('credential_definition_id')) {
      context.handle(
        _credentialDefinitionIdMeta,
        credentialDefinitionId.isAcceptableOrUnknown(
          data['credential_definition_id']!,
          _credentialDefinitionIdMeta,
        ),
      );
    }
    if (data.containsKey('is_credential_optional')) {
      context.handle(
        _isCredentialOptionalMeta,
        isCredentialOptional.isAcceptableOrUnknown(
          data['is_credential_optional']!,
          _isCredentialOptionalMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, title},
    {workspaceId, slug},
  ];
  @override
  SkillsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkillsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      source: $SkillsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      kind: $SkillsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      credentialDefinitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_definition_id'],
      ),
      isCredentialOptional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_credential_optional'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
    );
  }

  @override
  $SkillsTable createAlias(String alias) {
    return $SkillsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SkillSourceTable, String, String> $convertersource =
      const EnumNameConverter<SkillSourceTable>(SkillSourceTable.values);
  static JsonTypeConverter2<SkillKindTable, String, String> $converterkind =
      const EnumNameConverter<SkillKindTable>(SkillKindTable.values);
}

class SkillsTable extends DataClass implements Insertable<SkillsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String workspaceId;
  final SkillSourceTable source;
  final SkillKindTable kind;
  final String title;
  final String slug;
  final String description;
  final String content;
  final String? credentialDefinitionId;
  final bool isCredentialOptional;
  final bool isEnabled;
  const SkillsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    required this.source,
    required this.kind,
    required this.title,
    required this.slug,
    required this.description,
    required this.content,
    this.credentialDefinitionId,
    required this.isCredentialOptional,
    required this.isEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    {
      map['source'] = Variable<String>(
        $SkillsTable.$convertersource.toSql(source),
      );
    }
    {
      map['kind'] = Variable<String>($SkillsTable.$converterkind.toSql(kind));
    }
    map['title'] = Variable<String>(title);
    map['slug'] = Variable<String>(slug);
    map['description'] = Variable<String>(description);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || credentialDefinitionId != null) {
      map['credential_definition_id'] = Variable<String>(
        credentialDefinitionId,
      );
    }
    map['is_credential_optional'] = Variable<bool>(isCredentialOptional);
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  SkillsCompanion toCompanion(bool nullToAbsent) {
    return SkillsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      source: Value(source),
      kind: Value(kind),
      title: Value(title),
      slug: Value(slug),
      description: Value(description),
      content: Value(content),
      credentialDefinitionId: credentialDefinitionId == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialDefinitionId),
      isCredentialOptional: Value(isCredentialOptional),
      isEnabled: Value(isEnabled),
    );
  }

  factory SkillsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkillsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      source: $SkillsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      kind: $SkillsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      title: serializer.fromJson<String>(json['title']),
      slug: serializer.fromJson<String>(json['slug']),
      description: serializer.fromJson<String>(json['description']),
      content: serializer.fromJson<String>(json['content']),
      credentialDefinitionId: serializer.fromJson<String?>(
        json['credentialDefinitionId'],
      ),
      isCredentialOptional: serializer.fromJson<bool>(
        json['isCredentialOptional'],
      ),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'source': serializer.toJson<String>(
        $SkillsTable.$convertersource.toJson(source),
      ),
      'kind': serializer.toJson<String>(
        $SkillsTable.$converterkind.toJson(kind),
      ),
      'title': serializer.toJson<String>(title),
      'slug': serializer.toJson<String>(slug),
      'description': serializer.toJson<String>(description),
      'content': serializer.toJson<String>(content),
      'credentialDefinitionId': serializer.toJson<String?>(
        credentialDefinitionId,
      ),
      'isCredentialOptional': serializer.toJson<bool>(isCredentialOptional),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  SkillsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    SkillSourceTable? source,
    SkillKindTable? kind,
    String? title,
    String? slug,
    String? description,
    String? content,
    Value<String?> credentialDefinitionId = const Value.absent(),
    bool? isCredentialOptional,
    bool? isEnabled,
  }) => SkillsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    source: source ?? this.source,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    slug: slug ?? this.slug,
    description: description ?? this.description,
    content: content ?? this.content,
    credentialDefinitionId: credentialDefinitionId.present
        ? credentialDefinitionId.value
        : this.credentialDefinitionId,
    isCredentialOptional: isCredentialOptional ?? this.isCredentialOptional,
    isEnabled: isEnabled ?? this.isEnabled,
  );
  SkillsTable copyWithCompanion(SkillsCompanion data) {
    return SkillsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      source: data.source.present ? data.source.value : this.source,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      slug: data.slug.present ? data.slug.value : this.slug,
      description: data.description.present
          ? data.description.value
          : this.description,
      content: data.content.present ? data.content.value : this.content,
      credentialDefinitionId: data.credentialDefinitionId.present
          ? data.credentialDefinitionId.value
          : this.credentialDefinitionId,
      isCredentialOptional: data.isCredentialOptional.present
          ? data.isCredentialOptional.value
          : this.isCredentialOptional,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkillsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('source: $source, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('credentialDefinitionId: $credentialDefinitionId, ')
          ..write('isCredentialOptional: $isCredentialOptional, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    source,
    kind,
    title,
    slug,
    description,
    content,
    credentialDefinitionId,
    isCredentialOptional,
    isEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkillsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.source == this.source &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.slug == this.slug &&
          other.description == this.description &&
          other.content == this.content &&
          other.credentialDefinitionId == this.credentialDefinitionId &&
          other.isCredentialOptional == this.isCredentialOptional &&
          other.isEnabled == this.isEnabled);
}

class SkillsCompanion extends UpdateCompanion<SkillsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<SkillSourceTable> source;
  final Value<SkillKindTable> kind;
  final Value<String> title;
  final Value<String> slug;
  final Value<String> description;
  final Value<String> content;
  final Value<String?> credentialDefinitionId;
  final Value<bool> isCredentialOptional;
  final Value<bool> isEnabled;
  final Value<int> rowid;
  const SkillsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.source = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.slug = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.credentialDefinitionId = const Value.absent(),
    this.isCredentialOptional = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkillsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    required SkillSourceTable source,
    required SkillKindTable kind,
    required String title,
    required String slug,
    required String description,
    required String content,
    this.credentialDefinitionId = const Value.absent(),
    this.isCredentialOptional = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       source = Value(source),
       kind = Value(kind),
       title = Value(title),
       slug = Value(slug),
       description = Value(description),
       content = Value(content);
  static Insertable<SkillsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<String>? source,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? slug,
    Expression<String>? description,
    Expression<String>? content,
    Expression<String>? credentialDefinitionId,
    Expression<bool>? isCredentialOptional,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (source != null) 'source': source,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (slug != null) 'slug': slug,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (credentialDefinitionId != null)
        'credential_definition_id': credentialDefinitionId,
      if (isCredentialOptional != null)
        'is_credential_optional': isCredentialOptional,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkillsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<SkillSourceTable>? source,
    Value<SkillKindTable>? kind,
    Value<String>? title,
    Value<String>? slug,
    Value<String>? description,
    Value<String>? content,
    Value<String?>? credentialDefinitionId,
    Value<bool>? isCredentialOptional,
    Value<bool>? isEnabled,
    Value<int>? rowid,
  }) {
    return SkillsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      source: source ?? this.source,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      content: content ?? this.content,
      credentialDefinitionId:
          credentialDefinitionId ?? this.credentialDefinitionId,
      isCredentialOptional: isCredentialOptional ?? this.isCredentialOptional,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $SkillsTable.$convertersource.toSql(source.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SkillsTable.$converterkind.toSql(kind.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (credentialDefinitionId.present) {
      map['credential_definition_id'] = Variable<String>(
        credentialDefinitionId.value,
      );
    }
    if (isCredentialOptional.present) {
      map['is_credential_optional'] = Variable<bool>(
        isCredentialOptional.value,
      );
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkillsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('source: $source, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('credentialDefinitionId: $credentialDefinitionId, ')
          ..write('isCredentialOptional: $isCredentialOptional, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SkillTemplateToolsTable extends SkillTemplateTools
    with TableInfo<$SkillTemplateToolsTable, SkillTemplateToolsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillTemplateToolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES skills (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    SkillTemplateToolTypeTable,
    String
  >
  templateType =
      GeneratedColumn<String>(
        'template_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillTemplateToolTypeTable>(
        $SkillTemplateToolsTable.$convertertemplateType,
      );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateJsonMeta = const VerificationMeta(
    'templateJson',
  );
  @override
  late final GeneratedColumn<String> templateJson = GeneratedColumn<String>(
    'template_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputsJsonMeta = const VerificationMeta(
    'inputsJson',
  );
  @override
  late final GeneratedColumn<String> inputsJson = GeneratedColumn<String>(
    'inputs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiresCredentialMeta =
      const VerificationMeta('requiresCredential');
  @override
  late final GeneratedColumn<bool> requiresCredential = GeneratedColumn<bool>(
    'requires_credential',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_credential" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    skillId,
    templateType,
    title,
    description,
    slug,
    templateJson,
    inputsJson,
    requiresCredential,
    isEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skill_template_tools';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkillTemplateToolsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('template_json')) {
      context.handle(
        _templateJsonMeta,
        templateJson.isAcceptableOrUnknown(
          data['template_json']!,
          _templateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateJsonMeta);
    }
    if (data.containsKey('inputs_json')) {
      context.handle(
        _inputsJsonMeta,
        inputsJson.isAcceptableOrUnknown(data['inputs_json']!, _inputsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_inputsJsonMeta);
    }
    if (data.containsKey('requires_credential')) {
      context.handle(
        _requiresCredentialMeta,
        requiresCredential.isAcceptableOrUnknown(
          data['requires_credential']!,
          _requiresCredentialMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {skillId, title},
    {skillId, slug},
  ];
  @override
  SkillTemplateToolsTable map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkillTemplateToolsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      )!,
      templateType: $SkillTemplateToolsTable.$convertertemplateType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}template_type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      templateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_json'],
      )!,
      inputsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inputs_json'],
      )!,
      requiresCredential: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_credential'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
    );
  }

  @override
  $SkillTemplateToolsTable createAlias(String alias) {
    return $SkillTemplateToolsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SkillTemplateToolTypeTable, String, String>
  $convertertemplateType = const EnumNameConverter<SkillTemplateToolTypeTable>(
    SkillTemplateToolTypeTable.values,
  );
}

class SkillTemplateToolsTable extends DataClass
    implements Insertable<SkillTemplateToolsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String skillId;
  final SkillTemplateToolTypeTable templateType;
  final String title;
  final String description;
  final String slug;
  final String templateJson;
  final String inputsJson;
  final bool requiresCredential;
  final bool isEnabled;
  const SkillTemplateToolsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.skillId,
    required this.templateType,
    required this.title,
    required this.description,
    required this.slug,
    required this.templateJson,
    required this.inputsJson,
    required this.requiresCredential,
    required this.isEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['skill_id'] = Variable<String>(skillId);
    {
      map['template_type'] = Variable<String>(
        $SkillTemplateToolsTable.$convertertemplateType.toSql(templateType),
      );
    }
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['slug'] = Variable<String>(slug);
    map['template_json'] = Variable<String>(templateJson);
    map['inputs_json'] = Variable<String>(inputsJson);
    map['requires_credential'] = Variable<bool>(requiresCredential);
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  SkillTemplateToolsCompanion toCompanion(bool nullToAbsent) {
    return SkillTemplateToolsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      skillId: Value(skillId),
      templateType: Value(templateType),
      title: Value(title),
      description: Value(description),
      slug: Value(slug),
      templateJson: Value(templateJson),
      inputsJson: Value(inputsJson),
      requiresCredential: Value(requiresCredential),
      isEnabled: Value(isEnabled),
    );
  }

  factory SkillTemplateToolsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkillTemplateToolsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      skillId: serializer.fromJson<String>(json['skillId']),
      templateType: $SkillTemplateToolsTable.$convertertemplateType.fromJson(
        serializer.fromJson<String>(json['templateType']),
      ),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      slug: serializer.fromJson<String>(json['slug']),
      templateJson: serializer.fromJson<String>(json['templateJson']),
      inputsJson: serializer.fromJson<String>(json['inputsJson']),
      requiresCredential: serializer.fromJson<bool>(json['requiresCredential']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'skillId': serializer.toJson<String>(skillId),
      'templateType': serializer.toJson<String>(
        $SkillTemplateToolsTable.$convertertemplateType.toJson(templateType),
      ),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'slug': serializer.toJson<String>(slug),
      'templateJson': serializer.toJson<String>(templateJson),
      'inputsJson': serializer.toJson<String>(inputsJson),
      'requiresCredential': serializer.toJson<bool>(requiresCredential),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  SkillTemplateToolsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? skillId,
    SkillTemplateToolTypeTable? templateType,
    String? title,
    String? description,
    String? slug,
    String? templateJson,
    String? inputsJson,
    bool? requiresCredential,
    bool? isEnabled,
  }) => SkillTemplateToolsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    skillId: skillId ?? this.skillId,
    templateType: templateType ?? this.templateType,
    title: title ?? this.title,
    description: description ?? this.description,
    slug: slug ?? this.slug,
    templateJson: templateJson ?? this.templateJson,
    inputsJson: inputsJson ?? this.inputsJson,
    requiresCredential: requiresCredential ?? this.requiresCredential,
    isEnabled: isEnabled ?? this.isEnabled,
  );
  SkillTemplateToolsTable copyWithCompanion(SkillTemplateToolsCompanion data) {
    return SkillTemplateToolsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      templateType: data.templateType.present
          ? data.templateType.value
          : this.templateType,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      slug: data.slug.present ? data.slug.value : this.slug,
      templateJson: data.templateJson.present
          ? data.templateJson.value
          : this.templateJson,
      inputsJson: data.inputsJson.present
          ? data.inputsJson.value
          : this.inputsJson,
      requiresCredential: data.requiresCredential.present
          ? data.requiresCredential.value
          : this.requiresCredential,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkillTemplateToolsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('skillId: $skillId, ')
          ..write('templateType: $templateType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('slug: $slug, ')
          ..write('templateJson: $templateJson, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('requiresCredential: $requiresCredential, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    skillId,
    templateType,
    title,
    description,
    slug,
    templateJson,
    inputsJson,
    requiresCredential,
    isEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkillTemplateToolsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.skillId == this.skillId &&
          other.templateType == this.templateType &&
          other.title == this.title &&
          other.description == this.description &&
          other.slug == this.slug &&
          other.templateJson == this.templateJson &&
          other.inputsJson == this.inputsJson &&
          other.requiresCredential == this.requiresCredential &&
          other.isEnabled == this.isEnabled);
}

class SkillTemplateToolsCompanion
    extends UpdateCompanion<SkillTemplateToolsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> skillId;
  final Value<SkillTemplateToolTypeTable> templateType;
  final Value<String> title;
  final Value<String> description;
  final Value<String> slug;
  final Value<String> templateJson;
  final Value<String> inputsJson;
  final Value<bool> requiresCredential;
  final Value<bool> isEnabled;
  final Value<int> rowid;
  const SkillTemplateToolsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.skillId = const Value.absent(),
    this.templateType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.slug = const Value.absent(),
    this.templateJson = const Value.absent(),
    this.inputsJson = const Value.absent(),
    this.requiresCredential = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkillTemplateToolsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String skillId,
    required SkillTemplateToolTypeTable templateType,
    required String title,
    this.description = const Value.absent(),
    required String slug,
    required String templateJson,
    required String inputsJson,
    this.requiresCredential = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : skillId = Value(skillId),
       templateType = Value(templateType),
       title = Value(title),
       slug = Value(slug),
       templateJson = Value(templateJson),
       inputsJson = Value(inputsJson);
  static Insertable<SkillTemplateToolsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? skillId,
    Expression<String>? templateType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? slug,
    Expression<String>? templateJson,
    Expression<String>? inputsJson,
    Expression<bool>? requiresCredential,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (skillId != null) 'skill_id': skillId,
      if (templateType != null) 'template_type': templateType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (slug != null) 'slug': slug,
      if (templateJson != null) 'template_json': templateJson,
      if (inputsJson != null) 'inputs_json': inputsJson,
      if (requiresCredential != null) 'requires_credential': requiresCredential,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkillTemplateToolsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? skillId,
    Value<SkillTemplateToolTypeTable>? templateType,
    Value<String>? title,
    Value<String>? description,
    Value<String>? slug,
    Value<String>? templateJson,
    Value<String>? inputsJson,
    Value<bool>? requiresCredential,
    Value<bool>? isEnabled,
    Value<int>? rowid,
  }) {
    return SkillTemplateToolsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skillId: skillId ?? this.skillId,
      templateType: templateType ?? this.templateType,
      title: title ?? this.title,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      templateJson: templateJson ?? this.templateJson,
      inputsJson: inputsJson ?? this.inputsJson,
      requiresCredential: requiresCredential ?? this.requiresCredential,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (templateType.present) {
      map['template_type'] = Variable<String>(
        $SkillTemplateToolsTable.$convertertemplateType.toSql(
          templateType.value,
        ),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (templateJson.present) {
      map['template_json'] = Variable<String>(templateJson.value);
    }
    if (inputsJson.present) {
      map['inputs_json'] = Variable<String>(inputsJson.value);
    }
    if (requiresCredential.present) {
      map['requires_credential'] = Variable<bool>(requiresCredential.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkillTemplateToolsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('skillId: $skillId, ')
          ..write('templateType: $templateType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('slug: $slug, ')
          ..write('templateJson: $templateJson, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('requiresCredential: $requiresCredential, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationSkillsTable extends ConversationSkills
    with TableInfo<$ConversationSkillsTable, ConversationSkillsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationSkillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _workspaceSkillIdMeta = const VerificationMeta(
    'workspaceSkillId',
  );
  @override
  late final GeneratedColumn<String> workspaceSkillId = GeneratedColumn<String>(
    'workspace_skill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES skills (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _appSkillIdentifierMeta =
      const VerificationMeta('appSkillIdentifier');
  @override
  late final GeneratedColumn<String> appSkillIdentifier =
      GeneratedColumn<String>(
        'app_skill_identifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isLoadedMeta = const VerificationMeta(
    'isLoaded',
  );
  @override
  late final GeneratedColumn<bool> isLoaded = GeneratedColumn<bool>(
    'is_loaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_loaded" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    conversationId,
    workspaceSkillId,
    appSkillIdentifier,
    isLoaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_skills';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationSkillsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('workspace_skill_id')) {
      context.handle(
        _workspaceSkillIdMeta,
        workspaceSkillId.isAcceptableOrUnknown(
          data['workspace_skill_id']!,
          _workspaceSkillIdMeta,
        ),
      );
    }
    if (data.containsKey('app_skill_identifier')) {
      context.handle(
        _appSkillIdentifierMeta,
        appSkillIdentifier.isAcceptableOrUnknown(
          data['app_skill_identifier']!,
          _appSkillIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('is_loaded')) {
      context.handle(
        _isLoadedMeta,
        isLoaded.isAcceptableOrUnknown(data['is_loaded']!, _isLoadedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ConversationSkillsTable map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationSkillsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      workspaceSkillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_skill_id'],
      ),
      appSkillIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_skill_identifier'],
      ),
      isLoaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_loaded'],
      )!,
    );
  }

  @override
  $ConversationSkillsTable createAlias(String alias) {
    return $ConversationSkillsTable(attachedDatabase, alias);
  }
}

class ConversationSkillsTable extends DataClass
    implements Insertable<ConversationSkillsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String conversationId;
  final String? workspaceSkillId;
  final String? appSkillIdentifier;
  final bool isLoaded;
  const ConversationSkillsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.conversationId,
    this.workspaceSkillId,
    this.appSkillIdentifier,
    required this.isLoaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['conversation_id'] = Variable<String>(conversationId);
    if (!nullToAbsent || workspaceSkillId != null) {
      map['workspace_skill_id'] = Variable<String>(workspaceSkillId);
    }
    if (!nullToAbsent || appSkillIdentifier != null) {
      map['app_skill_identifier'] = Variable<String>(appSkillIdentifier);
    }
    map['is_loaded'] = Variable<bool>(isLoaded);
    return map;
  }

  ConversationSkillsCompanion toCompanion(bool nullToAbsent) {
    return ConversationSkillsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      conversationId: Value(conversationId),
      workspaceSkillId: workspaceSkillId == null && nullToAbsent
          ? const Value.absent()
          : Value(workspaceSkillId),
      appSkillIdentifier: appSkillIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(appSkillIdentifier),
      isLoaded: Value(isLoaded),
    );
  }

  factory ConversationSkillsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationSkillsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      workspaceSkillId: serializer.fromJson<String?>(json['workspaceSkillId']),
      appSkillIdentifier: serializer.fromJson<String?>(
        json['appSkillIdentifier'],
      ),
      isLoaded: serializer.fromJson<bool>(json['isLoaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'conversationId': serializer.toJson<String>(conversationId),
      'workspaceSkillId': serializer.toJson<String?>(workspaceSkillId),
      'appSkillIdentifier': serializer.toJson<String?>(appSkillIdentifier),
      'isLoaded': serializer.toJson<bool>(isLoaded),
    };
  }

  ConversationSkillsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? conversationId,
    Value<String?> workspaceSkillId = const Value.absent(),
    Value<String?> appSkillIdentifier = const Value.absent(),
    bool? isLoaded,
  }) => ConversationSkillsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    conversationId: conversationId ?? this.conversationId,
    workspaceSkillId: workspaceSkillId.present
        ? workspaceSkillId.value
        : this.workspaceSkillId,
    appSkillIdentifier: appSkillIdentifier.present
        ? appSkillIdentifier.value
        : this.appSkillIdentifier,
    isLoaded: isLoaded ?? this.isLoaded,
  );
  ConversationSkillsTable copyWithCompanion(ConversationSkillsCompanion data) {
    return ConversationSkillsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      workspaceSkillId: data.workspaceSkillId.present
          ? data.workspaceSkillId.value
          : this.workspaceSkillId,
      appSkillIdentifier: data.appSkillIdentifier.present
          ? data.appSkillIdentifier.value
          : this.appSkillIdentifier,
      isLoaded: data.isLoaded.present ? data.isLoaded.value : this.isLoaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationSkillsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('workspaceSkillId: $workspaceSkillId, ')
          ..write('appSkillIdentifier: $appSkillIdentifier, ')
          ..write('isLoaded: $isLoaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    conversationId,
    workspaceSkillId,
    appSkillIdentifier,
    isLoaded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationSkillsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.conversationId == this.conversationId &&
          other.workspaceSkillId == this.workspaceSkillId &&
          other.appSkillIdentifier == this.appSkillIdentifier &&
          other.isLoaded == this.isLoaded);
}

class ConversationSkillsCompanion
    extends UpdateCompanion<ConversationSkillsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> conversationId;
  final Value<String?> workspaceSkillId;
  final Value<String?> appSkillIdentifier;
  final Value<bool> isLoaded;
  final Value<int> rowid;
  const ConversationSkillsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.workspaceSkillId = const Value.absent(),
    this.appSkillIdentifier = const Value.absent(),
    this.isLoaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationSkillsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String conversationId,
    this.workspaceSkillId = const Value.absent(),
    this.appSkillIdentifier = const Value.absent(),
    this.isLoaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId);
  static Insertable<ConversationSkillsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? conversationId,
    Expression<String>? workspaceSkillId,
    Expression<String>? appSkillIdentifier,
    Expression<bool>? isLoaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (conversationId != null) 'conversation_id': conversationId,
      if (workspaceSkillId != null) 'workspace_skill_id': workspaceSkillId,
      if (appSkillIdentifier != null)
        'app_skill_identifier': appSkillIdentifier,
      if (isLoaded != null) 'is_loaded': isLoaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationSkillsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? conversationId,
    Value<String?>? workspaceSkillId,
    Value<String?>? appSkillIdentifier,
    Value<bool>? isLoaded,
    Value<int>? rowid,
  }) {
    return ConversationSkillsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      conversationId: conversationId ?? this.conversationId,
      workspaceSkillId: workspaceSkillId ?? this.workspaceSkillId,
      appSkillIdentifier: appSkillIdentifier ?? this.appSkillIdentifier,
      isLoaded: isLoaded ?? this.isLoaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (workspaceSkillId.present) {
      map['workspace_skill_id'] = Variable<String>(workspaceSkillId.value);
    }
    if (appSkillIdentifier.present) {
      map['app_skill_identifier'] = Variable<String>(appSkillIdentifier.value);
    }
    if (isLoaded.present) {
      map['is_loaded'] = Variable<bool>(isLoaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationSkillsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('workspaceSkillId: $workspaceSkillId, ')
          ..write('appSkillIdentifier: $appSkillIdentifier, ')
          ..write('isLoaded: $isLoaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSkillWorkspaceSettingsTable extends AppSkillWorkspaceSettings
    with
        TableInfo<
          $AppSkillWorkspaceSettingsTable,
          AppSkillWorkspaceSettingsTable
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSkillWorkspaceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const UuidV7().generate(),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _appSkillIdentifierMeta =
      const VerificationMeta('appSkillIdentifier');
  @override
  late final GeneratedColumn<String> appSkillIdentifier =
      GeneratedColumn<String>(
        'app_skill_identifier',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    workspaceId,
    appSkillIdentifier,
    isEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_skill_workspace_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSkillWorkspaceSettingsTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('app_skill_identifier')) {
      context.handle(
        _appSkillIdentifierMeta,
        appSkillIdentifier.isAcceptableOrUnknown(
          data['app_skill_identifier']!,
          _appSkillIdentifierMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appSkillIdentifierMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AppSkillWorkspaceSettingsTable map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSkillWorkspaceSettingsTable(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      appSkillIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_skill_identifier'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
    );
  }

  @override
  $AppSkillWorkspaceSettingsTable createAlias(String alias) {
    return $AppSkillWorkspaceSettingsTable(attachedDatabase, alias);
  }
}

class AppSkillWorkspaceSettingsTable extends DataClass
    implements Insertable<AppSkillWorkspaceSettingsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;
  final String workspaceId;
  final String appSkillIdentifier;
  final bool isEnabled;
  const AppSkillWorkspaceSettingsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    required this.appSkillIdentifier,
    required this.isEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['app_skill_identifier'] = Variable<String>(appSkillIdentifier);
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  AppSkillWorkspaceSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSkillWorkspaceSettingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      workspaceId: Value(workspaceId),
      appSkillIdentifier: Value(appSkillIdentifier),
      isEnabled: Value(isEnabled),
    );
  }

  factory AppSkillWorkspaceSettingsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSkillWorkspaceSettingsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      appSkillIdentifier: serializer.fromJson<String>(
        json['appSkillIdentifier'],
      ),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'appSkillIdentifier': serializer.toJson<String>(appSkillIdentifier),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  AppSkillWorkspaceSettingsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
    String? appSkillIdentifier,
    bool? isEnabled,
  }) => AppSkillWorkspaceSettingsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    workspaceId: workspaceId ?? this.workspaceId,
    appSkillIdentifier: appSkillIdentifier ?? this.appSkillIdentifier,
    isEnabled: isEnabled ?? this.isEnabled,
  );
  AppSkillWorkspaceSettingsTable copyWithCompanion(
    AppSkillWorkspaceSettingsCompanion data,
  ) {
    return AppSkillWorkspaceSettingsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      appSkillIdentifier: data.appSkillIdentifier.present
          ? data.appSkillIdentifier.value
          : this.appSkillIdentifier,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSkillWorkspaceSettingsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('appSkillIdentifier: $appSkillIdentifier, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    workspaceId,
    appSkillIdentifier,
    isEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSkillWorkspaceSettingsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.workspaceId == this.workspaceId &&
          other.appSkillIdentifier == this.appSkillIdentifier &&
          other.isEnabled == this.isEnabled);
}

class AppSkillWorkspaceSettingsCompanion
    extends UpdateCompanion<AppSkillWorkspaceSettingsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> workspaceId;
  final Value<String> appSkillIdentifier;
  final Value<bool> isEnabled;
  final Value<int> rowid;
  const AppSkillWorkspaceSettingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.appSkillIdentifier = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSkillWorkspaceSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workspaceId,
    required String appSkillIdentifier,
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workspaceId = Value(workspaceId),
       appSkillIdentifier = Value(appSkillIdentifier);
  static Insertable<AppSkillWorkspaceSettingsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? workspaceId,
    Expression<String>? appSkillIdentifier,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (appSkillIdentifier != null)
        'app_skill_identifier': appSkillIdentifier,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSkillWorkspaceSettingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? workspaceId,
    Value<String>? appSkillIdentifier,
    Value<bool>? isEnabled,
    Value<int>? rowid,
  }) {
    return AppSkillWorkspaceSettingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
      appSkillIdentifier: appSkillIdentifier ?? this.appSkillIdentifier,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (appSkillIdentifier.present) {
      map['app_skill_identifier'] = Variable<String>(appSkillIdentifier.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSkillWorkspaceSettingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('appSkillIdentifier: $appSkillIdentifier, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $ServiceConnectionsTable serviceConnections =
      $ServiceConnectionsTable(this);
  late final $ApiModelProvidersTable apiModelProviders =
      $ApiModelProvidersTable(this);
  late final $WorkspaceModelSelectionsTable workspaceModelSelections =
      $WorkspaceModelSelectionsTable(this);
  late final $ApiModelsTable apiModels = $ApiModelsTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $McpServersTable mcpServers = $McpServersTable(this);
  late final $ToolsGroupsTable toolsGroups = $ToolsGroupsTable(this);
  late final $ToolsTable tools = $ToolsTable(this);
  late final $ConversationToolsTable conversationTools =
      $ConversationToolsTable(this);
  late final $WorkspaceCompactionSettingsTable workspaceCompactionSettings =
      $WorkspaceCompactionSettingsTable(this);
  late final $SkillCredentialDefinitionsTable skillCredentialDefinitions =
      $SkillCredentialDefinitionsTable(this);
  late final $SkillsTable skills = $SkillsTable(this);
  late final $SkillTemplateToolsTable skillTemplateTools =
      $SkillTemplateToolsTable(this);
  late final $ConversationSkillsTable conversationSkills =
      $ConversationSkillsTable(this);
  late final $AppSkillWorkspaceSettingsTable appSkillWorkspaceSettings =
      $AppSkillWorkspaceSettingsTable(this);
  late final WorkspaceDao workspaceDao = WorkspaceDao(this as AppDatabase);
  late final ModelConnectionsDao modelConnectionsDao = ModelConnectionsDao(
    this as AppDatabase,
  );
  late final WorkspaceModelSelectionsDao workspaceModelSelectionsDao =
      WorkspaceModelSelectionsDao(this as AppDatabase);
  late final ApiModelProvidersDao apiModelProvidersDao = ApiModelProvidersDao(
    this as AppDatabase,
  );
  late final ApiModelsDao apiModelsDao = ApiModelsDao(this as AppDatabase);
  late final ConversationDao conversationDao = ConversationDao(
    this as AppDatabase,
  );
  late final MessageDao messageDao = MessageDao(this as AppDatabase);
  late final WorkspaceToolsDao workspaceToolsDao = WorkspaceToolsDao(
    this as AppDatabase,
  );
  late final ToolsGroupsDao toolsGroupsDao = ToolsGroupsDao(
    this as AppDatabase,
  );
  late final ConversationToolsDao conversationToolsDao = ConversationToolsDao(
    this as AppDatabase,
  );
  late final McpServersDao mcpServersDao = McpServersDao(this as AppDatabase);
  late final WorkspaceCompactionSettingsDao workspaceCompactionSettingsDao =
      WorkspaceCompactionSettingsDao(this as AppDatabase);
  late final SkillCredentialsDao skillCredentialsDao = SkillCredentialsDao(
    this as AppDatabase,
  );
  late final SkillCredentialDefinitionsDao skillCredentialDefinitionsDao =
      SkillCredentialDefinitionsDao(this as AppDatabase);
  late final SkillsDao skillsDao = SkillsDao(this as AppDatabase);
  late final SkillTemplateToolsDao skillTemplateToolsDao =
      SkillTemplateToolsDao(this as AppDatabase);
  late final ConversationSkillsDao conversationSkillsDao =
      ConversationSkillsDao(this as AppDatabase);
  late final AppSkillWorkspaceSettingsDao appSkillWorkspaceSettingsDao =
      AppSkillWorkspaceSettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    serviceConnections,
    apiModelProviders,
    workspaceModelSelections,
    apiModels,
    conversations,
    messages,
    mcpServers,
    toolsGroups,
    tools,
    conversationTools,
    workspaceCompactionSettings,
    skillCredentialDefinitions,
    skills,
    skillTemplateTools,
    conversationSkills,
    appSkillWorkspaceSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('service_connections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'service_connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('workspace_model_selections', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('mcp_servers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tools_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mcp_servers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tools_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tools', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tools_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tools', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_tools', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tools',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_tools', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('workspace_compaction_settings', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('skill_credential_definitions', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('skills', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'skill_credential_definitions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('skills', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'skills',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('skill_template_tools', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_skills', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'skills',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversation_skills', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('app_skill_workspace_settings', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$WorkspacesTableCreateCompanionBuilder =
    WorkspacesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String name,
      required WorkspaceType type,
      Value<String?> url,
      Value<int> rowid,
    });
typedef $$WorkspacesTableUpdateCompanionBuilder =
    WorkspacesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> name,
      Value<WorkspaceType> type,
      Value<String?> url,
      Value<int> rowid,
    });

final class $$WorkspacesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkspacesTable, WorkspacesTable> {
  $$WorkspacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ServiceConnectionsTable,
    List<ServiceConnectionTable>
  >
  _serviceConnectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.serviceConnections,
        aliasName: $_aliasNameGenerator(
          db.workspaces.id,
          db.serviceConnections.workspaceId,
        ),
      );

  $$ServiceConnectionsTableProcessedTableManager get serviceConnectionsRefs {
    final manager = $$ServiceConnectionsTableTableManager(
      $_db,
      $_db.serviceConnections,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _serviceConnectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConversationsTable, List<ConversationsTable>>
  _conversationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.conversations,
    aliasName: $_aliasNameGenerator(
      db.workspaces.id,
      db.conversations.workspaceId,
    ),
  );

  $$ConversationsTableProcessedTableManager get conversationsRefs {
    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_conversationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$McpServersTable, List<McpServersTable>>
  _mcpServersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mcpServers,
    aliasName: $_aliasNameGenerator(
      db.workspaces.id,
      db.mcpServers.workspaceId,
    ),
  );

  $$McpServersTableProcessedTableManager get mcpServersRefs {
    final manager = $$McpServersTableTableManager(
      $_db,
      $_db.mcpServers,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mcpServersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ToolsGroupsTable, List<ToolsGroupsTable>>
  _toolsGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.toolsGroups,
    aliasName: $_aliasNameGenerator(
      db.workspaces.id,
      db.toolsGroups.workspaceId,
    ),
  );

  $$ToolsGroupsTableProcessedTableManager get toolsGroupsRefs {
    final manager = $$ToolsGroupsTableTableManager(
      $_db,
      $_db.toolsGroups,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_toolsGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ToolsTable, List<ToolsTable>> _toolsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tools,
    aliasName: $_aliasNameGenerator(db.workspaces.id, db.tools.workspaceId),
  );

  $$ToolsTableProcessedTableManager get toolsRefs {
    final manager = $$ToolsTableTableManager(
      $_db,
      $_db.tools,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_toolsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $WorkspaceCompactionSettingsTable,
    List<WorkspaceCompactionSettingsTable>
  >
  _workspaceCompactionSettingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspaceCompactionSettings,
        aliasName: $_aliasNameGenerator(
          db.workspaces.id,
          db.workspaceCompactionSettings.workspaceId,
        ),
      );

  $$WorkspaceCompactionSettingsTableProcessedTableManager
  get workspaceCompactionSettingsRefs {
    final manager = $$WorkspaceCompactionSettingsTableTableManager(
      $_db,
      $_db.workspaceCompactionSettings,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workspaceCompactionSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $SkillCredentialDefinitionsTable,
    List<SkillCredentialDefinitionsTable>
  >
  _skillCredentialDefinitionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.skillCredentialDefinitions,
        aliasName: $_aliasNameGenerator(
          db.workspaces.id,
          db.skillCredentialDefinitions.workspaceId,
        ),
      );

  $$SkillCredentialDefinitionsTableProcessedTableManager
  get skillCredentialDefinitionsRefs {
    final manager = $$SkillCredentialDefinitionsTableTableManager(
      $_db,
      $_db.skillCredentialDefinitions,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _skillCredentialDefinitionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SkillsTable, List<SkillsTable>> _skillsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.skills,
    aliasName: $_aliasNameGenerator(db.workspaces.id, db.skills.workspaceId),
  );

  $$SkillsTableProcessedTableManager get skillsRefs {
    final manager = $$SkillsTableTableManager(
      $_db,
      $_db.skills,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_skillsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AppSkillWorkspaceSettingsTable,
    List<AppSkillWorkspaceSettingsTable>
  >
  _appSkillWorkspaceSettingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.appSkillWorkspaceSettings,
        aliasName: $_aliasNameGenerator(
          db.workspaces.id,
          db.appSkillWorkspaceSettings.workspaceId,
        ),
      );

  $$AppSkillWorkspaceSettingsTableProcessedTableManager
  get appSkillWorkspaceSettingsRefs {
    final manager = $$AppSkillWorkspaceSettingsTableTableManager(
      $_db,
      $_db.appSkillWorkspaceSettings,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _appSkillWorkspaceSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WorkspaceType, WorkspaceType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> serviceConnectionsRefs(
    Expression<bool> Function($$ServiceConnectionsTableFilterComposer f) f,
  ) {
    final $$ServiceConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.serviceConnections,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServiceConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.serviceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationsRefs(
    Expression<bool> Function($$ConversationsTableFilterComposer f) f,
  ) {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mcpServersRefs(
    Expression<bool> Function($$McpServersTableFilterComposer f) f,
  ) {
    final $$McpServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mcpServers,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$McpServersTableFilterComposer(
            $db: $db,
            $table: $db.mcpServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> toolsGroupsRefs(
    Expression<bool> Function($$ToolsGroupsTableFilterComposer f) f,
  ) {
    final $$ToolsGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.toolsGroups,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsGroupsTableFilterComposer(
            $db: $db,
            $table: $db.toolsGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> toolsRefs(
    Expression<bool> Function($$ToolsTableFilterComposer f) f,
  ) {
    final $$ToolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tools,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsTableFilterComposer(
            $db: $db,
            $table: $db.tools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workspaceCompactionSettingsRefs(
    Expression<bool> Function(
      $$WorkspaceCompactionSettingsTableFilterComposer f,
    )
    f,
  ) {
    final $$WorkspaceCompactionSettingsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workspaceCompactionSettings,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceCompactionSettingsTableFilterComposer(
                $db: $db,
                $table: $db.workspaceCompactionSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> skillCredentialDefinitionsRefs(
    Expression<bool> Function($$SkillCredentialDefinitionsTableFilterComposer f)
    f,
  ) {
    final $$SkillCredentialDefinitionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.skillCredentialDefinitions,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SkillCredentialDefinitionsTableFilterComposer(
                $db: $db,
                $table: $db.skillCredentialDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> skillsRefs(
    Expression<bool> Function($$SkillsTableFilterComposer f) f,
  ) {
    final $$SkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableFilterComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> appSkillWorkspaceSettingsRefs(
    Expression<bool> Function($$AppSkillWorkspaceSettingsTableFilterComposer f)
    f,
  ) {
    final $$AppSkillWorkspaceSettingsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.appSkillWorkspaceSettings,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AppSkillWorkspaceSettingsTableFilterComposer(
                $db: $db,
                $table: $db.appSkillWorkspaceSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkspaceType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  Expression<T> serviceConnectionsRefs<T extends Object>(
    Expression<T> Function($$ServiceConnectionsTableAnnotationComposer a) f,
  ) {
    final $$ServiceConnectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.serviceConnections,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ServiceConnectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.serviceConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> conversationsRefs<T extends Object>(
    Expression<T> Function($$ConversationsTableAnnotationComposer a) f,
  ) {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mcpServersRefs<T extends Object>(
    Expression<T> Function($$McpServersTableAnnotationComposer a) f,
  ) {
    final $$McpServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mcpServers,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$McpServersTableAnnotationComposer(
            $db: $db,
            $table: $db.mcpServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> toolsGroupsRefs<T extends Object>(
    Expression<T> Function($$ToolsGroupsTableAnnotationComposer a) f,
  ) {
    final $$ToolsGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.toolsGroups,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.toolsGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> toolsRefs<T extends Object>(
    Expression<T> Function($$ToolsTableAnnotationComposer a) f,
  ) {
    final $$ToolsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tools,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsTableAnnotationComposer(
            $db: $db,
            $table: $db.tools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workspaceCompactionSettingsRefs<T extends Object>(
    Expression<T> Function(
      $$WorkspaceCompactionSettingsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$WorkspaceCompactionSettingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workspaceCompactionSettings,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceCompactionSettingsTableAnnotationComposer(
                $db: $db,
                $table: $db.workspaceCompactionSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> skillCredentialDefinitionsRefs<T extends Object>(
    Expression<T> Function(
      $$SkillCredentialDefinitionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$SkillCredentialDefinitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.skillCredentialDefinitions,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SkillCredentialDefinitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.skillCredentialDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> skillsRefs<T extends Object>(
    Expression<T> Function($$SkillsTableAnnotationComposer a) f,
  ) {
    final $$SkillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableAnnotationComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> appSkillWorkspaceSettingsRefs<T extends Object>(
    Expression<T> Function($$AppSkillWorkspaceSettingsTableAnnotationComposer a)
    f,
  ) {
    final $$AppSkillWorkspaceSettingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.appSkillWorkspaceSettings,
          getReferencedColumn: (t) => t.workspaceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AppSkillWorkspaceSettingsTableAnnotationComposer(
                $db: $db,
                $table: $db.appSkillWorkspaceSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspacesTable,
          WorkspacesTable,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (WorkspacesTable, $$WorkspacesTableReferences),
          WorkspacesTable,
          PrefetchHooks Function({
            bool serviceConnectionsRefs,
            bool conversationsRefs,
            bool mcpServersRefs,
            bool toolsGroupsRefs,
            bool toolsRefs,
            bool workspaceCompactionSettingsRefs,
            bool skillCredentialDefinitionsRefs,
            bool skillsRefs,
            bool appSkillWorkspaceSettingsRefs,
          })
        > {
  $$WorkspacesTableTableManager(_$AppDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<WorkspaceType> type = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                type: type,
                url: url,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                required WorkspaceType type,
                Value<String?> url = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                type: type,
                url: url,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkspacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                serviceConnectionsRefs = false,
                conversationsRefs = false,
                mcpServersRefs = false,
                toolsGroupsRefs = false,
                toolsRefs = false,
                workspaceCompactionSettingsRefs = false,
                skillCredentialDefinitionsRefs = false,
                skillsRefs = false,
                appSkillWorkspaceSettingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (serviceConnectionsRefs) db.serviceConnections,
                    if (conversationsRefs) db.conversations,
                    if (mcpServersRefs) db.mcpServers,
                    if (toolsGroupsRefs) db.toolsGroups,
                    if (toolsRefs) db.tools,
                    if (workspaceCompactionSettingsRefs)
                      db.workspaceCompactionSettings,
                    if (skillCredentialDefinitionsRefs)
                      db.skillCredentialDefinitions,
                    if (skillsRefs) db.skills,
                    if (appSkillWorkspaceSettingsRefs)
                      db.appSkillWorkspaceSettings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (serviceConnectionsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          ServiceConnectionTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._serviceConnectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).serviceConnectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conversationsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          ConversationsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._conversationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mcpServersRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          McpServersTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._mcpServersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).mcpServersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (toolsGroupsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          ToolsGroupsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._toolsGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).toolsGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (toolsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          ToolsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._toolsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).toolsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workspaceCompactionSettingsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          WorkspaceCompactionSettingsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._workspaceCompactionSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).workspaceCompactionSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (skillCredentialDefinitionsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          SkillCredentialDefinitionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._skillCredentialDefinitionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).skillCredentialDefinitionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (skillsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          SkillsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._skillsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).skillsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (appSkillWorkspaceSettingsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          AppSkillWorkspaceSettingsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._appSkillWorkspaceSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).appSkillWorkspaceSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspacesTable,
      WorkspacesTable,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (WorkspacesTable, $$WorkspacesTableReferences),
      WorkspacesTable,
      PrefetchHooks Function({
        bool serviceConnectionsRefs,
        bool conversationsRefs,
        bool mcpServersRefs,
        bool toolsGroupsRefs,
        bool toolsRefs,
        bool workspaceCompactionSettingsRefs,
        bool skillCredentialDefinitionsRefs,
        bool skillsRefs,
        bool appSkillWorkspaceSettingsRefs,
      })
    >;
typedef $$ServiceConnectionsTableCreateCompanionBuilder =
    ServiceConnectionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String name,
      required String serviceId,
      required ServiceConnectionKindTable kind,
      required ServiceAuthenticationTypeTable authenticationType,
      Value<String?> url,
      Value<String?> encryptedAuthValue,
      Value<String?> keySuffix,
      Value<String?> metadataJson,
      required String workspaceId,
      Value<bool> isEnabled,
      Value<int> rowid,
    });
typedef $$ServiceConnectionsTableUpdateCompanionBuilder =
    ServiceConnectionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> name,
      Value<String> serviceId,
      Value<ServiceConnectionKindTable> kind,
      Value<ServiceAuthenticationTypeTable> authenticationType,
      Value<String?> url,
      Value<String?> encryptedAuthValue,
      Value<String?> keySuffix,
      Value<String?> metadataJson,
      Value<String> workspaceId,
      Value<bool> isEnabled,
      Value<int> rowid,
    });

final class $$ServiceConnectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ServiceConnectionsTable,
          ServiceConnectionTable
        > {
  $$ServiceConnectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(
          db.serviceConnections.workspaceId,
          db.workspaces.id,
        ),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $WorkspaceModelSelectionsTable,
    List<WorkspaceModelSelectionTable>
  >
  _workspaceModelSelectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspaceModelSelections,
        aliasName: $_aliasNameGenerator(
          db.serviceConnections.id,
          db.workspaceModelSelections.modelConnectionId,
        ),
      );

  $$WorkspaceModelSelectionsTableProcessedTableManager
  get workspaceModelSelectionsRefs {
    final manager =
        $$WorkspaceModelSelectionsTableTableManager(
          $_db,
          $_db.workspaceModelSelections,
        ).filter(
          (f) => f.modelConnectionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _workspaceModelSelectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ServiceConnectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ServiceConnectionsTable> {
  $$ServiceConnectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ServiceConnectionKindTable,
    ServiceConnectionKindTable,
    String
  >
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ServiceAuthenticationTypeTable,
    ServiceAuthenticationTypeTable,
    String
  >
  get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedAuthValue => $composableBuilder(
    column: $table.encryptedAuthValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keySuffix => $composableBuilder(
    column: $table.keySuffix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workspaceModelSelectionsRefs(
    Expression<bool> Function($$WorkspaceModelSelectionsTableFilterComposer f)
    f,
  ) {
    final $$WorkspaceModelSelectionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workspaceModelSelections,
          getReferencedColumn: (t) => t.modelConnectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceModelSelectionsTableFilterComposer(
                $db: $db,
                $table: $db.workspaceModelSelections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ServiceConnectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ServiceConnectionsTable> {
  $$ServiceConnectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedAuthValue => $composableBuilder(
    column: $table.encryptedAuthValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keySuffix => $composableBuilder(
    column: $table.keySuffix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServiceConnectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServiceConnectionsTable> {
  $$ServiceConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ServiceConnectionKindTable, String>
  get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ServiceAuthenticationTypeTable, String>
  get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get encryptedAuthValue => $composableBuilder(
    column: $table.encryptedAuthValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keySuffix =>
      $composableBuilder(column: $table.keySuffix, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workspaceModelSelectionsRefs<T extends Object>(
    Expression<T> Function($$WorkspaceModelSelectionsTableAnnotationComposer a)
    f,
  ) {
    final $$WorkspaceModelSelectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workspaceModelSelections,
          getReferencedColumn: (t) => t.modelConnectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceModelSelectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.workspaceModelSelections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ServiceConnectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServiceConnectionsTable,
          ServiceConnectionTable,
          $$ServiceConnectionsTableFilterComposer,
          $$ServiceConnectionsTableOrderingComposer,
          $$ServiceConnectionsTableAnnotationComposer,
          $$ServiceConnectionsTableCreateCompanionBuilder,
          $$ServiceConnectionsTableUpdateCompanionBuilder,
          (ServiceConnectionTable, $$ServiceConnectionsTableReferences),
          ServiceConnectionTable,
          PrefetchHooks Function({
            bool workspaceId,
            bool workspaceModelSelectionsRefs,
          })
        > {
  $$ServiceConnectionsTableTableManager(
    _$AppDatabase db,
    $ServiceConnectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServiceConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServiceConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServiceConnectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> serviceId = const Value.absent(),
                Value<ServiceConnectionKindTable> kind = const Value.absent(),
                Value<ServiceAuthenticationTypeTable> authenticationType =
                    const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> encryptedAuthValue = const Value.absent(),
                Value<String?> keySuffix = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceConnectionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                serviceId: serviceId,
                kind: kind,
                authenticationType: authenticationType,
                url: url,
                encryptedAuthValue: encryptedAuthValue,
                keySuffix: keySuffix,
                metadataJson: metadataJson,
                workspaceId: workspaceId,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                required String serviceId,
                required ServiceConnectionKindTable kind,
                required ServiceAuthenticationTypeTable authenticationType,
                Value<String?> url = const Value.absent(),
                Value<String?> encryptedAuthValue = const Value.absent(),
                Value<String?> keySuffix = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                required String workspaceId,
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServiceConnectionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                serviceId: serviceId,
                kind: kind,
                authenticationType: authenticationType,
                url: url,
                encryptedAuthValue: encryptedAuthValue,
                keySuffix: keySuffix,
                metadataJson: metadataJson,
                workspaceId: workspaceId,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ServiceConnectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceId = false, workspaceModelSelectionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workspaceModelSelectionsRefs)
                      db.workspaceModelSelections,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable:
                                        $$ServiceConnectionsTableReferences
                                            ._workspaceIdTable(db),
                                    referencedColumn:
                                        $$ServiceConnectionsTableReferences
                                            ._workspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workspaceModelSelectionsRefs)
                        await $_getPrefetchedData<
                          ServiceConnectionTable,
                          $ServiceConnectionsTable,
                          WorkspaceModelSelectionTable
                        >(
                          currentTable: table,
                          referencedTable: $$ServiceConnectionsTableReferences
                              ._workspaceModelSelectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServiceConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).workspaceModelSelectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.modelConnectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ServiceConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServiceConnectionsTable,
      ServiceConnectionTable,
      $$ServiceConnectionsTableFilterComposer,
      $$ServiceConnectionsTableOrderingComposer,
      $$ServiceConnectionsTableAnnotationComposer,
      $$ServiceConnectionsTableCreateCompanionBuilder,
      $$ServiceConnectionsTableUpdateCompanionBuilder,
      (ServiceConnectionTable, $$ServiceConnectionsTableReferences),
      ServiceConnectionTable,
      PrefetchHooks Function({
        bool workspaceId,
        bool workspaceModelSelectionsRefs,
      })
    >;
typedef $$ApiModelProvidersTableCreateCompanionBuilder =
    ApiModelProvidersCompanion Function({
      required String id,
      required String name,
      Value<ModelProvidersTableType?> type,
      Value<String?> url,
      Value<String?> doc,
      Value<int> rowid,
    });
typedef $$ApiModelProvidersTableUpdateCompanionBuilder =
    ApiModelProvidersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<ModelProvidersTableType?> type,
      Value<String?> url,
      Value<String?> doc,
      Value<int> rowid,
    });

final class $$ApiModelProvidersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ApiModelProvidersTable,
          ApiModelProvidersTable
        > {
  $$ApiModelProvidersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $WorkspaceModelSelectionsTable,
    List<WorkspaceModelSelectionTable>
  >
  _workspaceModelSelectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspaceModelSelections,
        aliasName: $_aliasNameGenerator(
          db.apiModelProviders.id,
          db.workspaceModelSelections.modelId,
        ),
      );

  $$WorkspaceModelSelectionsTableProcessedTableManager
  get workspaceModelSelectionsRefs {
    final manager = $$WorkspaceModelSelectionsTableTableManager(
      $_db,
      $_db.workspaceModelSelections,
    ).filter((f) => f.modelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workspaceModelSelectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ApiModelsTable, List<ApiModelsTable>>
  _apiModelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.apiModels,
    aliasName: $_aliasNameGenerator(
      db.apiModelProviders.id,
      db.apiModels.modelProvider,
    ),
  );

  $$ApiModelsTableProcessedTableManager get apiModelsRefs {
    final manager = $$ApiModelsTableTableManager(
      $_db,
      $_db.apiModels,
    ).filter((f) => f.modelProvider.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_apiModelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ApiModelProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $ApiModelProvidersTable> {
  $$ApiModelProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ModelProvidersTableType?,
    ModelProvidersTableType,
    String
  >
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doc => $composableBuilder(
    column: $table.doc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workspaceModelSelectionsRefs(
    Expression<bool> Function($$WorkspaceModelSelectionsTableFilterComposer f)
    f,
  ) {
    final $$WorkspaceModelSelectionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workspaceModelSelections,
          getReferencedColumn: (t) => t.modelId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceModelSelectionsTableFilterComposer(
                $db: $db,
                $table: $db.workspaceModelSelections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> apiModelsRefs(
    Expression<bool> Function($$ApiModelsTableFilterComposer f) f,
  ) {
    final $$ApiModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.apiModels,
      getReferencedColumn: (t) => t.modelProvider,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApiModelsTableFilterComposer(
            $db: $db,
            $table: $db.apiModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ApiModelProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiModelProvidersTable> {
  $$ApiModelProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doc => $composableBuilder(
    column: $table.doc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiModelProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiModelProvidersTable> {
  $$ApiModelProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ModelProvidersTableType?, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get doc =>
      $composableBuilder(column: $table.doc, builder: (column) => column);

  Expression<T> workspaceModelSelectionsRefs<T extends Object>(
    Expression<T> Function($$WorkspaceModelSelectionsTableAnnotationComposer a)
    f,
  ) {
    final $$WorkspaceModelSelectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.workspaceModelSelections,
          getReferencedColumn: (t) => t.modelId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceModelSelectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.workspaceModelSelections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> apiModelsRefs<T extends Object>(
    Expression<T> Function($$ApiModelsTableAnnotationComposer a) f,
  ) {
    final $$ApiModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.apiModels,
      getReferencedColumn: (t) => t.modelProvider,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApiModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.apiModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ApiModelProvidersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiModelProvidersTable,
          ApiModelProvidersTable,
          $$ApiModelProvidersTableFilterComposer,
          $$ApiModelProvidersTableOrderingComposer,
          $$ApiModelProvidersTableAnnotationComposer,
          $$ApiModelProvidersTableCreateCompanionBuilder,
          $$ApiModelProvidersTableUpdateCompanionBuilder,
          (ApiModelProvidersTable, $$ApiModelProvidersTableReferences),
          ApiModelProvidersTable,
          PrefetchHooks Function({
            bool workspaceModelSelectionsRefs,
            bool apiModelsRefs,
          })
        > {
  $$ApiModelProvidersTableTableManager(
    _$AppDatabase db,
    $ApiModelProvidersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiModelProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiModelProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiModelProvidersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ModelProvidersTableType?> type = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> doc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiModelProvidersCompanion(
                id: id,
                name: name,
                type: type,
                url: url,
                doc: doc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<ModelProvidersTableType?> type = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> doc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiModelProvidersCompanion.insert(
                id: id,
                name: name,
                type: type,
                url: url,
                doc: doc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ApiModelProvidersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceModelSelectionsRefs = false, apiModelsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workspaceModelSelectionsRefs)
                      db.workspaceModelSelections,
                    if (apiModelsRefs) db.apiModels,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workspaceModelSelectionsRefs)
                        await $_getPrefetchedData<
                          ApiModelProvidersTable,
                          $ApiModelProvidersTable,
                          WorkspaceModelSelectionTable
                        >(
                          currentTable: table,
                          referencedTable: $$ApiModelProvidersTableReferences
                              ._workspaceModelSelectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ApiModelProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).workspaceModelSelectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.modelId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (apiModelsRefs)
                        await $_getPrefetchedData<
                          ApiModelProvidersTable,
                          $ApiModelProvidersTable,
                          ApiModelsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ApiModelProvidersTableReferences
                              ._apiModelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ApiModelProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).apiModelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.modelProvider == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ApiModelProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiModelProvidersTable,
      ApiModelProvidersTable,
      $$ApiModelProvidersTableFilterComposer,
      $$ApiModelProvidersTableOrderingComposer,
      $$ApiModelProvidersTableAnnotationComposer,
      $$ApiModelProvidersTableCreateCompanionBuilder,
      $$ApiModelProvidersTableUpdateCompanionBuilder,
      (ApiModelProvidersTable, $$ApiModelProvidersTableReferences),
      ApiModelProvidersTable,
      PrefetchHooks Function({
        bool workspaceModelSelectionsRefs,
        bool apiModelsRefs,
      })
    >;
typedef $$WorkspaceModelSelectionsTableCreateCompanionBuilder =
    WorkspaceModelSelectionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String modelId,
      required String modelConnectionId,
      Value<int> rowid,
    });
typedef $$WorkspaceModelSelectionsTableUpdateCompanionBuilder =
    WorkspaceModelSelectionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> modelId,
      Value<String> modelConnectionId,
      Value<int> rowid,
    });

final class $$WorkspaceModelSelectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WorkspaceModelSelectionsTable,
          WorkspaceModelSelectionTable
        > {
  $$WorkspaceModelSelectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ApiModelProvidersTable _modelIdTable(_$AppDatabase db) =>
      db.apiModelProviders.createAlias(
        $_aliasNameGenerator(
          db.workspaceModelSelections.modelId,
          db.apiModelProviders.id,
        ),
      );

  $$ApiModelProvidersTableProcessedTableManager get modelId {
    final $_column = $_itemColumn<String>('model_id')!;

    final manager = $$ApiModelProvidersTableTableManager(
      $_db,
      $_db.apiModelProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ServiceConnectionsTable _modelConnectionIdTable(_$AppDatabase db) =>
      db.serviceConnections.createAlias(
        $_aliasNameGenerator(
          db.workspaceModelSelections.modelConnectionId,
          db.serviceConnections.id,
        ),
      );

  $$ServiceConnectionsTableProcessedTableManager get modelConnectionId {
    final $_column = $_itemColumn<String>('model_connection_id')!;

    final manager = $$ServiceConnectionsTableTableManager(
      $_db,
      $_db.serviceConnections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modelConnectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ConversationsTable, List<ConversationsTable>>
  _conversationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.conversations,
    aliasName: $_aliasNameGenerator(
      db.workspaceModelSelections.id,
      db.conversations.modelId,
    ),
  );

  $$ConversationsTableProcessedTableManager get conversationsRefs {
    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.modelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_conversationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspaceModelSelectionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspaceModelSelectionsTable> {
  $$WorkspaceModelSelectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ApiModelProvidersTableFilterComposer get modelId {
    final $$ApiModelProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.apiModelProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApiModelProvidersTableFilterComposer(
            $db: $db,
            $table: $db.apiModelProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServiceConnectionsTableFilterComposer get modelConnectionId {
    final $$ServiceConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelConnectionId,
      referencedTable: $db.serviceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServiceConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.serviceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> conversationsRefs(
    Expression<bool> Function($$ConversationsTableFilterComposer f) f,
  ) {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.modelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspaceModelSelectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspaceModelSelectionsTable> {
  $$WorkspaceModelSelectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ApiModelProvidersTableOrderingComposer get modelId {
    final $$ApiModelProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.apiModelProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApiModelProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.apiModelProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServiceConnectionsTableOrderingComposer get modelConnectionId {
    final $$ServiceConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelConnectionId,
      referencedTable: $db.serviceConnections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServiceConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.serviceConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspaceModelSelectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspaceModelSelectionsTable> {
  $$WorkspaceModelSelectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ApiModelProvidersTableAnnotationComposer get modelId {
    final $$ApiModelProvidersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modelId,
          referencedTable: $db.apiModelProviders,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ApiModelProvidersTableAnnotationComposer(
                $db: $db,
                $table: $db.apiModelProviders,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ServiceConnectionsTableAnnotationComposer get modelConnectionId {
    final $$ServiceConnectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modelConnectionId,
          referencedTable: $db.serviceConnections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ServiceConnectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.serviceConnections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> conversationsRefs<T extends Object>(
    Expression<T> Function($$ConversationsTableAnnotationComposer a) f,
  ) {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.modelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspaceModelSelectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspaceModelSelectionsTable,
          WorkspaceModelSelectionTable,
          $$WorkspaceModelSelectionsTableFilterComposer,
          $$WorkspaceModelSelectionsTableOrderingComposer,
          $$WorkspaceModelSelectionsTableAnnotationComposer,
          $$WorkspaceModelSelectionsTableCreateCompanionBuilder,
          $$WorkspaceModelSelectionsTableUpdateCompanionBuilder,
          (
            WorkspaceModelSelectionTable,
            $$WorkspaceModelSelectionsTableReferences,
          ),
          WorkspaceModelSelectionTable,
          PrefetchHooks Function({
            bool modelId,
            bool modelConnectionId,
            bool conversationsRefs,
          })
        > {
  $$WorkspaceModelSelectionsTableTableManager(
    _$AppDatabase db,
    $WorkspaceModelSelectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspaceModelSelectionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WorkspaceModelSelectionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkspaceModelSelectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> modelConnectionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceModelSelectionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                modelId: modelId,
                modelConnectionId: modelConnectionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String modelId,
                required String modelConnectionId,
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceModelSelectionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                modelId: modelId,
                modelConnectionId: modelConnectionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkspaceModelSelectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                modelId = false,
                modelConnectionId = false,
                conversationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (conversationsRefs) db.conversations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (modelId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.modelId,
                                    referencedTable:
                                        $$WorkspaceModelSelectionsTableReferences
                                            ._modelIdTable(db),
                                    referencedColumn:
                                        $$WorkspaceModelSelectionsTableReferences
                                            ._modelIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (modelConnectionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.modelConnectionId,
                                    referencedTable:
                                        $$WorkspaceModelSelectionsTableReferences
                                            ._modelConnectionIdTable(db),
                                    referencedColumn:
                                        $$WorkspaceModelSelectionsTableReferences
                                            ._modelConnectionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (conversationsRefs)
                        await $_getPrefetchedData<
                          WorkspaceModelSelectionTable,
                          $WorkspaceModelSelectionsTable,
                          ConversationsTable
                        >(
                          currentTable: table,
                          referencedTable:
                              $$WorkspaceModelSelectionsTableReferences
                                  ._conversationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspaceModelSelectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.modelId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkspaceModelSelectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspaceModelSelectionsTable,
      WorkspaceModelSelectionTable,
      $$WorkspaceModelSelectionsTableFilterComposer,
      $$WorkspaceModelSelectionsTableOrderingComposer,
      $$WorkspaceModelSelectionsTableAnnotationComposer,
      $$WorkspaceModelSelectionsTableCreateCompanionBuilder,
      $$WorkspaceModelSelectionsTableUpdateCompanionBuilder,
      (WorkspaceModelSelectionTable, $$WorkspaceModelSelectionsTableReferences),
      WorkspaceModelSelectionTable,
      PrefetchHooks Function({
        bool modelId,
        bool modelConnectionId,
        bool conversationsRefs,
      })
    >;
typedef $$ApiModelsTableCreateCompanionBuilder =
    ApiModelsCompanion Function({
      required String modelProvider,
      required String id,
      required String name,
      Value<List<String>?> modalitiesInput,
      Value<List<String>?> modalitiesOuput,
      Value<bool?> openWeights,
      Value<bool> supportsReasoning,
      Value<double?> costInput,
      Value<double?> costOutput,
      Value<double?> costCacheRead,
      required int limitContext,
      required int limitOutput,
      Value<int> rowid,
    });
typedef $$ApiModelsTableUpdateCompanionBuilder =
    ApiModelsCompanion Function({
      Value<String> modelProvider,
      Value<String> id,
      Value<String> name,
      Value<List<String>?> modalitiesInput,
      Value<List<String>?> modalitiesOuput,
      Value<bool?> openWeights,
      Value<bool> supportsReasoning,
      Value<double?> costInput,
      Value<double?> costOutput,
      Value<double?> costCacheRead,
      Value<int> limitContext,
      Value<int> limitOutput,
      Value<int> rowid,
    });

final class $$ApiModelsTableReferences
    extends BaseReferences<_$AppDatabase, $ApiModelsTable, ApiModelsTable> {
  $$ApiModelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ApiModelProvidersTable _modelProviderTable(_$AppDatabase db) =>
      db.apiModelProviders.createAlias(
        $_aliasNameGenerator(
          db.apiModels.modelProvider,
          db.apiModelProviders.id,
        ),
      );

  $$ApiModelProvidersTableProcessedTableManager get modelProvider {
    final $_column = $_itemColumn<String>('model_provider')!;

    final manager = $$ApiModelProvidersTableTableManager(
      $_db,
      $_db.apiModelProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modelProviderTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ApiModelsTableFilterComposer
    extends Composer<_$AppDatabase, $ApiModelsTable> {
  $$ApiModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get modalitiesInput => $composableBuilder(
    column: $table.modalitiesInput,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get modalitiesOuput => $composableBuilder(
    column: $table.modalitiesOuput,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get openWeights => $composableBuilder(
    column: $table.openWeights,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get supportsReasoning => $composableBuilder(
    column: $table.supportsReasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costInput => $composableBuilder(
    column: $table.costInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costOutput => $composableBuilder(
    column: $table.costOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costCacheRead => $composableBuilder(
    column: $table.costCacheRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitContext => $composableBuilder(
    column: $table.limitContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitOutput => $composableBuilder(
    column: $table.limitOutput,
    builder: (column) => ColumnFilters(column),
  );

  $$ApiModelProvidersTableFilterComposer get modelProvider {
    final $$ApiModelProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelProvider,
      referencedTable: $db.apiModelProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApiModelProvidersTableFilterComposer(
            $db: $db,
            $table: $db.apiModelProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ApiModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiModelsTable> {
  $$ApiModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modalitiesInput => $composableBuilder(
    column: $table.modalitiesInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modalitiesOuput => $composableBuilder(
    column: $table.modalitiesOuput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get openWeights => $composableBuilder(
    column: $table.openWeights,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get supportsReasoning => $composableBuilder(
    column: $table.supportsReasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costInput => $composableBuilder(
    column: $table.costInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costOutput => $composableBuilder(
    column: $table.costOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costCacheRead => $composableBuilder(
    column: $table.costCacheRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitContext => $composableBuilder(
    column: $table.limitContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitOutput => $composableBuilder(
    column: $table.limitOutput,
    builder: (column) => ColumnOrderings(column),
  );

  $$ApiModelProvidersTableOrderingComposer get modelProvider {
    final $$ApiModelProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelProvider,
      referencedTable: $db.apiModelProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApiModelProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.apiModelProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ApiModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiModelsTable> {
  $$ApiModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>?, String> get modalitiesInput =>
      $composableBuilder(
        column: $table.modalitiesInput,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>?, String> get modalitiesOuput =>
      $composableBuilder(
        column: $table.modalitiesOuput,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get openWeights => $composableBuilder(
    column: $table.openWeights,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get supportsReasoning => $composableBuilder(
    column: $table.supportsReasoning,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costInput =>
      $composableBuilder(column: $table.costInput, builder: (column) => column);

  GeneratedColumn<double> get costOutput => $composableBuilder(
    column: $table.costOutput,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costCacheRead => $composableBuilder(
    column: $table.costCacheRead,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitContext => $composableBuilder(
    column: $table.limitContext,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitOutput => $composableBuilder(
    column: $table.limitOutput,
    builder: (column) => column,
  );

  $$ApiModelProvidersTableAnnotationComposer get modelProvider {
    final $$ApiModelProvidersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modelProvider,
          referencedTable: $db.apiModelProviders,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ApiModelProvidersTableAnnotationComposer(
                $db: $db,
                $table: $db.apiModelProviders,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ApiModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiModelsTable,
          ApiModelsTable,
          $$ApiModelsTableFilterComposer,
          $$ApiModelsTableOrderingComposer,
          $$ApiModelsTableAnnotationComposer,
          $$ApiModelsTableCreateCompanionBuilder,
          $$ApiModelsTableUpdateCompanionBuilder,
          (ApiModelsTable, $$ApiModelsTableReferences),
          ApiModelsTable,
          PrefetchHooks Function({bool modelProvider})
        > {
  $$ApiModelsTableTableManager(_$AppDatabase db, $ApiModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> modelProvider = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<List<String>?> modalitiesInput = const Value.absent(),
                Value<List<String>?> modalitiesOuput = const Value.absent(),
                Value<bool?> openWeights = const Value.absent(),
                Value<bool> supportsReasoning = const Value.absent(),
                Value<double?> costInput = const Value.absent(),
                Value<double?> costOutput = const Value.absent(),
                Value<double?> costCacheRead = const Value.absent(),
                Value<int> limitContext = const Value.absent(),
                Value<int> limitOutput = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiModelsCompanion(
                modelProvider: modelProvider,
                id: id,
                name: name,
                modalitiesInput: modalitiesInput,
                modalitiesOuput: modalitiesOuput,
                openWeights: openWeights,
                supportsReasoning: supportsReasoning,
                costInput: costInput,
                costOutput: costOutput,
                costCacheRead: costCacheRead,
                limitContext: limitContext,
                limitOutput: limitOutput,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String modelProvider,
                required String id,
                required String name,
                Value<List<String>?> modalitiesInput = const Value.absent(),
                Value<List<String>?> modalitiesOuput = const Value.absent(),
                Value<bool?> openWeights = const Value.absent(),
                Value<bool> supportsReasoning = const Value.absent(),
                Value<double?> costInput = const Value.absent(),
                Value<double?> costOutput = const Value.absent(),
                Value<double?> costCacheRead = const Value.absent(),
                required int limitContext,
                required int limitOutput,
                Value<int> rowid = const Value.absent(),
              }) => ApiModelsCompanion.insert(
                modelProvider: modelProvider,
                id: id,
                name: name,
                modalitiesInput: modalitiesInput,
                modalitiesOuput: modalitiesOuput,
                openWeights: openWeights,
                supportsReasoning: supportsReasoning,
                costInput: costInput,
                costOutput: costOutput,
                costCacheRead: costCacheRead,
                limitContext: limitContext,
                limitOutput: limitOutput,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ApiModelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({modelProvider = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (modelProvider) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.modelProvider,
                                referencedTable: $$ApiModelsTableReferences
                                    ._modelProviderTable(db),
                                referencedColumn: $$ApiModelsTableReferences
                                    ._modelProviderTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ApiModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiModelsTable,
      ApiModelsTable,
      $$ApiModelsTableFilterComposer,
      $$ApiModelsTableOrderingComposer,
      $$ApiModelsTableAnnotationComposer,
      $$ApiModelsTableCreateCompanionBuilder,
      $$ApiModelsTableUpdateCompanionBuilder,
      (ApiModelsTable, $$ApiModelsTableReferences),
      ApiModelsTable,
      PrefetchHooks Function({bool modelProvider})
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      required String title,
      Value<String?> modelId,
      Value<bool> isPinned,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<String> title,
      Value<String?> modelId,
      Value<bool> isPinned,
      Value<int> rowid,
    });

final class $$ConversationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ConversationsTable, ConversationsTable> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(db.conversations.workspaceId, db.workspaces.id),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkspaceModelSelectionsTable _modelIdTable(_$AppDatabase db) =>
      db.workspaceModelSelections.createAlias(
        $_aliasNameGenerator(
          db.conversations.modelId,
          db.workspaceModelSelections.id,
        ),
      );

  $$WorkspaceModelSelectionsTableProcessedTableManager? get modelId {
    final $_column = $_itemColumn<String>('model_id');
    if ($_column == null) return null;
    final manager = $$WorkspaceModelSelectionsTableTableManager(
      $_db,
      $_db.workspaceModelSelections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<MessagesTable>>
  _messagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: $_aliasNameGenerator(
      db.conversations.id,
      db.messages.conversationId,
    ),
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConversationToolsTable,
    List<ConversationToolsTable>
  >
  _conversationToolsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationTools,
        aliasName: $_aliasNameGenerator(
          db.conversations.id,
          db.conversationTools.conversationId,
        ),
      );

  $$ConversationToolsTableProcessedTableManager get conversationToolsRefs {
    final manager = $$ConversationToolsTableTableManager(
      $_db,
      $_db.conversationTools,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conversationToolsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConversationSkillsTable,
    List<ConversationSkillsTable>
  >
  _conversationSkillsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationSkills,
        aliasName: $_aliasNameGenerator(
          db.conversations.id,
          db.conversationSkills.conversationId,
        ),
      );

  $$ConversationSkillsTableProcessedTableManager get conversationSkillsRefs {
    final manager = $$ConversationSkillsTableTableManager(
      $_db,
      $_db.conversationSkills,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conversationSkillsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkspaceModelSelectionsTableFilterComposer get modelId {
    final $$WorkspaceModelSelectionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modelId,
          referencedTable: $db.workspaceModelSelections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceModelSelectionsTableFilterComposer(
                $db: $db,
                $table: $db.workspaceModelSelections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationToolsRefs(
    Expression<bool> Function($$ConversationToolsTableFilterComposer f) f,
  ) {
    final $$ConversationToolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversationTools,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationToolsTableFilterComposer(
            $db: $db,
            $table: $db.conversationTools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationSkillsRefs(
    Expression<bool> Function($$ConversationSkillsTableFilterComposer f) f,
  ) {
    final $$ConversationSkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversationSkills,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationSkillsTableFilterComposer(
            $db: $db,
            $table: $db.conversationSkills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkspaceModelSelectionsTableOrderingComposer get modelId {
    final $$WorkspaceModelSelectionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modelId,
          referencedTable: $db.workspaceModelSelections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceModelSelectionsTableOrderingComposer(
                $db: $db,
                $table: $db.workspaceModelSelections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkspaceModelSelectionsTableAnnotationComposer get modelId {
    final $$WorkspaceModelSelectionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modelId,
          referencedTable: $db.workspaceModelSelections,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WorkspaceModelSelectionsTableAnnotationComposer(
                $db: $db,
                $table: $db.workspaceModelSelections,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conversationToolsRefs<T extends Object>(
    Expression<T> Function($$ConversationToolsTableAnnotationComposer a) f,
  ) {
    final $$ConversationToolsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationTools,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationToolsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationTools,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> conversationSkillsRefs<T extends Object>(
    Expression<T> Function($$ConversationSkillsTableAnnotationComposer a) f,
  ) {
    final $$ConversationSkillsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationSkills,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationSkillsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationSkills,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          ConversationsTable,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (ConversationsTable, $$ConversationsTableReferences),
          ConversationsTable,
          PrefetchHooks Function({
            bool workspaceId,
            bool modelId,
            bool messagesRefs,
            bool conversationToolsRefs,
            bool conversationSkillsRefs,
          })
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                title: title,
                modelId: modelId,
                isPinned: isPinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                required String title,
                Value<String?> modelId = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                title: title,
                modelId: modelId,
                isPinned: isPinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                modelId = false,
                messagesRefs = false,
                conversationToolsRefs = false,
                conversationSkillsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messagesRefs) db.messages,
                    if (conversationToolsRefs) db.conversationTools,
                    if (conversationSkillsRefs) db.conversationSkills,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable:
                                        $$ConversationsTableReferences
                                            ._workspaceIdTable(db),
                                    referencedColumn:
                                        $$ConversationsTableReferences
                                            ._workspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (modelId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.modelId,
                                    referencedTable:
                                        $$ConversationsTableReferences
                                            ._modelIdTable(db),
                                    referencedColumn:
                                        $$ConversationsTableReferences
                                            ._modelIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messagesRefs)
                        await $_getPrefetchedData<
                          ConversationsTable,
                          $ConversationsTable,
                          MessagesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ConversationsTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conversationToolsRefs)
                        await $_getPrefetchedData<
                          ConversationsTable,
                          $ConversationsTable,
                          ConversationToolsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ConversationsTableReferences
                              ._conversationToolsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationToolsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conversationSkillsRefs)
                        await $_getPrefetchedData<
                          ConversationsTable,
                          $ConversationsTable,
                          ConversationSkillsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ConversationsTableReferences
                              ._conversationSkillsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationSkillsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      ConversationsTable,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (ConversationsTable, $$ConversationsTableReferences),
      ConversationsTable,
      PrefetchHooks Function({
        bool workspaceId,
        bool modelId,
        bool messagesRefs,
        bool conversationToolsRefs,
        bool conversationSkillsRefs,
      })
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String conversationId,
      required String content,
      required MessagesTableType messageType,
      required bool isUser,
      required MessageTableStatus status,
      Value<String?> metadata,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> conversationId,
      Value<String> content,
      Value<MessagesTableType> messageType,
      Value<bool> isUser,
      Value<MessageTableStatus> status,
      Value<String?> metadata,
      Value<int> rowid,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, MessagesTable> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias(
        $_aliasNameGenerator(db.messages.conversationId, db.conversations.id),
      );

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MessagesTableType, MessagesTableType, String>
  get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isUser => $composableBuilder(
    column: $table.isUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MessageTableStatus, MessageTableStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUser => $composableBuilder(
    column: $table.isUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessagesTableType, String> get messageType =>
      $composableBuilder(
        column: $table.messageType,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isUser =>
      $composableBuilder(column: $table.isUser, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageTableStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessagesTable,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (MessagesTable, $$MessagesTableReferences),
          MessagesTable,
          PrefetchHooks Function({bool conversationId})
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<MessagesTableType> messageType = const Value.absent(),
                Value<bool> isUser = const Value.absent(),
                Value<MessageTableStatus> status = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                conversationId: conversationId,
                content: content,
                messageType: messageType,
                isUser: isUser,
                status: status,
                metadata: metadata,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String conversationId,
                required String content,
                required MessagesTableType messageType,
                required bool isUser,
                required MessageTableStatus status,
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                conversationId: conversationId,
                content: content,
                messageType: messageType,
                isUser: isUser,
                status: status,
                metadata: metadata,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (conversationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationId,
                                referencedTable: $$MessagesTableReferences
                                    ._conversationIdTable(db),
                                referencedColumn: $$MessagesTableReferences
                                    ._conversationIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessagesTable,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessagesTable, $$MessagesTableReferences),
      MessagesTable,
      PrefetchHooks Function({bool conversationId})
    >;
typedef $$McpServersTableCreateCompanionBuilder =
    McpServersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      required String name,
      required String url,
      required McpTransportType transport,
      required McpAuthenticationType authenticationType,
      Value<String?> description,
      Value<bool> isEnabled,
      Value<int> rowid,
    });
typedef $$McpServersTableUpdateCompanionBuilder =
    McpServersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<String> name,
      Value<String> url,
      Value<McpTransportType> transport,
      Value<McpAuthenticationType> authenticationType,
      Value<String?> description,
      Value<bool> isEnabled,
      Value<int> rowid,
    });

final class $$McpServersTableReferences
    extends BaseReferences<_$AppDatabase, $McpServersTable, McpServersTable> {
  $$McpServersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(db.mcpServers.workspaceId, db.workspaces.id),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ToolsGroupsTable, List<ToolsGroupsTable>>
  _toolsGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.toolsGroups,
    aliasName: $_aliasNameGenerator(
      db.mcpServers.id,
      db.toolsGroups.mcpServerId,
    ),
  );

  $$ToolsGroupsTableProcessedTableManager get toolsGroupsRefs {
    final manager = $$ToolsGroupsTableTableManager(
      $_db,
      $_db.toolsGroups,
    ).filter((f) => f.mcpServerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_toolsGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$McpServersTableFilterComposer
    extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<McpTransportType, McpTransportType, String>
  get transport => $composableBuilder(
    column: $table.transport,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    McpAuthenticationType,
    McpAuthenticationType,
    String
  >
  get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> toolsGroupsRefs(
    Expression<bool> Function($$ToolsGroupsTableFilterComposer f) f,
  ) {
    final $$ToolsGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.toolsGroups,
      getReferencedColumn: (t) => t.mcpServerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsGroupsTableFilterComposer(
            $db: $db,
            $table: $db.toolsGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$McpServersTableOrderingComposer
    extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transport => $composableBuilder(
    column: $table.transport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$McpServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumnWithTypeConverter<McpTransportType, String> get transport =>
      $composableBuilder(column: $table.transport, builder: (column) => column);

  GeneratedColumnWithTypeConverter<McpAuthenticationType, String>
  get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> toolsGroupsRefs<T extends Object>(
    Expression<T> Function($$ToolsGroupsTableAnnotationComposer a) f,
  ) {
    final $$ToolsGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.toolsGroups,
      getReferencedColumn: (t) => t.mcpServerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.toolsGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$McpServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $McpServersTable,
          McpServersTable,
          $$McpServersTableFilterComposer,
          $$McpServersTableOrderingComposer,
          $$McpServersTableAnnotationComposer,
          $$McpServersTableCreateCompanionBuilder,
          $$McpServersTableUpdateCompanionBuilder,
          (McpServersTable, $$McpServersTableReferences),
          McpServersTable,
          PrefetchHooks Function({bool workspaceId, bool toolsGroupsRefs})
        > {
  $$McpServersTableTableManager(_$AppDatabase db, $McpServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$McpServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$McpServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$McpServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<McpTransportType> transport = const Value.absent(),
                Value<McpAuthenticationType> authenticationType =
                    const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => McpServersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                name: name,
                url: url,
                transport: transport,
                authenticationType: authenticationType,
                description: description,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                required String name,
                required String url,
                required McpTransportType transport,
                required McpAuthenticationType authenticationType,
                Value<String?> description = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => McpServersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                name: name,
                url: url,
                transport: transport,
                authenticationType: authenticationType,
                description: description,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$McpServersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceId = false, toolsGroupsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (toolsGroupsRefs) db.toolsGroups,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $$McpServersTableReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn:
                                        $$McpServersTableReferences
                                            ._workspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (toolsGroupsRefs)
                        await $_getPrefetchedData<
                          McpServersTable,
                          $McpServersTable,
                          ToolsGroupsTable
                        >(
                          currentTable: table,
                          referencedTable: $$McpServersTableReferences
                              ._toolsGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$McpServersTableReferences(
                                db,
                                table,
                                p0,
                              ).toolsGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mcpServerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$McpServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $McpServersTable,
      McpServersTable,
      $$McpServersTableFilterComposer,
      $$McpServersTableOrderingComposer,
      $$McpServersTableAnnotationComposer,
      $$McpServersTableCreateCompanionBuilder,
      $$McpServersTableUpdateCompanionBuilder,
      (McpServersTable, $$McpServersTableReferences),
      McpServersTable,
      PrefetchHooks Function({bool workspaceId, bool toolsGroupsRefs})
    >;
typedef $$ToolsGroupsTableCreateCompanionBuilder =
    ToolsGroupsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      Value<String?> mcpServerId,
      required String name,
      Value<bool> isEnabled,
      required PermissionAccess permissions,
      Value<int> rowid,
    });
typedef $$ToolsGroupsTableUpdateCompanionBuilder =
    ToolsGroupsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<String?> mcpServerId,
      Value<String> name,
      Value<bool> isEnabled,
      Value<PermissionAccess> permissions,
      Value<int> rowid,
    });

final class $$ToolsGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $ToolsGroupsTable, ToolsGroupsTable> {
  $$ToolsGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(db.toolsGroups.workspaceId, db.workspaces.id),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $McpServersTable _mcpServerIdTable(_$AppDatabase db) =>
      db.mcpServers.createAlias(
        $_aliasNameGenerator(db.toolsGroups.mcpServerId, db.mcpServers.id),
      );

  $$McpServersTableProcessedTableManager? get mcpServerId {
    final $_column = $_itemColumn<String>('mcp_server_id');
    if ($_column == null) return null;
    final manager = $$McpServersTableTableManager(
      $_db,
      $_db.mcpServers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mcpServerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ToolsTable, List<ToolsTable>> _toolsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tools,
    aliasName: $_aliasNameGenerator(
      db.toolsGroups.id,
      db.tools.workspaceToolsGroupId,
    ),
  );

  $$ToolsTableProcessedTableManager get toolsRefs {
    final manager = $$ToolsTableTableManager($_db, $_db.tools).filter(
      (f) => f.workspaceToolsGroupId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_toolsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ToolsGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ToolsGroupsTable> {
  $$ToolsGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PermissionAccess, PermissionAccess, String>
  get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$McpServersTableFilterComposer get mcpServerId {
    final $$McpServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mcpServerId,
      referencedTable: $db.mcpServers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$McpServersTableFilterComposer(
            $db: $db,
            $table: $db.mcpServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> toolsRefs(
    Expression<bool> Function($$ToolsTableFilterComposer f) f,
  ) {
    final $$ToolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tools,
      getReferencedColumn: (t) => t.workspaceToolsGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsTableFilterComposer(
            $db: $db,
            $table: $db.tools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ToolsGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ToolsGroupsTable> {
  $$ToolsGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$McpServersTableOrderingComposer get mcpServerId {
    final $$McpServersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mcpServerId,
      referencedTable: $db.mcpServers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$McpServersTableOrderingComposer(
            $db: $db,
            $table: $db.mcpServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ToolsGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToolsGroupsTable> {
  $$ToolsGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PermissionAccess, String> get permissions =>
      $composableBuilder(
        column: $table.permissions,
        builder: (column) => column,
      );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$McpServersTableAnnotationComposer get mcpServerId {
    final $$McpServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mcpServerId,
      referencedTable: $db.mcpServers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$McpServersTableAnnotationComposer(
            $db: $db,
            $table: $db.mcpServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> toolsRefs<T extends Object>(
    Expression<T> Function($$ToolsTableAnnotationComposer a) f,
  ) {
    final $$ToolsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tools,
      getReferencedColumn: (t) => t.workspaceToolsGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsTableAnnotationComposer(
            $db: $db,
            $table: $db.tools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ToolsGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ToolsGroupsTable,
          ToolsGroupsTable,
          $$ToolsGroupsTableFilterComposer,
          $$ToolsGroupsTableOrderingComposer,
          $$ToolsGroupsTableAnnotationComposer,
          $$ToolsGroupsTableCreateCompanionBuilder,
          $$ToolsGroupsTableUpdateCompanionBuilder,
          (ToolsGroupsTable, $$ToolsGroupsTableReferences),
          ToolsGroupsTable,
          PrefetchHooks Function({
            bool workspaceId,
            bool mcpServerId,
            bool toolsRefs,
          })
        > {
  $$ToolsGroupsTableTableManager(_$AppDatabase db, $ToolsGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToolsGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToolsGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToolsGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> mcpServerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<PermissionAccess> permissions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ToolsGroupsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                mcpServerId: mcpServerId,
                name: name,
                isEnabled: isEnabled,
                permissions: permissions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                Value<String?> mcpServerId = const Value.absent(),
                required String name,
                Value<bool> isEnabled = const Value.absent(),
                required PermissionAccess permissions,
                Value<int> rowid = const Value.absent(),
              }) => ToolsGroupsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                mcpServerId: mcpServerId,
                name: name,
                isEnabled: isEnabled,
                permissions: permissions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ToolsGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceId = false, mcpServerId = false, toolsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (toolsRefs) db.tools],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable:
                                        $$ToolsGroupsTableReferences
                                            ._workspaceIdTable(db),
                                    referencedColumn:
                                        $$ToolsGroupsTableReferences
                                            ._workspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (mcpServerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.mcpServerId,
                                    referencedTable:
                                        $$ToolsGroupsTableReferences
                                            ._mcpServerIdTable(db),
                                    referencedColumn:
                                        $$ToolsGroupsTableReferences
                                            ._mcpServerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (toolsRefs)
                        await $_getPrefetchedData<
                          ToolsGroupsTable,
                          $ToolsGroupsTable,
                          ToolsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ToolsGroupsTableReferences
                              ._toolsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ToolsGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).toolsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceToolsGroupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ToolsGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ToolsGroupsTable,
      ToolsGroupsTable,
      $$ToolsGroupsTableFilterComposer,
      $$ToolsGroupsTableOrderingComposer,
      $$ToolsGroupsTableAnnotationComposer,
      $$ToolsGroupsTableCreateCompanionBuilder,
      $$ToolsGroupsTableUpdateCompanionBuilder,
      (ToolsGroupsTable, $$ToolsGroupsTableReferences),
      ToolsGroupsTable,
      PrefetchHooks Function({
        bool workspaceId,
        bool mcpServerId,
        bool toolsRefs,
      })
    >;
typedef $$ToolsTableCreateCompanionBuilder =
    ToolsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      Value<String?> workspaceToolsGroupId,
      required String toolId,
      Value<String?> customName,
      Value<String?> description,
      Value<String?> additionalPrompt,
      Value<String?> config,
      Value<String?> inputSchema,
      Value<bool> isEnabled,
      Value<PermissionAccess> permissions,
      Value<int> rowid,
    });
typedef $$ToolsTableUpdateCompanionBuilder =
    ToolsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<String?> workspaceToolsGroupId,
      Value<String> toolId,
      Value<String?> customName,
      Value<String?> description,
      Value<String?> additionalPrompt,
      Value<String?> config,
      Value<String?> inputSchema,
      Value<bool> isEnabled,
      Value<PermissionAccess> permissions,
      Value<int> rowid,
    });

final class $$ToolsTableReferences
    extends BaseReferences<_$AppDatabase, $ToolsTable, ToolsTable> {
  $$ToolsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(db.tools.workspaceId, db.workspaces.id),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ToolsGroupsTable _workspaceToolsGroupIdTable(_$AppDatabase db) =>
      db.toolsGroups.createAlias(
        $_aliasNameGenerator(db.tools.workspaceToolsGroupId, db.toolsGroups.id),
      );

  $$ToolsGroupsTableProcessedTableManager? get workspaceToolsGroupId {
    final $_column = $_itemColumn<String>('workspace_tools_group_id');
    if ($_column == null) return null;
    final manager = $$ToolsGroupsTableTableManager(
      $_db,
      $_db.toolsGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _workspaceToolsGroupIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ConversationToolsTable,
    List<ConversationToolsTable>
  >
  _conversationToolsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationTools,
        aliasName: $_aliasNameGenerator(
          db.tools.id,
          db.conversationTools.toolId,
        ),
      );

  $$ConversationToolsTableProcessedTableManager get conversationToolsRefs {
    final manager = $$ConversationToolsTableTableManager(
      $_db,
      $_db.conversationTools,
    ).filter((f) => f.toolId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conversationToolsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ToolsTableFilterComposer extends Composer<_$AppDatabase, $ToolsTable> {
  $$ToolsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolId => $composableBuilder(
    column: $table.toolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get additionalPrompt => $composableBuilder(
    column: $table.additionalPrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputSchema => $composableBuilder(
    column: $table.inputSchema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PermissionAccess, PermissionAccess, String>
  get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ToolsGroupsTableFilterComposer get workspaceToolsGroupId {
    final $$ToolsGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceToolsGroupId,
      referencedTable: $db.toolsGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsGroupsTableFilterComposer(
            $db: $db,
            $table: $db.toolsGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> conversationToolsRefs(
    Expression<bool> Function($$ConversationToolsTableFilterComposer f) f,
  ) {
    final $$ConversationToolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversationTools,
      getReferencedColumn: (t) => t.toolId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationToolsTableFilterComposer(
            $db: $db,
            $table: $db.conversationTools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ToolsTableOrderingComposer
    extends Composer<_$AppDatabase, $ToolsTable> {
  $$ToolsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolId => $composableBuilder(
    column: $table.toolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get additionalPrompt => $composableBuilder(
    column: $table.additionalPrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputSchema => $composableBuilder(
    column: $table.inputSchema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ToolsGroupsTableOrderingComposer get workspaceToolsGroupId {
    final $$ToolsGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceToolsGroupId,
      referencedTable: $db.toolsGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.toolsGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ToolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToolsTable> {
  $$ToolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get toolId =>
      $composableBuilder(column: $table.toolId, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get additionalPrompt => $composableBuilder(
    column: $table.additionalPrompt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<String> get inputSchema => $composableBuilder(
    column: $table.inputSchema,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PermissionAccess, String> get permissions =>
      $composableBuilder(
        column: $table.permissions,
        builder: (column) => column,
      );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ToolsGroupsTableAnnotationComposer get workspaceToolsGroupId {
    final $$ToolsGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceToolsGroupId,
      referencedTable: $db.toolsGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.toolsGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> conversationToolsRefs<T extends Object>(
    Expression<T> Function($$ConversationToolsTableAnnotationComposer a) f,
  ) {
    final $$ConversationToolsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationTools,
          getReferencedColumn: (t) => t.toolId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationToolsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationTools,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ToolsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ToolsTable,
          ToolsTable,
          $$ToolsTableFilterComposer,
          $$ToolsTableOrderingComposer,
          $$ToolsTableAnnotationComposer,
          $$ToolsTableCreateCompanionBuilder,
          $$ToolsTableUpdateCompanionBuilder,
          (ToolsTable, $$ToolsTableReferences),
          ToolsTable,
          PrefetchHooks Function({
            bool workspaceId,
            bool workspaceToolsGroupId,
            bool conversationToolsRefs,
          })
        > {
  $$ToolsTableTableManager(_$AppDatabase db, $ToolsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToolsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> workspaceToolsGroupId = const Value.absent(),
                Value<String> toolId = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> additionalPrompt = const Value.absent(),
                Value<String?> config = const Value.absent(),
                Value<String?> inputSchema = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<PermissionAccess> permissions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ToolsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                workspaceToolsGroupId: workspaceToolsGroupId,
                toolId: toolId,
                customName: customName,
                description: description,
                additionalPrompt: additionalPrompt,
                config: config,
                inputSchema: inputSchema,
                isEnabled: isEnabled,
                permissions: permissions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                Value<String?> workspaceToolsGroupId = const Value.absent(),
                required String toolId,
                Value<String?> customName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> additionalPrompt = const Value.absent(),
                Value<String?> config = const Value.absent(),
                Value<String?> inputSchema = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<PermissionAccess> permissions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ToolsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                workspaceToolsGroupId: workspaceToolsGroupId,
                toolId: toolId,
                customName: customName,
                description: description,
                additionalPrompt: additionalPrompt,
                config: config,
                inputSchema: inputSchema,
                isEnabled: isEnabled,
                permissions: permissions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ToolsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                workspaceToolsGroupId = false,
                conversationToolsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (conversationToolsRefs) db.conversationTools,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $$ToolsTableReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn: $$ToolsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (workspaceToolsGroupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceToolsGroupId,
                                    referencedTable: $$ToolsTableReferences
                                        ._workspaceToolsGroupIdTable(db),
                                    referencedColumn: $$ToolsTableReferences
                                        ._workspaceToolsGroupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (conversationToolsRefs)
                        await $_getPrefetchedData<
                          ToolsTable,
                          $ToolsTable,
                          ConversationToolsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ToolsTableReferences
                              ._conversationToolsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ToolsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationToolsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toolId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ToolsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ToolsTable,
      ToolsTable,
      $$ToolsTableFilterComposer,
      $$ToolsTableOrderingComposer,
      $$ToolsTableAnnotationComposer,
      $$ToolsTableCreateCompanionBuilder,
      $$ToolsTableUpdateCompanionBuilder,
      (ToolsTable, $$ToolsTableReferences),
      ToolsTable,
      PrefetchHooks Function({
        bool workspaceId,
        bool workspaceToolsGroupId,
        bool conversationToolsRefs,
      })
    >;
typedef $$ConversationToolsTableCreateCompanionBuilder =
    ConversationToolsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String conversationId,
      required String toolId,
      Value<bool> isEnabled,
      Value<PermissionAccess> permissions,
      Value<int> rowid,
    });
typedef $$ConversationToolsTableUpdateCompanionBuilder =
    ConversationToolsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> conversationId,
      Value<String> toolId,
      Value<bool> isEnabled,
      Value<PermissionAccess> permissions,
      Value<int> rowid,
    });

final class $$ConversationToolsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConversationToolsTable,
          ConversationToolsTable
        > {
  $$ConversationToolsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias(
        $_aliasNameGenerator(
          db.conversationTools.conversationId,
          db.conversations.id,
        ),
      );

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ToolsTable _toolIdTable(_$AppDatabase db) => db.tools.createAlias(
    $_aliasNameGenerator(db.conversationTools.toolId, db.tools.id),
  );

  $$ToolsTableProcessedTableManager get toolId {
    final $_column = $_itemColumn<String>('tool_id')!;

    final manager = $$ToolsTableTableManager(
      $_db,
      $_db.tools,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toolIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConversationToolsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationToolsTable> {
  $$ConversationToolsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PermissionAccess, PermissionAccess, String>
  get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ToolsTableFilterComposer get toolId {
    final $$ToolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toolId,
      referencedTable: $db.tools,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsTableFilterComposer(
            $db: $db,
            $table: $db.tools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationToolsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationToolsTable> {
  $$ConversationToolsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ToolsTableOrderingComposer get toolId {
    final $$ToolsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toolId,
      referencedTable: $db.tools,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsTableOrderingComposer(
            $db: $db,
            $table: $db.tools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationToolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationToolsTable> {
  $$ConversationToolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PermissionAccess, String> get permissions =>
      $composableBuilder(
        column: $table.permissions,
        builder: (column) => column,
      );

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ToolsTableAnnotationComposer get toolId {
    final $$ToolsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toolId,
      referencedTable: $db.tools,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ToolsTableAnnotationComposer(
            $db: $db,
            $table: $db.tools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationToolsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationToolsTable,
          ConversationToolsTable,
          $$ConversationToolsTableFilterComposer,
          $$ConversationToolsTableOrderingComposer,
          $$ConversationToolsTableAnnotationComposer,
          $$ConversationToolsTableCreateCompanionBuilder,
          $$ConversationToolsTableUpdateCompanionBuilder,
          (ConversationToolsTable, $$ConversationToolsTableReferences),
          ConversationToolsTable,
          PrefetchHooks Function({bool conversationId, bool toolId})
        > {
  $$ConversationToolsTableTableManager(
    _$AppDatabase db,
    $ConversationToolsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationToolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationToolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationToolsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> toolId = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<PermissionAccess> permissions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationToolsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                conversationId: conversationId,
                toolId: toolId,
                isEnabled: isEnabled,
                permissions: permissions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String conversationId,
                required String toolId,
                Value<bool> isEnabled = const Value.absent(),
                Value<PermissionAccess> permissions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationToolsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                conversationId: conversationId,
                toolId: toolId,
                isEnabled: isEnabled,
                permissions: permissions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationToolsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false, toolId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (conversationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationId,
                                referencedTable:
                                    $$ConversationToolsTableReferences
                                        ._conversationIdTable(db),
                                referencedColumn:
                                    $$ConversationToolsTableReferences
                                        ._conversationIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (toolId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.toolId,
                                referencedTable:
                                    $$ConversationToolsTableReferences
                                        ._toolIdTable(db),
                                referencedColumn:
                                    $$ConversationToolsTableReferences
                                        ._toolIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ConversationToolsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationToolsTable,
      ConversationToolsTable,
      $$ConversationToolsTableFilterComposer,
      $$ConversationToolsTableOrderingComposer,
      $$ConversationToolsTableAnnotationComposer,
      $$ConversationToolsTableCreateCompanionBuilder,
      $$ConversationToolsTableUpdateCompanionBuilder,
      (ConversationToolsTable, $$ConversationToolsTableReferences),
      ConversationToolsTable,
      PrefetchHooks Function({bool conversationId, bool toolId})
    >;
typedef $$WorkspaceCompactionSettingsTableCreateCompanionBuilder =
    WorkspaceCompactionSettingsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      Value<bool?> autoCompactEnabled,
      Value<int?> usagePercentageThreshold,
      Value<int?> remainingTokenThreshold,
      Value<int> rowid,
    });
typedef $$WorkspaceCompactionSettingsTableUpdateCompanionBuilder =
    WorkspaceCompactionSettingsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<bool?> autoCompactEnabled,
      Value<int?> usagePercentageThreshold,
      Value<int?> remainingTokenThreshold,
      Value<int> rowid,
    });

final class $$WorkspaceCompactionSettingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WorkspaceCompactionSettingsTable,
          WorkspaceCompactionSettingsTable
        > {
  $$WorkspaceCompactionSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(
          db.workspaceCompactionSettings.workspaceId,
          db.workspaces.id,
        ),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkspaceCompactionSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspaceCompactionSettingsTable> {
  $$WorkspaceCompactionSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoCompactEnabled => $composableBuilder(
    column: $table.autoCompactEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usagePercentageThreshold => $composableBuilder(
    column: $table.usagePercentageThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remainingTokenThreshold => $composableBuilder(
    column: $table.remainingTokenThreshold,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspaceCompactionSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspaceCompactionSettingsTable> {
  $$WorkspaceCompactionSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoCompactEnabled => $composableBuilder(
    column: $table.autoCompactEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usagePercentageThreshold => $composableBuilder(
    column: $table.usagePercentageThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remainingTokenThreshold => $composableBuilder(
    column: $table.remainingTokenThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspaceCompactionSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspaceCompactionSettingsTable> {
  $$WorkspaceCompactionSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get autoCompactEnabled => $composableBuilder(
    column: $table.autoCompactEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usagePercentageThreshold => $composableBuilder(
    column: $table.usagePercentageThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remainingTokenThreshold => $composableBuilder(
    column: $table.remainingTokenThreshold,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkspaceCompactionSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspaceCompactionSettingsTable,
          WorkspaceCompactionSettingsTable,
          $$WorkspaceCompactionSettingsTableFilterComposer,
          $$WorkspaceCompactionSettingsTableOrderingComposer,
          $$WorkspaceCompactionSettingsTableAnnotationComposer,
          $$WorkspaceCompactionSettingsTableCreateCompanionBuilder,
          $$WorkspaceCompactionSettingsTableUpdateCompanionBuilder,
          (
            WorkspaceCompactionSettingsTable,
            $$WorkspaceCompactionSettingsTableReferences,
          ),
          WorkspaceCompactionSettingsTable,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$WorkspaceCompactionSettingsTableTableManager(
    _$AppDatabase db,
    $WorkspaceCompactionSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspaceCompactionSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WorkspaceCompactionSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkspaceCompactionSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<bool?> autoCompactEnabled = const Value.absent(),
                Value<int?> usagePercentageThreshold = const Value.absent(),
                Value<int?> remainingTokenThreshold = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceCompactionSettingsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                autoCompactEnabled: autoCompactEnabled,
                usagePercentageThreshold: usagePercentageThreshold,
                remainingTokenThreshold: remainingTokenThreshold,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                Value<bool?> autoCompactEnabled = const Value.absent(),
                Value<int?> usagePercentageThreshold = const Value.absent(),
                Value<int?> remainingTokenThreshold = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceCompactionSettingsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                autoCompactEnabled: autoCompactEnabled,
                usagePercentageThreshold: usagePercentageThreshold,
                remainingTokenThreshold: remainingTokenThreshold,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkspaceCompactionSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable:
                                    $$WorkspaceCompactionSettingsTableReferences
                                        ._workspaceIdTable(db),
                                referencedColumn:
                                    $$WorkspaceCompactionSettingsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkspaceCompactionSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspaceCompactionSettingsTable,
      WorkspaceCompactionSettingsTable,
      $$WorkspaceCompactionSettingsTableFilterComposer,
      $$WorkspaceCompactionSettingsTableOrderingComposer,
      $$WorkspaceCompactionSettingsTableAnnotationComposer,
      $$WorkspaceCompactionSettingsTableCreateCompanionBuilder,
      $$WorkspaceCompactionSettingsTableUpdateCompanionBuilder,
      (
        WorkspaceCompactionSettingsTable,
        $$WorkspaceCompactionSettingsTableReferences,
      ),
      WorkspaceCompactionSettingsTable,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $$SkillCredentialDefinitionsTableCreateCompanionBuilder =
    SkillCredentialDefinitionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      required String title,
      required String slug,
      required String attributesJson,
      Value<int> rowid,
    });
typedef $$SkillCredentialDefinitionsTableUpdateCompanionBuilder =
    SkillCredentialDefinitionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<String> title,
      Value<String> slug,
      Value<String> attributesJson,
      Value<int> rowid,
    });

final class $$SkillCredentialDefinitionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SkillCredentialDefinitionsTable,
          SkillCredentialDefinitionsTable
        > {
  $$SkillCredentialDefinitionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(
          db.skillCredentialDefinitions.workspaceId,
          db.workspaces.id,
        ),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SkillsTable, List<SkillsTable>> _skillsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.skills,
    aliasName: $_aliasNameGenerator(
      db.skillCredentialDefinitions.id,
      db.skills.credentialDefinitionId,
    ),
  );

  $$SkillsTableProcessedTableManager get skillsRefs {
    final manager = $$SkillsTableTableManager($_db, $_db.skills).filter(
      (f) => f.credentialDefinitionId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_skillsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SkillCredentialDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $SkillCredentialDefinitionsTable> {
  $$SkillCredentialDefinitionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attributesJson => $composableBuilder(
    column: $table.attributesJson,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> skillsRefs(
    Expression<bool> Function($$SkillsTableFilterComposer f) f,
  ) {
    final $$SkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.credentialDefinitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableFilterComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SkillCredentialDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkillCredentialDefinitionsTable> {
  $$SkillCredentialDefinitionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attributesJson => $composableBuilder(
    column: $table.attributesJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SkillCredentialDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkillCredentialDefinitionsTable> {
  $$SkillCredentialDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get attributesJson => $composableBuilder(
    column: $table.attributesJson,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> skillsRefs<T extends Object>(
    Expression<T> Function($$SkillsTableAnnotationComposer a) f,
  ) {
    final $$SkillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.credentialDefinitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableAnnotationComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SkillCredentialDefinitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkillCredentialDefinitionsTable,
          SkillCredentialDefinitionsTable,
          $$SkillCredentialDefinitionsTableFilterComposer,
          $$SkillCredentialDefinitionsTableOrderingComposer,
          $$SkillCredentialDefinitionsTableAnnotationComposer,
          $$SkillCredentialDefinitionsTableCreateCompanionBuilder,
          $$SkillCredentialDefinitionsTableUpdateCompanionBuilder,
          (
            SkillCredentialDefinitionsTable,
            $$SkillCredentialDefinitionsTableReferences,
          ),
          SkillCredentialDefinitionsTable,
          PrefetchHooks Function({bool workspaceId, bool skillsRefs})
        > {
  $$SkillCredentialDefinitionsTableTableManager(
    _$AppDatabase db,
    $SkillCredentialDefinitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillCredentialDefinitionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SkillCredentialDefinitionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SkillCredentialDefinitionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> attributesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillCredentialDefinitionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                title: title,
                slug: slug,
                attributesJson: attributesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                required String title,
                required String slug,
                required String attributesJson,
                Value<int> rowid = const Value.absent(),
              }) => SkillCredentialDefinitionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                title: title,
                slug: slug,
                attributesJson: attributesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SkillCredentialDefinitionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false, skillsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (skillsRefs) db.skills],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable:
                                    $$SkillCredentialDefinitionsTableReferences
                                        ._workspaceIdTable(db),
                                referencedColumn:
                                    $$SkillCredentialDefinitionsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (skillsRefs)
                    await $_getPrefetchedData<
                      SkillCredentialDefinitionsTable,
                      $SkillCredentialDefinitionsTable,
                      SkillsTable
                    >(
                      currentTable: table,
                      referencedTable:
                          $$SkillCredentialDefinitionsTableReferences
                              ._skillsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SkillCredentialDefinitionsTableReferences(
                            db,
                            table,
                            p0,
                          ).skillsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.credentialDefinitionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SkillCredentialDefinitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkillCredentialDefinitionsTable,
      SkillCredentialDefinitionsTable,
      $$SkillCredentialDefinitionsTableFilterComposer,
      $$SkillCredentialDefinitionsTableOrderingComposer,
      $$SkillCredentialDefinitionsTableAnnotationComposer,
      $$SkillCredentialDefinitionsTableCreateCompanionBuilder,
      $$SkillCredentialDefinitionsTableUpdateCompanionBuilder,
      (
        SkillCredentialDefinitionsTable,
        $$SkillCredentialDefinitionsTableReferences,
      ),
      SkillCredentialDefinitionsTable,
      PrefetchHooks Function({bool workspaceId, bool skillsRefs})
    >;
typedef $$SkillsTableCreateCompanionBuilder =
    SkillsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      required SkillSourceTable source,
      required SkillKindTable kind,
      required String title,
      required String slug,
      required String description,
      required String content,
      Value<String?> credentialDefinitionId,
      Value<bool> isCredentialOptional,
      Value<bool> isEnabled,
      Value<int> rowid,
    });
typedef $$SkillsTableUpdateCompanionBuilder =
    SkillsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<SkillSourceTable> source,
      Value<SkillKindTable> kind,
      Value<String> title,
      Value<String> slug,
      Value<String> description,
      Value<String> content,
      Value<String?> credentialDefinitionId,
      Value<bool> isCredentialOptional,
      Value<bool> isEnabled,
      Value<int> rowid,
    });

final class $$SkillsTableReferences
    extends BaseReferences<_$AppDatabase, $SkillsTable, SkillsTable> {
  $$SkillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(db.skills.workspaceId, db.workspaces.id),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SkillCredentialDefinitionsTable _credentialDefinitionIdTable(
    _$AppDatabase db,
  ) => db.skillCredentialDefinitions.createAlias(
    $_aliasNameGenerator(
      db.skills.credentialDefinitionId,
      db.skillCredentialDefinitions.id,
    ),
  );

  $$SkillCredentialDefinitionsTableProcessedTableManager?
  get credentialDefinitionId {
    final $_column = $_itemColumn<String>('credential_definition_id');
    if ($_column == null) return null;
    final manager = $$SkillCredentialDefinitionsTableTableManager(
      $_db,
      $_db.skillCredentialDefinitions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _credentialDefinitionIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SkillTemplateToolsTable,
    List<SkillTemplateToolsTable>
  >
  _skillTemplateToolsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.skillTemplateTools,
        aliasName: $_aliasNameGenerator(
          db.skills.id,
          db.skillTemplateTools.skillId,
        ),
      );

  $$SkillTemplateToolsTableProcessedTableManager get skillTemplateToolsRefs {
    final manager = $$SkillTemplateToolsTableTableManager(
      $_db,
      $_db.skillTemplateTools,
    ).filter((f) => f.skillId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _skillTemplateToolsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConversationSkillsTable,
    List<ConversationSkillsTable>
  >
  _conversationSkillsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationSkills,
        aliasName: $_aliasNameGenerator(
          db.skills.id,
          db.conversationSkills.workspaceSkillId,
        ),
      );

  $$ConversationSkillsTableProcessedTableManager get conversationSkillsRefs {
    final manager =
        $$ConversationSkillsTableTableManager(
          $_db,
          $_db.conversationSkills,
        ).filter(
          (f) => f.workspaceSkillId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _conversationSkillsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SkillsTableFilterComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkillSourceTable, SkillSourceTable, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SkillKindTable, SkillKindTable, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCredentialOptional => $composableBuilder(
    column: $table.isCredentialOptional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SkillCredentialDefinitionsTableFilterComposer get credentialDefinitionId {
    final $$SkillCredentialDefinitionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.credentialDefinitionId,
          referencedTable: $db.skillCredentialDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SkillCredentialDefinitionsTableFilterComposer(
                $db: $db,
                $table: $db.skillCredentialDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<bool> skillTemplateToolsRefs(
    Expression<bool> Function($$SkillTemplateToolsTableFilterComposer f) f,
  ) {
    final $$SkillTemplateToolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.skillTemplateTools,
      getReferencedColumn: (t) => t.skillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillTemplateToolsTableFilterComposer(
            $db: $db,
            $table: $db.skillTemplateTools,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationSkillsRefs(
    Expression<bool> Function($$ConversationSkillsTableFilterComposer f) f,
  ) {
    final $$ConversationSkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversationSkills,
      getReferencedColumn: (t) => t.workspaceSkillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationSkillsTableFilterComposer(
            $db: $db,
            $table: $db.conversationSkills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SkillsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCredentialOptional => $composableBuilder(
    column: $table.isCredentialOptional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SkillCredentialDefinitionsTableOrderingComposer get credentialDefinitionId {
    final $$SkillCredentialDefinitionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.credentialDefinitionId,
          referencedTable: $db.skillCredentialDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SkillCredentialDefinitionsTableOrderingComposer(
                $db: $db,
                $table: $db.skillCredentialDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SkillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillSourceTable, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillKindTable, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isCredentialOptional => $composableBuilder(
    column: $table.isCredentialOptional,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SkillCredentialDefinitionsTableAnnotationComposer
  get credentialDefinitionId {
    final $$SkillCredentialDefinitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.credentialDefinitionId,
          referencedTable: $db.skillCredentialDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SkillCredentialDefinitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.skillCredentialDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> skillTemplateToolsRefs<T extends Object>(
    Expression<T> Function($$SkillTemplateToolsTableAnnotationComposer a) f,
  ) {
    final $$SkillTemplateToolsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.skillTemplateTools,
          getReferencedColumn: (t) => t.skillId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SkillTemplateToolsTableAnnotationComposer(
                $db: $db,
                $table: $db.skillTemplateTools,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> conversationSkillsRefs<T extends Object>(
    Expression<T> Function($$ConversationSkillsTableAnnotationComposer a) f,
  ) {
    final $$ConversationSkillsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.conversationSkills,
          getReferencedColumn: (t) => t.workspaceSkillId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationSkillsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationSkills,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SkillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkillsTable,
          SkillsTable,
          $$SkillsTableFilterComposer,
          $$SkillsTableOrderingComposer,
          $$SkillsTableAnnotationComposer,
          $$SkillsTableCreateCompanionBuilder,
          $$SkillsTableUpdateCompanionBuilder,
          (SkillsTable, $$SkillsTableReferences),
          SkillsTable,
          PrefetchHooks Function({
            bool workspaceId,
            bool credentialDefinitionId,
            bool skillTemplateToolsRefs,
            bool conversationSkillsRefs,
          })
        > {
  $$SkillsTableTableManager(_$AppDatabase db, $SkillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<SkillSourceTable> source = const Value.absent(),
                Value<SkillKindTable> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> credentialDefinitionId = const Value.absent(),
                Value<bool> isCredentialOptional = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                source: source,
                kind: kind,
                title: title,
                slug: slug,
                description: description,
                content: content,
                credentialDefinitionId: credentialDefinitionId,
                isCredentialOptional: isCredentialOptional,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                required SkillSourceTable source,
                required SkillKindTable kind,
                required String title,
                required String slug,
                required String description,
                required String content,
                Value<String?> credentialDefinitionId = const Value.absent(),
                Value<bool> isCredentialOptional = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                source: source,
                kind: kind,
                title: title,
                slug: slug,
                description: description,
                content: content,
                credentialDefinitionId: credentialDefinitionId,
                isCredentialOptional: isCredentialOptional,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SkillsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                credentialDefinitionId = false,
                skillTemplateToolsRefs = false,
                conversationSkillsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (skillTemplateToolsRefs) db.skillTemplateTools,
                    if (conversationSkillsRefs) db.conversationSkills,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $$SkillsTableReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn: $$SkillsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (credentialDefinitionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.credentialDefinitionId,
                                    referencedTable: $$SkillsTableReferences
                                        ._credentialDefinitionIdTable(db),
                                    referencedColumn: $$SkillsTableReferences
                                        ._credentialDefinitionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (skillTemplateToolsRefs)
                        await $_getPrefetchedData<
                          SkillsTable,
                          $SkillsTable,
                          SkillTemplateToolsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SkillsTableReferences
                              ._skillTemplateToolsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SkillsTableReferences(
                                db,
                                table,
                                p0,
                              ).skillTemplateToolsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.skillId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (conversationSkillsRefs)
                        await $_getPrefetchedData<
                          SkillsTable,
                          $SkillsTable,
                          ConversationSkillsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SkillsTableReferences
                              ._conversationSkillsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SkillsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationSkillsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceSkillId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SkillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkillsTable,
      SkillsTable,
      $$SkillsTableFilterComposer,
      $$SkillsTableOrderingComposer,
      $$SkillsTableAnnotationComposer,
      $$SkillsTableCreateCompanionBuilder,
      $$SkillsTableUpdateCompanionBuilder,
      (SkillsTable, $$SkillsTableReferences),
      SkillsTable,
      PrefetchHooks Function({
        bool workspaceId,
        bool credentialDefinitionId,
        bool skillTemplateToolsRefs,
        bool conversationSkillsRefs,
      })
    >;
typedef $$SkillTemplateToolsTableCreateCompanionBuilder =
    SkillTemplateToolsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String skillId,
      required SkillTemplateToolTypeTable templateType,
      required String title,
      Value<String> description,
      required String slug,
      required String templateJson,
      required String inputsJson,
      Value<bool> requiresCredential,
      Value<bool> isEnabled,
      Value<int> rowid,
    });
typedef $$SkillTemplateToolsTableUpdateCompanionBuilder =
    SkillTemplateToolsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> skillId,
      Value<SkillTemplateToolTypeTable> templateType,
      Value<String> title,
      Value<String> description,
      Value<String> slug,
      Value<String> templateJson,
      Value<String> inputsJson,
      Value<bool> requiresCredential,
      Value<bool> isEnabled,
      Value<int> rowid,
    });

final class $$SkillTemplateToolsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SkillTemplateToolsTable,
          SkillTemplateToolsTable
        > {
  $$SkillTemplateToolsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SkillsTable _skillIdTable(_$AppDatabase db) => db.skills.createAlias(
    $_aliasNameGenerator(db.skillTemplateTools.skillId, db.skills.id),
  );

  $$SkillsTableProcessedTableManager get skillId {
    final $_column = $_itemColumn<String>('skill_id')!;

    final manager = $$SkillsTableTableManager(
      $_db,
      $_db.skills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_skillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SkillTemplateToolsTableFilterComposer
    extends Composer<_$AppDatabase, $SkillTemplateToolsTable> {
  $$SkillTemplateToolsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    SkillTemplateToolTypeTable,
    SkillTemplateToolTypeTable,
    String
  >
  get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresCredential => $composableBuilder(
    column: $table.requiresCredential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$SkillsTableFilterComposer get skillId {
    final $$SkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableFilterComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SkillTemplateToolsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkillTemplateToolsTable> {
  $$SkillTemplateToolsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresCredential => $composableBuilder(
    column: $table.requiresCredential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$SkillsTableOrderingComposer get skillId {
    final $$SkillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableOrderingComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SkillTemplateToolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkillTemplateToolsTable> {
  $$SkillTemplateToolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillTemplateToolTypeTable, String>
  get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiresCredential => $composableBuilder(
    column: $table.requiresCredential,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  $$SkillsTableAnnotationComposer get skillId {
    final $$SkillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableAnnotationComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SkillTemplateToolsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkillTemplateToolsTable,
          SkillTemplateToolsTable,
          $$SkillTemplateToolsTableFilterComposer,
          $$SkillTemplateToolsTableOrderingComposer,
          $$SkillTemplateToolsTableAnnotationComposer,
          $$SkillTemplateToolsTableCreateCompanionBuilder,
          $$SkillTemplateToolsTableUpdateCompanionBuilder,
          (SkillTemplateToolsTable, $$SkillTemplateToolsTableReferences),
          SkillTemplateToolsTable,
          PrefetchHooks Function({bool skillId})
        > {
  $$SkillTemplateToolsTableTableManager(
    _$AppDatabase db,
    $SkillTemplateToolsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillTemplateToolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkillTemplateToolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkillTemplateToolsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> skillId = const Value.absent(),
                Value<SkillTemplateToolTypeTable> templateType =
                    const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> templateJson = const Value.absent(),
                Value<String> inputsJson = const Value.absent(),
                Value<bool> requiresCredential = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillTemplateToolsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                skillId: skillId,
                templateType: templateType,
                title: title,
                description: description,
                slug: slug,
                templateJson: templateJson,
                inputsJson: inputsJson,
                requiresCredential: requiresCredential,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String skillId,
                required SkillTemplateToolTypeTable templateType,
                required String title,
                Value<String> description = const Value.absent(),
                required String slug,
                required String templateJson,
                required String inputsJson,
                Value<bool> requiresCredential = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillTemplateToolsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                skillId: skillId,
                templateType: templateType,
                title: title,
                description: description,
                slug: slug,
                templateJson: templateJson,
                inputsJson: inputsJson,
                requiresCredential: requiresCredential,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SkillTemplateToolsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({skillId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (skillId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.skillId,
                                referencedTable:
                                    $$SkillTemplateToolsTableReferences
                                        ._skillIdTable(db),
                                referencedColumn:
                                    $$SkillTemplateToolsTableReferences
                                        ._skillIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SkillTemplateToolsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkillTemplateToolsTable,
      SkillTemplateToolsTable,
      $$SkillTemplateToolsTableFilterComposer,
      $$SkillTemplateToolsTableOrderingComposer,
      $$SkillTemplateToolsTableAnnotationComposer,
      $$SkillTemplateToolsTableCreateCompanionBuilder,
      $$SkillTemplateToolsTableUpdateCompanionBuilder,
      (SkillTemplateToolsTable, $$SkillTemplateToolsTableReferences),
      SkillTemplateToolsTable,
      PrefetchHooks Function({bool skillId})
    >;
typedef $$ConversationSkillsTableCreateCompanionBuilder =
    ConversationSkillsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String conversationId,
      Value<String?> workspaceSkillId,
      Value<String?> appSkillIdentifier,
      Value<bool> isLoaded,
      Value<int> rowid,
    });
typedef $$ConversationSkillsTableUpdateCompanionBuilder =
    ConversationSkillsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> conversationId,
      Value<String?> workspaceSkillId,
      Value<String?> appSkillIdentifier,
      Value<bool> isLoaded,
      Value<int> rowid,
    });

final class $$ConversationSkillsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConversationSkillsTable,
          ConversationSkillsTable
        > {
  $$ConversationSkillsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias(
        $_aliasNameGenerator(
          db.conversationSkills.conversationId,
          db.conversations.id,
        ),
      );

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SkillsTable _workspaceSkillIdTable(_$AppDatabase db) =>
      db.skills.createAlias(
        $_aliasNameGenerator(
          db.conversationSkills.workspaceSkillId,
          db.skills.id,
        ),
      );

  $$SkillsTableProcessedTableManager? get workspaceSkillId {
    final $_column = $_itemColumn<String>('workspace_skill_id');
    if ($_column == null) return null;
    final manager = $$SkillsTableTableManager(
      $_db,
      $_db.skills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceSkillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConversationSkillsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationSkillsTable> {
  $$ConversationSkillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appSkillIdentifier => $composableBuilder(
    column: $table.appSkillIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLoaded => $composableBuilder(
    column: $table.isLoaded,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SkillsTableFilterComposer get workspaceSkillId {
    final $$SkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceSkillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableFilterComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationSkillsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationSkillsTable> {
  $$ConversationSkillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appSkillIdentifier => $composableBuilder(
    column: $table.appSkillIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLoaded => $composableBuilder(
    column: $table.isLoaded,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SkillsTableOrderingComposer get workspaceSkillId {
    final $$SkillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceSkillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableOrderingComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationSkillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationSkillsTable> {
  $$ConversationSkillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get appSkillIdentifier => $composableBuilder(
    column: $table.appSkillIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLoaded =>
      $composableBuilder(column: $table.isLoaded, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SkillsTableAnnotationComposer get workspaceSkillId {
    final $$SkillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceSkillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableAnnotationComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationSkillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationSkillsTable,
          ConversationSkillsTable,
          $$ConversationSkillsTableFilterComposer,
          $$ConversationSkillsTableOrderingComposer,
          $$ConversationSkillsTableAnnotationComposer,
          $$ConversationSkillsTableCreateCompanionBuilder,
          $$ConversationSkillsTableUpdateCompanionBuilder,
          (ConversationSkillsTable, $$ConversationSkillsTableReferences),
          ConversationSkillsTable,
          PrefetchHooks Function({bool conversationId, bool workspaceSkillId})
        > {
  $$ConversationSkillsTableTableManager(
    _$AppDatabase db,
    $ConversationSkillsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationSkillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationSkillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationSkillsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String?> workspaceSkillId = const Value.absent(),
                Value<String?> appSkillIdentifier = const Value.absent(),
                Value<bool> isLoaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationSkillsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                conversationId: conversationId,
                workspaceSkillId: workspaceSkillId,
                appSkillIdentifier: appSkillIdentifier,
                isLoaded: isLoaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String conversationId,
                Value<String?> workspaceSkillId = const Value.absent(),
                Value<String?> appSkillIdentifier = const Value.absent(),
                Value<bool> isLoaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationSkillsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                conversationId: conversationId,
                workspaceSkillId: workspaceSkillId,
                appSkillIdentifier: appSkillIdentifier,
                isLoaded: isLoaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationSkillsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({conversationId = false, workspaceSkillId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (conversationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.conversationId,
                                    referencedTable:
                                        $$ConversationSkillsTableReferences
                                            ._conversationIdTable(db),
                                    referencedColumn:
                                        $$ConversationSkillsTableReferences
                                            ._conversationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (workspaceSkillId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceSkillId,
                                    referencedTable:
                                        $$ConversationSkillsTableReferences
                                            ._workspaceSkillIdTable(db),
                                    referencedColumn:
                                        $$ConversationSkillsTableReferences
                                            ._workspaceSkillIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ConversationSkillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationSkillsTable,
      ConversationSkillsTable,
      $$ConversationSkillsTableFilterComposer,
      $$ConversationSkillsTableOrderingComposer,
      $$ConversationSkillsTableAnnotationComposer,
      $$ConversationSkillsTableCreateCompanionBuilder,
      $$ConversationSkillsTableUpdateCompanionBuilder,
      (ConversationSkillsTable, $$ConversationSkillsTableReferences),
      ConversationSkillsTable,
      PrefetchHooks Function({bool conversationId, bool workspaceSkillId})
    >;
typedef $$AppSkillWorkspaceSettingsTableCreateCompanionBuilder =
    AppSkillWorkspaceSettingsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String workspaceId,
      required String appSkillIdentifier,
      Value<bool> isEnabled,
      Value<int> rowid,
    });
typedef $$AppSkillWorkspaceSettingsTableUpdateCompanionBuilder =
    AppSkillWorkspaceSettingsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> workspaceId,
      Value<String> appSkillIdentifier,
      Value<bool> isEnabled,
      Value<int> rowid,
    });

final class $$AppSkillWorkspaceSettingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AppSkillWorkspaceSettingsTable,
          AppSkillWorkspaceSettingsTable
        > {
  $$AppSkillWorkspaceSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(
          db.appSkillWorkspaceSettings.workspaceId,
          db.workspaces.id,
        ),
      );

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AppSkillWorkspaceSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSkillWorkspaceSettingsTable> {
  $$AppSkillWorkspaceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appSkillIdentifier => $composableBuilder(
    column: $table.appSkillIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSkillWorkspaceSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSkillWorkspaceSettingsTable> {
  $$AppSkillWorkspaceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appSkillIdentifier => $composableBuilder(
    column: $table.appSkillIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSkillWorkspaceSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSkillWorkspaceSettingsTable> {
  $$AppSkillWorkspaceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get appSkillIdentifier => $composableBuilder(
    column: $table.appSkillIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSkillWorkspaceSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSkillWorkspaceSettingsTable,
          AppSkillWorkspaceSettingsTable,
          $$AppSkillWorkspaceSettingsTableFilterComposer,
          $$AppSkillWorkspaceSettingsTableOrderingComposer,
          $$AppSkillWorkspaceSettingsTableAnnotationComposer,
          $$AppSkillWorkspaceSettingsTableCreateCompanionBuilder,
          $$AppSkillWorkspaceSettingsTableUpdateCompanionBuilder,
          (
            AppSkillWorkspaceSettingsTable,
            $$AppSkillWorkspaceSettingsTableReferences,
          ),
          AppSkillWorkspaceSettingsTable,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$AppSkillWorkspaceSettingsTableTableManager(
    _$AppDatabase db,
    $AppSkillWorkspaceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSkillWorkspaceSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AppSkillWorkspaceSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AppSkillWorkspaceSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> appSkillIdentifier = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSkillWorkspaceSettingsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                appSkillIdentifier: appSkillIdentifier,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workspaceId,
                required String appSkillIdentifier,
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSkillWorkspaceSettingsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                workspaceId: workspaceId,
                appSkillIdentifier: appSkillIdentifier,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AppSkillWorkspaceSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable:
                                    $$AppSkillWorkspaceSettingsTableReferences
                                        ._workspaceIdTable(db),
                                referencedColumn:
                                    $$AppSkillWorkspaceSettingsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AppSkillWorkspaceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSkillWorkspaceSettingsTable,
      AppSkillWorkspaceSettingsTable,
      $$AppSkillWorkspaceSettingsTableFilterComposer,
      $$AppSkillWorkspaceSettingsTableOrderingComposer,
      $$AppSkillWorkspaceSettingsTableAnnotationComposer,
      $$AppSkillWorkspaceSettingsTableCreateCompanionBuilder,
      $$AppSkillWorkspaceSettingsTableUpdateCompanionBuilder,
      (
        AppSkillWorkspaceSettingsTable,
        $$AppSkillWorkspaceSettingsTableReferences,
      ),
      AppSkillWorkspaceSettingsTable,
      PrefetchHooks Function({bool workspaceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$ServiceConnectionsTableTableManager get serviceConnections =>
      $$ServiceConnectionsTableTableManager(_db, _db.serviceConnections);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(_db, _db.apiModelProviders);
  $$WorkspaceModelSelectionsTableTableManager get workspaceModelSelections =>
      $$WorkspaceModelSelectionsTableTableManager(
        _db,
        _db.workspaceModelSelections,
      );
  $$ApiModelsTableTableManager get apiModels =>
      $$ApiModelsTableTableManager(_db, _db.apiModels);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$McpServersTableTableManager get mcpServers =>
      $$McpServersTableTableManager(_db, _db.mcpServers);
  $$ToolsGroupsTableTableManager get toolsGroups =>
      $$ToolsGroupsTableTableManager(_db, _db.toolsGroups);
  $$ToolsTableTableManager get tools =>
      $$ToolsTableTableManager(_db, _db.tools);
  $$ConversationToolsTableTableManager get conversationTools =>
      $$ConversationToolsTableTableManager(_db, _db.conversationTools);
  $$WorkspaceCompactionSettingsTableTableManager
  get workspaceCompactionSettings =>
      $$WorkspaceCompactionSettingsTableTableManager(
        _db,
        _db.workspaceCompactionSettings,
      );
  $$SkillCredentialDefinitionsTableTableManager
  get skillCredentialDefinitions =>
      $$SkillCredentialDefinitionsTableTableManager(
        _db,
        _db.skillCredentialDefinitions,
      );
  $$SkillsTableTableManager get skills =>
      $$SkillsTableTableManager(_db, _db.skills);
  $$SkillTemplateToolsTableTableManager get skillTemplateTools =>
      $$SkillTemplateToolsTableTableManager(_db, _db.skillTemplateTools);
  $$ConversationSkillsTableTableManager get conversationSkills =>
      $$ConversationSkillsTableTableManager(_db, _db.conversationSkills);
  $$AppSkillWorkspaceSettingsTableTableManager get appSkillWorkspaceSettings =>
      $$AppSkillWorkspaceSettingsTableTableManager(
        _db,
        _db.appSkillWorkspaceSettings,
      );
}
