class AttachmentFileStore {
  AttachmentFileStore({String storageNamespace = 'auravibes_app'}) {
    if (storageNamespace.isEmpty) {
      throw ArgumentError.value(storageNamespace, 'storageNamespace');
    }
  }

  Future<String> persistDraftFile(String localPath) => Future.value(localPath);

  Future<void> deleteFile(String _) => Future.value();
}
