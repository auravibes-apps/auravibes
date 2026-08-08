class AttachmentFileStore {
  AttachmentFileStore({String storageNamespace = 'auravibes_app'});

  Future<String> persistDraftFile(String localPath) => Future.value(localPath);

  Future<void> deleteFile(String _) => Future.value();
}
