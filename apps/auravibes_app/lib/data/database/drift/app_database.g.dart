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

class $CredentialsTable extends Credentials
    with TableInfo<$CredentialsTable, CredentialsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CredentialsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES api_models (id)',
    ),
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
  static const VerificationMeta _keyValueMeta = const VerificationMeta(
    'keyValue',
  );
  @override
  late final GeneratedColumn<String> keyValue = GeneratedColumn<String>(
    'key_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
      'REFERENCES workspaces (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    modelId,
    url,
    keyValue,
    workspaceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<CredentialsTable> instance, {
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
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('key_value')) {
      context.handle(
        _keyValueMeta,
        keyValue.isAcceptableOrUnknown(data['key_value']!, _keyValueMeta),
      );
    } else if (isInserting) {
      context.missing(_keyValueMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  CredentialsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CredentialsTable(
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
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      keyValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_value'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
    );
  }

  @override
  $CredentialsTable createAlias(String alias) {
    return $CredentialsTable(attachedDatabase, alias);
  }
}

class CredentialsTable extends DataClass
    implements Insertable<CredentialsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// Human-readable name of the chat model
  final String name;
  final String modelId;

  /// URL for remote chat models, null for default urls
  final String? url;

  /// UUID reference to securely stored API key
  final String keyValue;
  final String workspaceId;
  const CredentialsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.modelId,
    this.url,
    required this.keyValue,
    required this.workspaceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['model_id'] = Variable<String>(modelId);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['key_value'] = Variable<String>(keyValue);
    map['workspace_id'] = Variable<String>(workspaceId);
    return map;
  }

  CredentialsCompanion toCompanion(bool nullToAbsent) {
    return CredentialsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      modelId: Value(modelId),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      keyValue: Value(keyValue),
      workspaceId: Value(workspaceId),
    );
  }

  factory CredentialsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CredentialsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      modelId: serializer.fromJson<String>(json['modelId']),
      url: serializer.fromJson<String?>(json['url']),
      keyValue: serializer.fromJson<String>(json['keyValue']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
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
      'modelId': serializer.toJson<String>(modelId),
      'url': serializer.toJson<String?>(url),
      'keyValue': serializer.toJson<String>(keyValue),
      'workspaceId': serializer.toJson<String>(workspaceId),
    };
  }

  CredentialsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? modelId,
    Value<String?> url = const Value.absent(),
    String? keyValue,
    String? workspaceId,
  }) => CredentialsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    modelId: modelId ?? this.modelId,
    url: url.present ? url.value : this.url,
    keyValue: keyValue ?? this.keyValue,
    workspaceId: workspaceId ?? this.workspaceId,
  );
  CredentialsTable copyWithCompanion(CredentialsCompanion data) {
    return CredentialsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      url: data.url.present ? data.url.value : this.url,
      keyValue: data.keyValue.present ? data.keyValue.value : this.keyValue,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CredentialsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('modelId: $modelId, ')
          ..write('url: $url, ')
          ..write('keyValue: $keyValue, ')
          ..write('workspaceId: $workspaceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    modelId,
    url,
    keyValue,
    workspaceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CredentialsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.modelId == this.modelId &&
          other.url == this.url &&
          other.keyValue == this.keyValue &&
          other.workspaceId == this.workspaceId);
}

class CredentialsCompanion extends UpdateCompanion<CredentialsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String> modelId;
  final Value<String?> url;
  final Value<String> keyValue;
  final Value<String> workspaceId;
  final Value<int> rowid;
  const CredentialsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.modelId = const Value.absent(),
    this.url = const Value.absent(),
    this.keyValue = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CredentialsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    required String modelId,
    this.url = const Value.absent(),
    required String keyValue,
    required String workspaceId,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       modelId = Value(modelId),
       keyValue = Value(keyValue),
       workspaceId = Value(workspaceId);
  static Insertable<CredentialsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? modelId,
    Expression<String>? url,
    Expression<String>? keyValue,
    Expression<String>? workspaceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (modelId != null) 'model_id': modelId,
      if (url != null) 'url': url,
      if (keyValue != null) 'key_value': keyValue,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CredentialsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String>? modelId,
    Value<String?>? url,
    Value<String>? keyValue,
    Value<String>? workspaceId,
    Value<int>? rowid,
  }) {
    return CredentialsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      modelId: modelId ?? this.modelId,
      url: url ?? this.url,
      keyValue: keyValue ?? this.keyValue,
      workspaceId: workspaceId ?? this.workspaceId,
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
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (keyValue.present) {
      map['key_value'] = Variable<String>(keyValue.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredentialsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('modelId: $modelId, ')
          ..write('url: $url, ')
          ..write('keyValue: $keyValue, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CredentialModelsTable extends CredentialModels
    with TableInfo<$CredentialModelsTable, CredentialModelsTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CredentialModelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _credentialsIdMeta = const VerificationMeta(
    'credentialsId',
  );
  @override
  late final GeneratedColumn<String> credentialsId = GeneratedColumn<String>(
    'credentials_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credentials (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    modelId,
    credentialsId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credential_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<CredentialModelsTable> instance, {
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
    if (data.containsKey('credentials_id')) {
      context.handle(
        _credentialsIdMeta,
        credentialsId.isAcceptableOrUnknown(
          data['credentials_id']!,
          _credentialsIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialsIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  CredentialModelsTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CredentialModelsTable(
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
      credentialsId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credentials_id'],
      )!,
    );
  }

  @override
  $CredentialModelsTable createAlias(String alias) {
    return $CredentialModelsTable(attachedDatabase, alias);
  }
}

class CredentialModelsTable extends DataClass
    implements Insertable<CredentialModelsTable> {
  ///Primary key column as string
  final String id;

  /// when was created timestamp
  final DateTime createdAt;

  /// when was last updated timestamp
  final DateTime updatedAt;

  /// model unique identifier
  final String modelId;
  final String credentialsId;
  const CredentialModelsTable({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.modelId,
    required this.credentialsId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['model_id'] = Variable<String>(modelId);
    map['credentials_id'] = Variable<String>(credentialsId);
    return map;
  }

  CredentialModelsCompanion toCompanion(bool nullToAbsent) {
    return CredentialModelsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      modelId: Value(modelId),
      credentialsId: Value(credentialsId),
    );
  }

  factory CredentialModelsTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CredentialModelsTable(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      modelId: serializer.fromJson<String>(json['modelId']),
      credentialsId: serializer.fromJson<String>(json['credentialsId']),
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
      'credentialsId': serializer.toJson<String>(credentialsId),
    };
  }

  CredentialModelsTable copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? modelId,
    String? credentialsId,
  }) => CredentialModelsTable(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    modelId: modelId ?? this.modelId,
    credentialsId: credentialsId ?? this.credentialsId,
  );
  CredentialModelsTable copyWithCompanion(CredentialModelsCompanion data) {
    return CredentialModelsTable(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      credentialsId: data.credentialsId.present
          ? data.credentialsId.value
          : this.credentialsId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CredentialModelsTable(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('modelId: $modelId, ')
          ..write('credentialsId: $credentialsId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, modelId, credentialsId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CredentialModelsTable &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.modelId == this.modelId &&
          other.credentialsId == this.credentialsId);
}

class CredentialModelsCompanion extends UpdateCompanion<CredentialModelsTable> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> modelId;
  final Value<String> credentialsId;
  final Value<int> rowid;
  const CredentialModelsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.modelId = const Value.absent(),
    this.credentialsId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CredentialModelsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String modelId,
    required String credentialsId,
    this.rowid = const Value.absent(),
  }) : modelId = Value(modelId),
       credentialsId = Value(credentialsId);
  static Insertable<CredentialModelsTable> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? modelId,
    Expression<String>? credentialsId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (modelId != null) 'model_id': modelId,
      if (credentialsId != null) 'credentials_id': credentialsId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CredentialModelsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? modelId,
    Value<String>? credentialsId,
    Value<int>? rowid,
  }) {
    return CredentialModelsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modelId: modelId ?? this.modelId,
      credentialsId: credentialsId ?? this.credentialsId,
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
    if (credentialsId.present) {
      map['credentials_id'] = Variable<String>(credentialsId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredentialModelsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('modelId: $modelId, ')
          ..write('credentialsId: $credentialsId, ')
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
      'REFERENCES workspaces (id)',
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
      'REFERENCES credential_models (id)',
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
      'REFERENCES conversations (id)',
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
      'REFERENCES workspaces (id)',
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
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tokenEndpointMeta = const VerificationMeta(
    'tokenEndpoint',
  );
  @override
  late final GeneratedColumn<String> tokenEndpoint = GeneratedColumn<String>(
    'token_endpoint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorizationEndpointMeta =
      const VerificationMeta('authorizationEndpoint');
  @override
  late final GeneratedColumn<String> authorizationEndpoint =
      GeneratedColumn<String>(
        'authorization_endpoint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bearerTokenMeta = const VerificationMeta(
    'bearerToken',
  );
  @override
  late final GeneratedColumn<String> bearerToken = GeneratedColumn<String>(
    'bearer_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useHttp2Meta = const VerificationMeta(
    'useHttp2',
  );
  @override
  late final GeneratedColumn<bool> useHttp2 = GeneratedColumn<bool>(
    'use_http2',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_http2" IN (0, 1))',
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
    name,
    url,
    transport,
    authenticationType,
    description,
    clientId,
    tokenEndpoint,
    authorizationEndpoint,
    bearerToken,
    useHttp2,
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
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('token_endpoint')) {
      context.handle(
        _tokenEndpointMeta,
        tokenEndpoint.isAcceptableOrUnknown(
          data['token_endpoint']!,
          _tokenEndpointMeta,
        ),
      );
    }
    if (data.containsKey('authorization_endpoint')) {
      context.handle(
        _authorizationEndpointMeta,
        authorizationEndpoint.isAcceptableOrUnknown(
          data['authorization_endpoint']!,
          _authorizationEndpointMeta,
        ),
      );
    }
    if (data.containsKey('bearer_token')) {
      context.handle(
        _bearerTokenMeta,
        bearerToken.isAcceptableOrUnknown(
          data['bearer_token']!,
          _bearerTokenMeta,
        ),
      );
    }
    if (data.containsKey('use_http2')) {
      context.handle(
        _useHttp2Meta,
        useHttp2.isAcceptableOrUnknown(data['use_http2']!, _useHttp2Meta),
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
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      tokenEndpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_endpoint'],
      ),
      authorizationEndpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authorization_endpoint'],
      ),
      bearerToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bearer_token'],
      ),
      useHttp2: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_http2'],
      )!,
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

  static JsonTypeConverter2<McpTransportType, String, String>
  $convertertransport = const EnumNameConverter<McpTransportType>(
    McpTransportType.values,
  );
  static JsonTypeConverter2<McpAuthenticationType, String, String>
  $converterauthenticationType = const EnumNameConverter<McpAuthenticationType>(
    McpAuthenticationType.values,
  );
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

  /// OAuth client ID (required when authenticationType is oauth)
  final String? clientId;

  /// OAuth token endpoint URL (required when authenticationType is oauth)
  final String? tokenEndpoint;

  /// OAuth authorization endpoint URL
  /// (required when authenticationType is oauth)
  final String? authorizationEndpoint;

  /// Bearer token (required when authenticationType is bearerToken)
  /// TODO: Consider moving to secure storage instead of database
  final String? bearerToken;

  /// Whether to use HTTP/2 (only applicable for streamableHttp transport)
  final bool useHttp2;

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
    this.clientId,
    this.tokenEndpoint,
    this.authorizationEndpoint,
    this.bearerToken,
    required this.useHttp2,
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
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || tokenEndpoint != null) {
      map['token_endpoint'] = Variable<String>(tokenEndpoint);
    }
    if (!nullToAbsent || authorizationEndpoint != null) {
      map['authorization_endpoint'] = Variable<String>(authorizationEndpoint);
    }
    if (!nullToAbsent || bearerToken != null) {
      map['bearer_token'] = Variable<String>(bearerToken);
    }
    map['use_http2'] = Variable<bool>(useHttp2);
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
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      tokenEndpoint: tokenEndpoint == null && nullToAbsent
          ? const Value.absent()
          : Value(tokenEndpoint),
      authorizationEndpoint: authorizationEndpoint == null && nullToAbsent
          ? const Value.absent()
          : Value(authorizationEndpoint),
      bearerToken: bearerToken == null && nullToAbsent
          ? const Value.absent()
          : Value(bearerToken),
      useHttp2: Value(useHttp2),
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
        serializer.fromJson<String>(json['transport']),
      ),
      authenticationType: $McpServersTable.$converterauthenticationType
          .fromJson(serializer.fromJson<String>(json['authenticationType'])),
      description: serializer.fromJson<String?>(json['description']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      tokenEndpoint: serializer.fromJson<String?>(json['tokenEndpoint']),
      authorizationEndpoint: serializer.fromJson<String?>(
        json['authorizationEndpoint'],
      ),
      bearerToken: serializer.fromJson<String?>(json['bearerToken']),
      useHttp2: serializer.fromJson<bool>(json['useHttp2']),
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
      'transport': serializer.toJson<String>(
        $McpServersTable.$convertertransport.toJson(transport),
      ),
      'authenticationType': serializer.toJson<String>(
        $McpServersTable.$converterauthenticationType.toJson(
          authenticationType,
        ),
      ),
      'description': serializer.toJson<String?>(description),
      'clientId': serializer.toJson<String?>(clientId),
      'tokenEndpoint': serializer.toJson<String?>(tokenEndpoint),
      'authorizationEndpoint': serializer.toJson<String?>(
        authorizationEndpoint,
      ),
      'bearerToken': serializer.toJson<String?>(bearerToken),
      'useHttp2': serializer.toJson<bool>(useHttp2),
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
    Value<String?> clientId = const Value.absent(),
    Value<String?> tokenEndpoint = const Value.absent(),
    Value<String?> authorizationEndpoint = const Value.absent(),
    Value<String?> bearerToken = const Value.absent(),
    bool? useHttp2,
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
    clientId: clientId.present ? clientId.value : this.clientId,
    tokenEndpoint: tokenEndpoint.present
        ? tokenEndpoint.value
        : this.tokenEndpoint,
    authorizationEndpoint: authorizationEndpoint.present
        ? authorizationEndpoint.value
        : this.authorizationEndpoint,
    bearerToken: bearerToken.present ? bearerToken.value : this.bearerToken,
    useHttp2: useHttp2 ?? this.useHttp2,
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
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      tokenEndpoint: data.tokenEndpoint.present
          ? data.tokenEndpoint.value
          : this.tokenEndpoint,
      authorizationEndpoint: data.authorizationEndpoint.present
          ? data.authorizationEndpoint.value
          : this.authorizationEndpoint,
      bearerToken: data.bearerToken.present
          ? data.bearerToken.value
          : this.bearerToken,
      useHttp2: data.useHttp2.present ? data.useHttp2.value : this.useHttp2,
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
          ..write('clientId: $clientId, ')
          ..write('tokenEndpoint: $tokenEndpoint, ')
          ..write('authorizationEndpoint: $authorizationEndpoint, ')
          ..write('bearerToken: $bearerToken, ')
          ..write('useHttp2: $useHttp2, ')
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
    clientId,
    tokenEndpoint,
    authorizationEndpoint,
    bearerToken,
    useHttp2,
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
          other.clientId == this.clientId &&
          other.tokenEndpoint == this.tokenEndpoint &&
          other.authorizationEndpoint == this.authorizationEndpoint &&
          other.bearerToken == this.bearerToken &&
          other.useHttp2 == this.useHttp2 &&
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
  final Value<String?> clientId;
  final Value<String?> tokenEndpoint;
  final Value<String?> authorizationEndpoint;
  final Value<String?> bearerToken;
  final Value<bool> useHttp2;
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
    this.clientId = const Value.absent(),
    this.tokenEndpoint = const Value.absent(),
    this.authorizationEndpoint = const Value.absent(),
    this.bearerToken = const Value.absent(),
    this.useHttp2 = const Value.absent(),
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
    this.clientId = const Value.absent(),
    this.tokenEndpoint = const Value.absent(),
    this.authorizationEndpoint = const Value.absent(),
    this.bearerToken = const Value.absent(),
    this.useHttp2 = const Value.absent(),
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
    Expression<String>? clientId,
    Expression<String>? tokenEndpoint,
    Expression<String>? authorizationEndpoint,
    Expression<String>? bearerToken,
    Expression<bool>? useHttp2,
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
      if (clientId != null) 'client_id': clientId,
      if (tokenEndpoint != null) 'token_endpoint': tokenEndpoint,
      if (authorizationEndpoint != null)
        'authorization_endpoint': authorizationEndpoint,
      if (bearerToken != null) 'bearer_token': bearerToken,
      if (useHttp2 != null) 'use_http2': useHttp2,
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
    Value<String?>? clientId,
    Value<String?>? tokenEndpoint,
    Value<String?>? authorizationEndpoint,
    Value<String?>? bearerToken,
    Value<bool>? useHttp2,
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
      clientId: clientId ?? this.clientId,
      tokenEndpoint: tokenEndpoint ?? this.tokenEndpoint,
      authorizationEndpoint:
          authorizationEndpoint ?? this.authorizationEndpoint,
      bearerToken: bearerToken ?? this.bearerToken,
      useHttp2: useHttp2 ?? this.useHttp2,
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
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (tokenEndpoint.present) {
      map['token_endpoint'] = Variable<String>(tokenEndpoint.value);
    }
    if (authorizationEndpoint.present) {
      map['authorization_endpoint'] = Variable<String>(
        authorizationEndpoint.value,
      );
    }
    if (bearerToken.present) {
      map['bearer_token'] = Variable<String>(bearerToken.value);
    }
    if (useHttp2.present) {
      map['use_http2'] = Variable<bool>(useHttp2.value);
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
          ..write('clientId: $clientId, ')
          ..write('tokenEndpoint: $tokenEndpoint, ')
          ..write('authorizationEndpoint: $authorizationEndpoint, ')
          ..write('bearerToken: $bearerToken, ')
          ..write('useHttp2: $useHttp2, ')
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
      'REFERENCES workspaces (id)',
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
      'REFERENCES workspaces (id)',
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
      'REFERENCES conversations (id)',
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
      'REFERENCES tools (id)',
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $ApiModelProvidersTable apiModelProviders =
      $ApiModelProvidersTable(this);
  late final $ApiModelsTable apiModels = $ApiModelsTable(this);
  late final $CredentialsTable credentials = $CredentialsTable(this);
  late final $CredentialModelsTable credentialModels = $CredentialModelsTable(
    this,
  );
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $McpServersTable mcpServers = $McpServersTable(this);
  late final $ToolsGroupsTable toolsGroups = $ToolsGroupsTable(this);
  late final $ToolsTable tools = $ToolsTable(this);
  late final $ConversationToolsTable conversationTools =
      $ConversationToolsTable(this);
  late final WorkspaceDao workspaceDao = WorkspaceDao(this as AppDatabase);
  late final CredentialsDao credentialsDao = CredentialsDao(
    this as AppDatabase,
  );
  late final CredentialModelsDao credentialModelsDao = CredentialModelsDao(
    this as AppDatabase,
  );
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    apiModelProviders,
    apiModels,
    credentials,
    credentialModels,
    conversations,
    messages,
    mcpServers,
    toolsGroups,
    tools,
    conversationTools,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mcp_servers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tools_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tools_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tools', kind: UpdateKind.delete)],
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

  static MultiTypedResultKey<$CredentialsTable, List<CredentialsTable>>
  _credentialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentials,
    aliasName: $_aliasNameGenerator(
      db.workspaces.id,
      db.credentials.workspaceId,
    ),
  );

  $$CredentialsTableProcessedTableManager get credentialsRefs {
    final manager = $$CredentialsTableTableManager(
      $_db,
      $_db.credentials,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_credentialsRefsTable($_db));
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

  Expression<bool> credentialsRefs(
    Expression<bool> Function($$CredentialsTableFilterComposer f) f,
  ) {
    final $$CredentialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableFilterComposer(
            $db: $db,
            $table: $db.credentials,
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

  Expression<T> credentialsRefs<T extends Object>(
    Expression<T> Function($$CredentialsTableAnnotationComposer a) f,
  ) {
    final $$CredentialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentials,
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
            bool credentialsRefs,
            bool conversationsRefs,
            bool mcpServersRefs,
            bool toolsGroupsRefs,
            bool toolsRefs,
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
                credentialsRefs = false,
                conversationsRefs = false,
                mcpServersRefs = false,
                toolsGroupsRefs = false,
                toolsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (credentialsRefs) db.credentials,
                    if (conversationsRefs) db.conversations,
                    if (mcpServersRefs) db.mcpServers,
                    if (toolsGroupsRefs) db.toolsGroups,
                    if (toolsRefs) db.tools,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (credentialsRefs)
                        await $_getPrefetchedData<
                          WorkspacesTable,
                          $WorkspacesTable,
                          CredentialsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._credentialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialsRefs,
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
        bool credentialsRefs,
        bool conversationsRefs,
        bool mcpServersRefs,
        bool toolsGroupsRefs,
        bool toolsRefs,
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

  static MultiTypedResultKey<
    $CredentialModelsTable,
    List<CredentialModelsTable>
  >
  _credentialModelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentialModels,
    aliasName: $_aliasNameGenerator(
      db.apiModelProviders.id,
      db.credentialModels.modelId,
    ),
  );

  $$CredentialModelsTableProcessedTableManager get credentialModelsRefs {
    final manager = $$CredentialModelsTableTableManager(
      $_db,
      $_db.credentialModels,
    ).filter((f) => f.modelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _credentialModelsRefsTable($_db),
    );
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

  Expression<bool> credentialModelsRefs(
    Expression<bool> Function($$CredentialModelsTableFilterComposer f) f,
  ) {
    final $$CredentialModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentialModels,
      getReferencedColumn: (t) => t.modelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialModelsTableFilterComposer(
            $db: $db,
            $table: $db.credentialModels,
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

  Expression<T> credentialModelsRefs<T extends Object>(
    Expression<T> Function($$CredentialModelsTableAnnotationComposer a) f,
  ) {
    final $$CredentialModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentialModels,
      getReferencedColumn: (t) => t.modelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentialModels,
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
            bool apiModelsRefs,
            bool credentialModelsRefs,
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
              ({apiModelsRefs = false, credentialModelsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (apiModelsRefs) db.apiModels,
                    if (credentialModelsRefs) db.credentialModels,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
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
                      if (credentialModelsRefs)
                        await $_getPrefetchedData<
                          ApiModelProvidersTable,
                          $ApiModelProvidersTable,
                          CredentialModelsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ApiModelProvidersTableReferences
                              ._credentialModelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ApiModelProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialModelsRefs,
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
      PrefetchHooks Function({bool apiModelsRefs, bool credentialModelsRefs})
    >;
typedef $$ApiModelsTableCreateCompanionBuilder =
    ApiModelsCompanion Function({
      required String modelProvider,
      required String id,
      required String name,
      Value<List<String>?> modalitiesInput,
      Value<List<String>?> modalitiesOuput,
      Value<bool?> openWeights,
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

  static MultiTypedResultKey<$CredentialsTable, List<CredentialsTable>>
  _credentialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentials,
    aliasName: $_aliasNameGenerator(db.apiModels.id, db.credentials.modelId),
  );

  $$CredentialsTableProcessedTableManager get credentialsRefs {
    final manager = $$CredentialsTableTableManager(
      $_db,
      $_db.credentials,
    ).filter((f) => f.modelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_credentialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> credentialsRefs(
    Expression<bool> Function($$CredentialsTableFilterComposer f) f,
  ) {
    final $$CredentialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.modelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableFilterComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> credentialsRefs<T extends Object>(
    Expression<T> Function($$CredentialsTableAnnotationComposer a) f,
  ) {
    final $$CredentialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.modelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
          PrefetchHooks Function({bool modelProvider, bool credentialsRefs})
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
          prefetchHooksCallback:
              ({modelProvider = false, credentialsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (credentialsRefs) db.credentials,
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
                    return [
                      if (credentialsRefs)
                        await $_getPrefetchedData<
                          ApiModelsTable,
                          $ApiModelsTable,
                          CredentialsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ApiModelsTableReferences
                              ._credentialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ApiModelsTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialsRefs,
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
      PrefetchHooks Function({bool modelProvider, bool credentialsRefs})
    >;
typedef $$CredentialsTableCreateCompanionBuilder =
    CredentialsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String name,
      required String modelId,
      Value<String?> url,
      required String keyValue,
      required String workspaceId,
      Value<int> rowid,
    });
typedef $$CredentialsTableUpdateCompanionBuilder =
    CredentialsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> name,
      Value<String> modelId,
      Value<String?> url,
      Value<String> keyValue,
      Value<String> workspaceId,
      Value<int> rowid,
    });

final class $$CredentialsTableReferences
    extends BaseReferences<_$AppDatabase, $CredentialsTable, CredentialsTable> {
  $$CredentialsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ApiModelsTable _modelIdTable(_$AppDatabase db) =>
      db.apiModels.createAlias(
        $_aliasNameGenerator(db.credentials.modelId, db.apiModels.id),
      );

  $$ApiModelsTableProcessedTableManager get modelId {
    final $_column = $_itemColumn<String>('model_id')!;

    final manager = $$ApiModelsTableTableManager(
      $_db,
      $_db.apiModels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(db.credentials.workspaceId, db.workspaces.id),
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
    $CredentialModelsTable,
    List<CredentialModelsTable>
  >
  _credentialModelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.credentialModels,
    aliasName: $_aliasNameGenerator(
      db.credentials.id,
      db.credentialModels.credentialsId,
    ),
  );

  $$CredentialModelsTableProcessedTableManager get credentialModelsRefs {
    final manager = $$CredentialModelsTableTableManager(
      $_db,
      $_db.credentialModels,
    ).filter((f) => f.credentialsId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _credentialModelsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CredentialsTableFilterComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableFilterComposer({
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

  ColumnFilters<String> get keyValue => $composableBuilder(
    column: $table.keyValue,
    builder: (column) => ColumnFilters(column),
  );

  $$ApiModelsTableFilterComposer get modelId {
    final $$ApiModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.apiModels,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

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

  Expression<bool> credentialModelsRefs(
    Expression<bool> Function($$CredentialModelsTableFilterComposer f) f,
  ) {
    final $$CredentialModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentialModels,
      getReferencedColumn: (t) => t.credentialsId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialModelsTableFilterComposer(
            $db: $db,
            $table: $db.credentialModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CredentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableOrderingComposer({
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

  ColumnOrderings<String> get keyValue => $composableBuilder(
    column: $table.keyValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$ApiModelsTableOrderingComposer get modelId {
    final $$ApiModelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.apiModels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ApiModelsTableOrderingComposer(
            $db: $db,
            $table: $db.apiModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$CredentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CredentialsTable> {
  $$CredentialsTableAnnotationComposer({
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

  GeneratedColumn<String> get keyValue =>
      $composableBuilder(column: $table.keyValue, builder: (column) => column);

  $$ApiModelsTableAnnotationComposer get modelId {
    final $$ApiModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.apiModels,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

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

  Expression<T> credentialModelsRefs<T extends Object>(
    Expression<T> Function($$CredentialModelsTableAnnotationComposer a) f,
  ) {
    final $$CredentialModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.credentialModels,
      getReferencedColumn: (t) => t.credentialsId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentialModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CredentialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CredentialsTable,
          CredentialsTable,
          $$CredentialsTableFilterComposer,
          $$CredentialsTableOrderingComposer,
          $$CredentialsTableAnnotationComposer,
          $$CredentialsTableCreateCompanionBuilder,
          $$CredentialsTableUpdateCompanionBuilder,
          (CredentialsTable, $$CredentialsTableReferences),
          CredentialsTable,
          PrefetchHooks Function({
            bool modelId,
            bool workspaceId,
            bool credentialModelsRefs,
          })
        > {
  $$CredentialsTableTableManager(_$AppDatabase db, $CredentialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CredentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CredentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CredentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String> keyValue = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CredentialsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                modelId: modelId,
                url: url,
                keyValue: keyValue,
                workspaceId: workspaceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                required String modelId,
                Value<String?> url = const Value.absent(),
                required String keyValue,
                required String workspaceId,
                Value<int> rowid = const Value.absent(),
              }) => CredentialsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                modelId: modelId,
                url: url,
                keyValue: keyValue,
                workspaceId: workspaceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CredentialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                modelId = false,
                workspaceId = false,
                credentialModelsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (credentialModelsRefs) db.credentialModels,
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
                                        $$CredentialsTableReferences
                                            ._modelIdTable(db),
                                    referencedColumn:
                                        $$CredentialsTableReferences
                                            ._modelIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable:
                                        $$CredentialsTableReferences
                                            ._workspaceIdTable(db),
                                    referencedColumn:
                                        $$CredentialsTableReferences
                                            ._workspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (credentialModelsRefs)
                        await $_getPrefetchedData<
                          CredentialsTable,
                          $CredentialsTable,
                          CredentialModelsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CredentialsTableReferences
                              ._credentialModelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CredentialsTableReferences(
                                db,
                                table,
                                p0,
                              ).credentialModelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.credentialsId == item.id,
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

typedef $$CredentialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CredentialsTable,
      CredentialsTable,
      $$CredentialsTableFilterComposer,
      $$CredentialsTableOrderingComposer,
      $$CredentialsTableAnnotationComposer,
      $$CredentialsTableCreateCompanionBuilder,
      $$CredentialsTableUpdateCompanionBuilder,
      (CredentialsTable, $$CredentialsTableReferences),
      CredentialsTable,
      PrefetchHooks Function({
        bool modelId,
        bool workspaceId,
        bool credentialModelsRefs,
      })
    >;
typedef $$CredentialModelsTableCreateCompanionBuilder =
    CredentialModelsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      required String modelId,
      required String credentialsId,
      Value<int> rowid,
    });
typedef $$CredentialModelsTableUpdateCompanionBuilder =
    CredentialModelsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> modelId,
      Value<String> credentialsId,
      Value<int> rowid,
    });

final class $$CredentialModelsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CredentialModelsTable,
          CredentialModelsTable
        > {
  $$CredentialModelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ApiModelProvidersTable _modelIdTable(_$AppDatabase db) =>
      db.apiModelProviders.createAlias(
        $_aliasNameGenerator(
          db.credentialModels.modelId,
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

  static $CredentialsTable _credentialsIdTable(_$AppDatabase db) =>
      db.credentials.createAlias(
        $_aliasNameGenerator(
          db.credentialModels.credentialsId,
          db.credentials.id,
        ),
      );

  $$CredentialsTableProcessedTableManager get credentialsId {
    final $_column = $_itemColumn<String>('credentials_id')!;

    final manager = $$CredentialsTableTableManager(
      $_db,
      $_db.credentials,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_credentialsIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ConversationsTable, List<ConversationsTable>>
  _conversationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.conversations,
    aliasName: $_aliasNameGenerator(
      db.credentialModels.id,
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

class $$CredentialModelsTableFilterComposer
    extends Composer<_$AppDatabase, $CredentialModelsTable> {
  $$CredentialModelsTableFilterComposer({
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

  $$CredentialsTableFilterComposer get credentialsId {
    final $$CredentialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.credentialsId,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableFilterComposer(
            $db: $db,
            $table: $db.credentials,
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

class $$CredentialModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $CredentialModelsTable> {
  $$CredentialModelsTableOrderingComposer({
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

  $$CredentialsTableOrderingComposer get credentialsId {
    final $$CredentialsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.credentialsId,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableOrderingComposer(
            $db: $db,
            $table: $db.credentials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CredentialModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CredentialModelsTable> {
  $$CredentialModelsTableAnnotationComposer({
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

  $$CredentialsTableAnnotationComposer get credentialsId {
    final $$CredentialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.credentialsId,
      referencedTable: $db.credentials,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentials,
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

class $$CredentialModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CredentialModelsTable,
          CredentialModelsTable,
          $$CredentialModelsTableFilterComposer,
          $$CredentialModelsTableOrderingComposer,
          $$CredentialModelsTableAnnotationComposer,
          $$CredentialModelsTableCreateCompanionBuilder,
          $$CredentialModelsTableUpdateCompanionBuilder,
          (CredentialModelsTable, $$CredentialModelsTableReferences),
          CredentialModelsTable,
          PrefetchHooks Function({
            bool modelId,
            bool credentialsId,
            bool conversationsRefs,
          })
        > {
  $$CredentialModelsTableTableManager(
    _$AppDatabase db,
    $CredentialModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CredentialModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CredentialModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CredentialModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<String> credentialsId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CredentialModelsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                modelId: modelId,
                credentialsId: credentialsId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String modelId,
                required String credentialsId,
                Value<int> rowid = const Value.absent(),
              }) => CredentialModelsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                modelId: modelId,
                credentialsId: credentialsId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CredentialModelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                modelId = false,
                credentialsId = false,
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
                                        $$CredentialModelsTableReferences
                                            ._modelIdTable(db),
                                    referencedColumn:
                                        $$CredentialModelsTableReferences
                                            ._modelIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (credentialsId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.credentialsId,
                                    referencedTable:
                                        $$CredentialModelsTableReferences
                                            ._credentialsIdTable(db),
                                    referencedColumn:
                                        $$CredentialModelsTableReferences
                                            ._credentialsIdTable(db)
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
                          CredentialModelsTable,
                          $CredentialModelsTable,
                          ConversationsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CredentialModelsTableReferences
                              ._conversationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CredentialModelsTableReferences(
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

typedef $$CredentialModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CredentialModelsTable,
      CredentialModelsTable,
      $$CredentialModelsTableFilterComposer,
      $$CredentialModelsTableOrderingComposer,
      $$CredentialModelsTableAnnotationComposer,
      $$CredentialModelsTableCreateCompanionBuilder,
      $$CredentialModelsTableUpdateCompanionBuilder,
      (CredentialModelsTable, $$CredentialModelsTableReferences),
      CredentialModelsTable,
      PrefetchHooks Function({
        bool modelId,
        bool credentialsId,
        bool conversationsRefs,
      })
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

  static $CredentialModelsTable _modelIdTable(_$AppDatabase db) =>
      db.credentialModels.createAlias(
        $_aliasNameGenerator(db.conversations.modelId, db.credentialModels.id),
      );

  $$CredentialModelsTableProcessedTableManager? get modelId {
    final $_column = $_itemColumn<String>('model_id');
    if ($_column == null) return null;
    final manager = $$CredentialModelsTableTableManager(
      $_db,
      $_db.credentialModels,
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

  $$CredentialModelsTableFilterComposer get modelId {
    final $$CredentialModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.credentialModels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialModelsTableFilterComposer(
            $db: $db,
            $table: $db.credentialModels,
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

  $$CredentialModelsTableOrderingComposer get modelId {
    final $$CredentialModelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.credentialModels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialModelsTableOrderingComposer(
            $db: $db,
            $table: $db.credentialModels,
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

  $$CredentialModelsTableAnnotationComposer get modelId {
    final $$CredentialModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelId,
      referencedTable: $db.credentialModels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CredentialModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.credentialModels,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messagesRefs) db.messages,
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
      Value<String?> clientId,
      Value<String?> tokenEndpoint,
      Value<String?> authorizationEndpoint,
      Value<String?> bearerToken,
      Value<bool> useHttp2,
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
      Value<String?> clientId,
      Value<String?> tokenEndpoint,
      Value<String?> authorizationEndpoint,
      Value<String?> bearerToken,
      Value<bool> useHttp2,
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenEndpoint => $composableBuilder(
    column: $table.tokenEndpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorizationEndpoint => $composableBuilder(
    column: $table.authorizationEndpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bearerToken => $composableBuilder(
    column: $table.bearerToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useHttp2 => $composableBuilder(
    column: $table.useHttp2,
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenEndpoint => $composableBuilder(
    column: $table.tokenEndpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorizationEndpoint => $composableBuilder(
    column: $table.authorizationEndpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bearerToken => $composableBuilder(
    column: $table.bearerToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useHttp2 => $composableBuilder(
    column: $table.useHttp2,
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

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get tokenEndpoint => $composableBuilder(
    column: $table.tokenEndpoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorizationEndpoint => $composableBuilder(
    column: $table.authorizationEndpoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bearerToken => $composableBuilder(
    column: $table.bearerToken,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useHttp2 =>
      $composableBuilder(column: $table.useHttp2, builder: (column) => column);

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
                Value<String?> clientId = const Value.absent(),
                Value<String?> tokenEndpoint = const Value.absent(),
                Value<String?> authorizationEndpoint = const Value.absent(),
                Value<String?> bearerToken = const Value.absent(),
                Value<bool> useHttp2 = const Value.absent(),
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
                clientId: clientId,
                tokenEndpoint: tokenEndpoint,
                authorizationEndpoint: authorizationEndpoint,
                bearerToken: bearerToken,
                useHttp2: useHttp2,
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
                Value<String?> clientId = const Value.absent(),
                Value<String?> tokenEndpoint = const Value.absent(),
                Value<String?> authorizationEndpoint = const Value.absent(),
                Value<String?> bearerToken = const Value.absent(),
                Value<bool> useHttp2 = const Value.absent(),
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
                clientId: clientId,
                tokenEndpoint: tokenEndpoint,
                authorizationEndpoint: authorizationEndpoint,
                bearerToken: bearerToken,
                useHttp2: useHttp2,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(_db, _db.apiModelProviders);
  $$ApiModelsTableTableManager get apiModels =>
      $$ApiModelsTableTableManager(_db, _db.apiModels);
  $$CredentialsTableTableManager get credentials =>
      $$CredentialsTableTableManager(_db, _db.credentials);
  $$CredentialModelsTableTableManager get credentialModels =>
      $$CredentialModelsTableTableManager(_db, _db.credentialModels);
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
}
