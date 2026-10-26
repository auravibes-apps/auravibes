import 'package:auravibes_app/data/repositories/cloud_workspace_asset_repository.dart';
import 'package:auravibes_app/data/repositories/cloud_workspace_file_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_cleanup.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_erasure.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_credential_erasure.dart';
import 'package:auravibes_app/data/repositories/local_workspace_file_repository.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_attachment_adapter.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_asset_file_service.dart';
import 'package:auravibes_app/features/workspaces/usecases/choose_workspace_asset_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_file_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/save_workspace_asset_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/select_workspace_asset_attachment_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_assets_provider.g.dart';

@riverpod
LocalWorkspaceAssetErasure workspaceAssetErasure(Ref ref) =>
    LocalWorkspaceAssetErasure(
      ref.watch(appDatabaseProvider),
      ref.watch(attachmentFileStoreProvider),
      credentialErasure: _credentialErasure(ref),
    );

@riverpod
Future<SelectWorkspaceAssetAttachmentUsecase> selectWorkspaceAssetAttachment(
  Ref ref,
  String workspaceId,
) async {
  final namespace = ref.watch(appStorageNamespaceProvider);
  final assets = await ref.watch(
    workspaceAssetsUsecaseProvider(workspaceId).future,
  );

  return SelectWorkspaceAssetAttachmentUsecase(assets, (
    namespace: namespace,
    workspaceId: workspaceId,
  ));
}

@riverpod
Future<WorkspaceAssetRepository> workspaceAssetRepository(
  Ref ref,
  String workspaceId,
) {
  final link = ref.keepAlive();

  return _assetRepository(ref, workspaceId).whenComplete(link.close);
}

Future<WorkspaceAssetRepository> _assetRepository(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  _requireMounted(ref);

  return session.cloud == null
      ? await _localAssets(ref, workspaceId)
      : _bindCloudAssets(await _gateway(ref, session));
}

Future<WorkspaceAssetRepository> _localAssets(
  Ref ref,
  String workspaceId,
) async {
  final database = ref.watch(appDatabaseProvider);
  final store = ref.watch(attachmentFileStoreProvider);
  await LocalWorkspaceAssetCleanup(
    database,
    workspaceId,
    store,
    credentialErasure: _credentialErasure(ref),
  ).flush();
  _requireMounted(ref);

  return LocalWorkspaceAssetRepository(database, workspaceId, store);
}

LocalWorkspaceCredentialErasure _credentialErasure(Ref ref) =>
    LocalWorkspaceCredentialErasure(
      ref.watch(appDatabaseProvider),
      ref.watch(encryptionServiceProvider),
    );

Future<CloudWorkspaceStateGateway> _gateway(
  Ref ref,
  WorkspaceSession session,
) async {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );
  _requireMounted(ref);
  if (gateway == null) throw const WorkspaceAssetException(.unavailable);

  return gateway;
}

CloudWorkspaceAssetRepository _bindCloudAssets(
  CloudWorkspaceStateGateway gateway,
) {
  final transfer = CloudChatAttachmentAdapter(gateway: .new(gateway));
  final uploader = transfer.createUsecase();

  return CloudWorkspaceAssetRepository(
    gateway: gateway,
    uploadBytes: uploader.uploadAssetBytes,
    getDownload: uploader.getDownload,
    fetchBytes: transfer.downloadAssetBytes,
  );
}

void _requireMounted(Ref ref) {
  if (!ref.mounted) throw const WorkspaceAssetException(.unavailable);
}

@riverpod
Future<ManageWorkspaceAssetsUsecase> workspaceAssetsUsecase(
  Ref ref,
  String workspaceId,
) async => ManageWorkspaceAssetsUsecase(
  await ref.watch(workspaceAssetRepositoryProvider(workspaceId).future),
);

@riverpod
Future<OrganizeWorkspaceFilesUsecase> workspaceFilesUsecase(
  Ref ref,
  String workspaceId,
) {
  final link = ref.keepAlive();

  return _filesUsecase(ref, workspaceId).whenComplete(link.close);
}

Future<OrganizeWorkspaceFilesUsecase> _filesUsecase(
  Ref ref,
  String workspaceId,
) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  _requireMounted(ref);
  if (session.cloud == null) return await _localFiles(ref, workspaceId);
  final gateway = await _gateway(ref, session);

  return OrganizeWorkspaceFilesUsecase(
    CloudWorkspaceFileRepository(.new(gateway)),
  );
}

Future<OrganizeWorkspaceFilesUsecase> _localFiles(
  Ref ref,
  String workspaceId,
) async {
  final assets = await ref.watch(
    workspaceAssetRepositoryProvider(workspaceId).future,
  );
  _requireMounted(ref);

  return OrganizeWorkspaceFilesUsecase(
    LocalWorkspaceFileRepository(
      ref.watch(appDatabaseProvider),
      workspaceId,
      assets,
    ),
  );
}

@riverpod
Future<CreateWorkspaceFileUsecase> createWorkspaceFileUsecase(
  Ref ref,
  String workspaceId,
) {
  final link = ref.keepAlive();

  return _createFileUsecase(ref, workspaceId).whenComplete(link.close);
}

Future<CreateWorkspaceFileUsecase> _createFileUsecase(
  Ref ref,
  String workspaceId,
) async {
  final assets = await ref.watch(
    workspaceAssetsUsecaseProvider(workspaceId).future,
  );
  if (!ref.mounted) throw const WorkspaceAssetException(.unavailable);
  final files = await ref.watch(
    workspaceFilesUsecaseProvider(workspaceId).future,
  );

  return CreateWorkspaceFileUsecase(assets, files);
}

@riverpod
Future<List<WorkspaceFile>> workspaceFiles(
  Ref ref,
  String workspaceId,
  String? parentId,
) async {
  final files = await ref.watch(
    workspaceFilesUsecaseProvider(workspaceId).future,
  );

  return await files.list(parentId: parentId);
}

@riverpod
Future<WorkspaceFile> workspaceFile(
  Ref ref,
  String workspaceId,
  String id,
) async {
  final files = await ref.watch(
    workspaceFilesUsecaseProvider(workspaceId).future,
  );

  return await files.file(id);
}

@riverpod
Future<WorkspaceAssetPreview> workspaceAssetPreview(
  Ref ref,
  String workspaceId,
  String assetId,
) async {
  final assets = await ref.watch(
    workspaceAssetsUsecaseProvider(workspaceId).future,
  );

  return await assets.preview(assetId);
}

@riverpod
WorkspaceAssetFileService workspaceAssetFileService(Ref _) => const .new();

@riverpod
ChooseWorkspaceAssetUsecase chooseWorkspaceAssetUsecase(Ref ref) =>
    ChooseWorkspaceAssetUsecase(ref.watch(workspaceAssetFileServiceProvider));

@riverpod
Future<SaveWorkspaceAssetUsecase> saveWorkspaceAssetUsecase(
  Ref ref,
  String workspaceId,
) async {
  final files = ref.watch(workspaceAssetFileServiceProvider);
  final assets = await ref.watch(
    workspaceAssetsUsecaseProvider(workspaceId).future,
  );

  return SaveWorkspaceAssetUsecase(assets, files);
}

@riverpod
Future<WorkspaceAsset> workspaceAssetDescriptor(
  Ref ref,
  String workspaceId,
  String assetId,
) async {
  final assets = await ref.watch(
    workspaceAssetsUsecaseProvider(workspaceId).future,
  );

  return await assets.describe(assetId);
}
