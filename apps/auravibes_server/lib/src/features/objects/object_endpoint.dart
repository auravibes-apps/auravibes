import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'object_scanner.dart';
import 'object_store.dart';
import 'object_use_cases.dart';

class ObjectEndpoint extends Endpoint {
  ObjectUseCases get _useCases => ObjectUseCases(
    store: _objectStore,
    scanner: _objectScanner,
  );

  ObjectScanner get _objectScanner {
    final endpoint = Platform.environment['OBJECT_SCANNER_ENDPOINT'];
    if (endpoint == null) return const UnconfiguredObjectScanner();
    return HttpObjectScanner(
      endpoint: Uri.parse(endpoint),
      bearerToken: Platform.environment['OBJECT_SCANNER_BEARER_TOKEN'],
    );
  }

  ObjectStore get _objectStore {
    final endpoint = Platform.environment['OBJECT_STORE_ENDPOINT'];
    if (endpoint == null) return const UnconfiguredObjectStore();
    return HttpObjectStore(
      endpoint: Uri.parse(endpoint),
      bearerToken: Platform.environment['OBJECT_STORE_BEARER_TOKEN'],
    );
  }

  Future<BeginUploadResult> beginUpload(
    Session session,
    BeginUploadRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.beginUpload(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<ObjectResult> completeUpload(
    Session session,
    CompleteUploadRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.completeUpload(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<GetDownloadResult> getDownload(
    Session session,
    GetDownloadRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.getDownload(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<void> delete(Session session, DeleteObjectRequest request) async {
    final account = await const AuthenticatedAccountResolver()(session);
    await _useCases.delete(session, userId: account.userId, request: request);
  }
}
