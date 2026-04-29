// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_model_providers_dao.dart';

// ignore_for_file: type=lint
mixin _$ApiModelProvidersDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiModelProvidersTable get apiModelProviders =>
      attachedDatabase.apiModelProviders;
  ApiModelProvidersDaoManager get managers => ApiModelProvidersDaoManager(this);
}

class ApiModelProvidersDaoManager {
  final _$ApiModelProvidersDaoMixin _db;
  ApiModelProvidersDaoManager(this._db);
  $$ApiModelProvidersTableTableManager get apiModelProviders =>
      $$ApiModelProvidersTableTableManager(
        _db.attachedDatabase,
        _db.apiModelProviders,
      );
}
