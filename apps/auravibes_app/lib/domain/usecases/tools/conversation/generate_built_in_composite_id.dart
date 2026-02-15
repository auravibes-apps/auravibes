String generateBuiltInCompositeId({
  required String tableId,
  required String toolIdentifier,
}) {
  return 'built_in_${tableId}_$toolIdentifier';
}
