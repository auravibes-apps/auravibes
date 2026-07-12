import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('classifies MIME types and matches model modalities', () {
    expect(
      attachmentModalityForMimeType('IMAGE/PNG'),
      AttachmentModality.image,
    );
    expect(
      supportsAttachmentModality(
        AttachmentModality.file,
        ['text', 'pdf'],
        mimeType: 'APPLICATION/PDF',
      ),
      isTrue,
    );
    expect(
      supportsAttachmentModality(
        AttachmentModality.file,
        ['text', 'pdf'],
        mimeType: 'text/csv',
      ),
      isFalse,
    );
    expect(supportsFileAttachments(['text', 'video']), isTrue);
  });
}
