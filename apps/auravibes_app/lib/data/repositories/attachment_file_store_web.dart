class AttachmentFileStore {
  const AttachmentFileStore({this.storageNamespace = 'auravibes_app'});

  final String storageNamespace;

  Future<String> persistDraftFile(String localPath) => Future.value(localPath);

  Future<void> deleteFile(String _) => Future.value();
}
