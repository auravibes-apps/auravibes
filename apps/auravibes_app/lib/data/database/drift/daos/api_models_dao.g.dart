// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_models_dao.dart';

// ignore_for_file: type=lint
mixin _$ApiModelsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  $ApiModelsTable get apiModels => attachedDatabase.apiModels;
  ApiModelsDaoManager get managers => ApiModelsDaoManager(this);
}

class ApiModelsDaoManager {
  final _$ApiModelsDaoMixin _db;
  ApiModelsDaoManager(this._db);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(
        _db.attachedDatabase,
        _db.apiModelProviders,
      );
  $$ApiModelsTableTableManager get apiModels =>
      $$ApiModelsTableTableManager(_db.attachedDatabase, _db.apiModels);
}
