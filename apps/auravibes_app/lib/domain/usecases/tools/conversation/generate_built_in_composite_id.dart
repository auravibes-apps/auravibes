// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
String generateBuiltInCompositeId({
  required String tableId,
  required String toolIdentifier,
}) {
  return 'built_in_${tableId}_$toolIdentifier';
}

String generateNativeCompositeId({
  required String tableId,
  required String toolIdentifier,
}) {
  return 'native_${tableId}_$toolIdentifier';
}
