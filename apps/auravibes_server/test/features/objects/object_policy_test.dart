import 'package:auravibes_server/src/features/objects/object_policy.dart';
import 'package:test/test.dart';

void main() {
  test('accepts bounded passive content', () {
    expect(
      () => validateObjectInput(
        requestId: 'request-1',
        purpose: 'attachment',
        displayName: 'notes.txt',
        mimeType: 'text/plain',
        sizeBytes: 3,
        checksumSha256: 'a' * 64,
      ),
      returnsNormally,
    );
  });

  test('rejects active content and oversized objects', () {
    expect(
      () => validateObjectInput(
        requestId: 'request-1',
        purpose: 'attachment',
        displayName: 'page.html',
        mimeType: 'text/html',
        sizeBytes: 3,
        checksumSha256: 'a' * 64,
      ),
      throwsUnsupportedError,
    );
    expect(
      () => validateObjectInput(
        requestId: 'request-1',
        purpose: 'attachment',
        displayName: 'large.txt',
        mimeType: 'text/plain',
        sizeBytes: maxObjectSizeBytes + 1,
        checksumSha256: 'a' * 64,
      ),
      throwsRangeError,
    );
  });

  test('download disposition cannot inject headers', () {
    expect(
      safeContentDisposition('x\r\nContent-Type: text/html'),
      'attachment; filename="x__Content-Type_ text_html"',
    );
  });
}
